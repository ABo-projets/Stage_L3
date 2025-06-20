"""Let's compute the mutual information between the power consuption and each of the four hypothesis : horizontal value, horizontal HW, vertical
value, vetical HW"""

using Plots
using Statistics
using NPZ

cles = npzread("Mesures/keys.npy")
clairs = npzread("Mesures/pts.npy")
chiffres = npzread("Mesures/cts.npy")
traces = npzread("Mesures/traces.npy")
nonce = npzread("Mesures/nonce.npy")

function IM(X,Y,fnX,fnY)
    valsX = Dict()
    valsY = Dict()
    valsXY = Dict()
    for i in 1:length(X)
        if fnX(X[i]) ∉ keys(valsX)
            valsX[fnX(X[i])] = 1
        else 
            valsX[fnX(X[i])] += 1
        end

        if fnY(Y[i]) ∉ keys(valsY)
            valsY[fnY(Y[i])] = 1
        else 
            valsY[fnY(Y[i])] += 1
        end

        if (fnX(X[i]),fnY(Y[i])) ∉ keys(valsXY)
            valsXY[(fnX(X[i]),fnY(Y[i]))] = 1
        else 
            valsXY[(fnX(X[i]),fnY(Y[i]))] += 1
        end
    end

    sum=0
    for (i,j) in keys(valsXY)
        px = valsX[i]/length(X)
        py = valsY[j]/length(X)
        pxy = valsXY[(i,j)]/length(X)
        sum += pxy*log(pxy/(px*py))
    end
    if sum > 1
        println(sum)
    end
    sum
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

function sbox_4(k0,k1,n0,n1,v0)
    n0 ⊻ n1 ⊻ k0*(1 ⊻ v0 ⊻ n1)
end

function sbox_3(k0,k1,n0,n1,v0)
    (v0 ⊻ 1)*(n1 ⊻ n0) ⊻ v0 ⊻ k0 ⊻ k1
end

function sbox_2(k0,k1,n0,n1,v0)
    n1*(n0 ⊻ 1) ⊻ 1 ⊻ k0 ⊻ k1
end

function sbox_1(k0,k1,n0,n1,v0)
    n1 ⊻ v0 ⊻ (n0 ⊻ 1)*(k0 ⊻ k1) ⊻ k0*k1
end

function sbox_0(k0,k1,n0,n1,v0)
    n0 ⊻ v0 ⊻ k1 ⊻ k0*(n1 ⊻ k1 ⊻ v0 ⊻ 1)
end

function sbox_byte_4(lst,i,j)
    [sbox_4(lst[k],cut(cles[i,j+8],8)[k],cut(nonce[j],8)[k],cut(nonce[j+8],8)[k],IV[8*(j-1)+k]) for k in 1:8]
end

function sbox_byte_3(lst,i,j)
    [sbox_3(lst[k],cut(cles[i,j+8],8)[k],cut(nonce[j],8)[k],cut(nonce[j+8],8)[k],IV[8*(j-1)+k]) for k in 1:8]
end

function sbox_byte_2(lst,i,j)
    [sbox_2(lst[k],cut(cles[i,j+8],8)[k],cut(nonce[j],8)[k],cut(nonce[j+8],8)[k],IV[8*(j-1)+k]) for k in 1:8]
end

function sbox_byte_1(lst,i,j)
    [sbox_1(lst[k],cut(cles[i,j+8],8)[k],cut(nonce[j],8)[k],cut(nonce[j+8],8)[k],IV[8*(j-1)+k]) for k in 1:8]
end

function sbox_byte_0(lst,i,j)
    [sbox_0(lst[k],cut(cles[i,j+8],8)[k],cut(nonce[j],8)[k],cut(nonce[j+8],8)[k],IV[8*(j-1)+k]) for k in 1:8]
end

function cut(x,len)
    [(x<<(k-1))>>(len-1) for k in 1:len]
end

function assemble(lst,len)
    sum(map(<<,lst,(len-1):-1:0))
end

IV =  cut(0x00001000808c0001,64)

s4 = map(x -> cut(x,8),cles[:,1:8])
s3 = map(x -> cut(x,8),cles[:,1:8])
s2 = map(x -> cut(x,8),cles[:,1:8])
s1 = map(x -> cut(x,8),cles[:,1:8])
s0 = map(x -> cut(x,8),cles[:,1:8])

s4 = map((x,i,j) -> sbox_byte_4(x,i,j),s4,reshape(collect(Iterators.flatten(1:10000 for i in 1:8)),(10000,8)),transpose(reshape([j for i in 1:10000 for j in 1:8],(8,10000))))
s3 = map((x,i,j) -> sbox_byte_3(x,i,j),s3,reshape(collect(Iterators.flatten(1:10000 for i in 1:8)),(10000,8)),transpose(reshape([j for i in 1:10000 for j in 1:8],(8,10000))))
s2 = map((x,i,j) -> sbox_byte_2(x,i,j),s2,reshape(collect(Iterators.flatten(1:10000 for i in 1:8)),(10000,8)),transpose(reshape([j for i in 1:10000 for j in 1:8],(8,10000))))
s1 = map((x,i,j) -> sbox_byte_1(x,i,j),s1,reshape(collect(Iterators.flatten(1:10000 for i in 1:8)),(10000,8)),transpose(reshape([j for i in 1:10000 for j in 1:8],(8,10000))))
s0 = map((x,i,j) -> sbox_byte_0(x,i,j),s0,reshape(collect(Iterators.flatten(1:10000 for i in 1:8)),(10000,8)),transpose(reshape([j for i in 1:10000 for j in 1:8],(8,10000))))


output = [map((s0,s1,s2,s3,s4) -> assemble([s0[i],s1[i],s2[i],s3[i],s4[i]],5),s0,s1,s2,s3,s4) for i in 1:8]
vHW = [IM(output[1][:,1], traces[:,t], x -> HW(x,5), identity) for t in 1:2000]
vvalue = [IM(output[1][:,1],traces[:,t], identity, identity) for t in 1:2000]