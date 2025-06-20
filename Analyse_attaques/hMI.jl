"""Let's compute the mutual information between the power consuption and each of the four hypothesis : horizontal value, horizontal HW, vertical
value, vetical HW"""

using Plots
using Statistics
using NPZ
using InformationMeasures

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

function sbox(k0,n0,n1,v0)
    n0 ⊻ n1 ⊻ k0*(1 ⊻ v0 ⊻ n1)
end

function sbox_byte(lst,i,j)
    [sbox(lst[k],cut(nonce[j],8)[k],cut(nonce[j+8],8)[k],IV[8*(j-1)+k]) for k in 1:8]
end

function cut(x,len)
    [(x<<(k-1))>>(len-1) for k in 1:len]    
end

function assemble(lst,len)
    sum(map(<<,lst,(len-1):-1:0))
end

IV =  cut(0x00001000808c0001,64)

output = map(x -> cut(x,8),cles[:,1:8])
output = map((x,i,j) -> sbox_byte(x,i,j),output,reshape(collect(Iterators.flatten(1:10000 for i in 1:8)),(10000,8)),transpose(reshape([j for i in 1:10000 for j in 1:8],(8,10000))))
output = map(x -> assemble(x,8),output)

hHW = [[get_mutual_information(map(x -> HW(x,8), output[:,i]), traces[:,t]) for t in 1:2000] for i in 1:8]
#hvalue = [IM(output[:,1],traces[:,t], identity, identity) for t in 1:2000]