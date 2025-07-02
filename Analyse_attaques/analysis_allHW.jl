"""Let's compute the mutual information between the power consuption and each of the four hypothesis : horizontal value, horizontal HW, vertical
value, vetical HW"""

using Plots
using Statistics
using InformationMeasures
using NPZ

cles = npzread("Mesures_tousHW/keys.npy")
clairs = npzread("Mesures_tousHW/pts.npy")
chiffres = npzread("Mesures_tousHW/cts.npy")
traces = npzread("Mesures_tousHW/traces.npy")
nonces = npzread("Mesures_tousHW/nonces.npy")




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
    [sbox_4(lst[k],cut(cles[i,j+8],8)[k],cut(nonces[i,j],8)[k],cut(nonces[i,(j+8)],8)[k],IV[8*(j-1)+k]) for k in 1:8]
end

function sbox_byte_3(lst,i,j)
    [sbox_3(lst[k],cut(cles[i,j+8],8)[k],cut(nonces[i,j],8)[k],cut(nonces[i,(j+8)],8)[k],IV[8*(j-1)+k]) for k in 1:8]
end

function sbox_byte_2(lst,i,j)
    [sbox_2(lst[k],cut(cles[i,j+8],8)[k],cut(nonces[i,j],8)[k],cut(nonces[i,(j+8)],8)[k],IV[8*(j-1)+k]) for k in 1:8]
end

function sbox_byte_1(lst,i,j)
    [sbox_1(lst[k],cut(cles[i,j+8],8)[k],cut(nonces[i,j],8)[k],cut(nonces[i,(j+8)],8)[k],IV[8*(j-1)+k]) for k in 1:8]
end

function sbox_byte_0(lst,i,j)
    [sbox_0(lst[k],cut(cles[i,j+8],8)[k],cut(nonces[i,j],8)[k],cut(nonces[i,(j+8)],8)[k],IV[8*(j-1)+k]) for k in 1:8]
end

function cut(x,len)
    [(x<<(k-1))>>(len-1) for k in 1:len]
end

function assemble(lst,len)
    sum(map(<<,lst,(len-1):-1:0))
end

IV =  cut(0x00001000808c0001,64)


k0 = map(x -> cut(x,8),cles[:,1:8])
k1 = map(x -> cut(x,8),cles[:,9:16])
k0prim = vcat([k0[10000,:] for i in 1:5000],[k0[1,:] for i in 1:5000])
k1prim = vcat([k1[10000,:] for i in 1:5000],[k1[1,:] for i in 1:5000])
n0 = map(x -> cut(x,8),nonces[:,1:8])
n1 = map(x -> cut(x,8),nonces[:,9:16])
vraisHW = [sum(map(f -> f(IV[1],k0[i,1][1],k1[i,1][1],n0[i,1][1],n1[i,1][1]),[sbox_0,sbox_1,sbox_2,sbox_3,sbox_4])) for i in 1:size(traces,1)]
fauxHW = [sum(map(f -> f(IV[1],k0prim[i][1][1],k1prim[i][1][1],n0[i,1][1],n1[i,1][1]),[sbox_0,sbox_1,sbox_2,sbox_3,sbox_4])) for i in 1:size(traces,1)]

IM_bad_hw = [IM(traces[:,t],fauxHW,identity,identity) for t in 1:size(traces,2)]
IM_good_hw = [IM(traces[:,t],vraisHW,identity,identity) for t in 1:size(traces,2)]

plot(IM_good_hw)
plot!(IM_bad_hw)