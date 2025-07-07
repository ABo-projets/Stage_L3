"""Using the equations from Modou Sarry during the decryption with a fixed nonce to find the key by finding the constant output of the initialization
sbox"""

using NPZ
using Statistics
using InformationMeasures
using Plots

plain = npzread("Mesures_hf/pts.npy")
cipher = npzread("Mesures_hf/cts.npy")
tags = npzread("Mesures_hf/tags.npy")
traces = npzread("Mesures_hf/traces.npy")
nonces = npzread("Mesures_hf/nonces.npy")[1,:,:]

function cut(x,len)
    [(x<<(k-1))>>(len-1) for k in 1:len]
end

function assemble(lst,len)
    sum(map(<<,lst,(len-1):-1:0))
end

function to_bits(x,deb,len)
    [(UInt8(x[deb + i])<<(k-1))>>7 for i in 1:len for k in 1:8]
end

function to_bytes(lst,len)
    [sum(map(<<,lst[j:j+7],7:-1:0)) for j in 1:8:len]
end

function sbox_4(k0,k1,n0,n1,v0)
    xor(n0,xor(n1,k0*(xor(1, xor(v0, n1)))))
end

function sbox_3(k0,k1,n0,n1,v0)
    xor(xor(v0,1)*xor(n1, n0), xor(v0, xor(k0,k1)))
end

function sbox_2(k0,k1,n0,n1,v0)
    xor(n1*xor(n0,1), xor(1, xor(k0,k1)))
end

function sbox_1(k0,k1,n0,n1,v0)
    xor(n1, xor(v0, xor(xor(n0,1)*xor(k0,k1), k0*k1)))
end

function sbox_0(k0,k1,n0,n1,v0)
    xor(n0, xor(v0, xor(k1,k0*(xor(n1, xor(k1, xor(v0,1)))))))
end

function HW(x,nb_bits)
    nb = 0
    for i in 0:(nb_bits-1)
        if (x>>i)%2 == 1
            nb += 1
        end
    end
    nb
end

function find_key(n0,n1,v0,s4)
    if n0 == n1 && n1 == v0
        return s4
    elseif v0 == n1
        return xor(1, s4)
    else 
        error("Mauvais nonce")
    end
end

IV =  cut(0x00001000808c0001,64)
real_key = to_bits([0x2b, 0x7e, 0x15, 0x16, 0x28, 0xae, 0xd2, 0xa6, 0xab, 0xf7, 0x15, 0x88, 09, 0xcf, 0x4f, 0x3c],0,16)
lst_n0 = [to_bits(nonces[i,:],0,8) for i in 1:size(nonces,1)]
lst_n1 = [to_bits(nonces[i,:],8,8) for i in 1:size(nonces,1)]

function outputs(output,l,jump)
    outputs = zeros(UInt8,size(traces,1))
    bit_output = cut(UInt8(output),8)
    for i in 1:jump
        outputs[i] = output
    end
    m = 0
    for i in 1:size(traces,1)
        if IV[l] == lst_n1[i][l]
            m = i
            break
        end
    end
    n0 = lst_n0[m][l]
    n1 = lst_n1[m][l]
    v0 = IV[l]
    s4 = bit_output[8]
    k0 = find_key(n0,n1,v0,s4)
    k1 = xor(xor(v0, 1)*xor(n0, n1), xor(v0, xor(k0, bit_output[7])))
    for i in (jump+1):jump:(size(traces,1))
        n0 = lst_n0[i][l]
        n1 = lst_n1[i][l]
        s0 = sbox_0(k0,k1,n0,n1,v0)
        s1 = sbox_1(k0,k1,n0,n1,v0)
        s2 = sbox_2(k0,xor(k1,((l in [57,58,59,60]) ? 1 : 0),n0,n1,v0))
        s3 = sbox_3(k0,k1,n0,n1,v0)
        s4 = sbox_4(k0,k1,n0,n1,v0)
        output_i = assemble([s0,s1,s2,s3,s4],5)
        for j in 0:(jump-1)
            outputs[i+j] = output_i
        end
    end
    outputs
end

outs = Array{Dict{Any,Any}}(undef,64)
for l in 1:64
    outs[l] = Dict()
    for output in 0:31  
        out = outputs(output,l,1) 
        occ = Dict()
        for i in 1:size(traces,1)
            if !(out[i] in keys(occ))
                occ[out[i]] = 1
            else 
                occ[out[i]] += 1
            end
        end
        if length(keys(occ)) == 2
            outs[l][output]  = out
        end
    end
end


IM_hw = [[[get_mutual_information(map(x -> HW(x,5),outs[l][output]),traces[:,t]) for t in 1:size(traces,2)] for output in keys(outs[l])] for l in 1:1]
IM_val = [[[get_mutual_information(outs[l][output],traces[:,t]) for t in 1:size(traces,2)] for output in keys(outs)] for l in 1:64]


plot()
for k in 1:length(keys(outs[1]))
    cles = [output for output in keys(outs[1])]
    out = cles[k]
    m = 0
    for i in 1:size(traces,1)
        if IV[1] == lst_n1[i][1]
            m = i
            break
        end
    end
    bit_output = cut(UInt8(out),8)
    n0 = lst_n0[m][1]
    n1 = lst_n1[m][1]
    v0 = IV[1]
    s4 = bit_output[8]
    k0 = find_key(n0,n1,v0,s4)
    k1 = xor(xor(v0, 1)*xor(n0, n1), xor(v0, xor(k0, bit_output[7])))
    plot!(IM_hw[1][k], label = "("*string(k0)*","*string(k1)*")")
end

key_guess = Array{UInt8}(undef,128)
for l in 1:1
    possible_s = [i for i in keys(outs[l])]
    s_max = 0
    maxi = 0
    for hyp_s in 1:length(IM_hw[l])
        val_max = maximum(IM_hw[l][hyp_s])
        if val_max > maxi
            s_max = possible_s[hyp_s]
            maxi = val_max
        end
    end
    println(s_max)
    m = 0
    for i in 1:size(traces,1)
        if IV[l] == lst_n1[i][l]
            m = i
            break
        end
    end
    bit_output = cut(UInt8(s_max),8)
    n0 = lst_n0[m][l]
    n1 = lst_n1[m][l]
    v0 = IV[l]
    s4 = bit_output[8]
    key_guess[l] = find_key(n0,n1,v0,s4)
    key_guess[l+64] = xor(xor(v0, 1)*xor(n0,n1),xor(v0, xor(key_guess[l], bit_output[7])))
end