"""Daemen CPA attack : for each 3 bits key hypothesis, compute the output of the first round of the linear permutation for the nth bit of word 
and looks at the Pearson correlation with the power consumption"""

using Plots
using Statistics
using NPZ

clairs = npzread("Mesures_ref/pts.npy")
chiffres = npzread("Mesures_ref/cts.npy")
traces = npzread("Mesures_ref/traces.npy")
nonces = npzread("Mesures_ref/nonces.npy")

IV = [00,00,0x10,00,0x80,0x8c,00,01]

real_key = [0x2b, 0x7e, 0x15, 0x16, 0x28, 0xae, 0xd2, 0xa6, 0xab, 0xf7, 0x15, 0x88, 09, 0xcf, 0x4f, 0x3c]

function y0(k0,n1,n0)
    k0*(n1 ⊻ 0x1) ⊻ n0
end

function z0(kj, k36, k45, n1, n0, j)
    y0_j = y0(kj, n1[j], n0[j])
    y0_36 = y0(k36, n1[(j+35)%64 + 1], n0[(j+35)%64 + 1])
    y0_45 = y0(k45, n1[(j+44)%64 + 1], n0[(j+44)%64 + 1])
    y0_j ⊻ y0_36 ⊻ y0_45
end

function y1(k01,n1,n0)
    n0*(k01 ⊻ 1) ⊻ n1
end

function z1(kj, k3, k25, n1, n0, j)
    y1(kj, n1[j], n0[j]) ⊻ y1(k3, n1[(j+2)%64 + 1], n0[(j+2)%64 + 1]) ⊻ y1(k25, n1[(j+24)%64 + 1], n0[(j+24)%64 + 1])
end

function cut(x,deb,len)
    [(UInt8(x[deb + i])<<(k-1))>>7 for i in 1:len for k in 1:8]
end

function assemble(lst,len)
    [sum(map(<<,lst[j:j+7],7:-1:0)) for j in 1:8:len]
end

n0 = [cut(nonces[t,:], 0, 8) for t in 1:size(traces,1)]
n1 = [cut(nonces[t,:], 8, 8) for t in 1:size(traces,1)]

z0s = [[[z0(kj,k36,k45,n1[t],n0[t],j) for t in 1:size(traces,1)] for kj in 0:1 for k36 in 0:1 for k45 in 0:1] for j in 1:64]
corrs0 = [[[cor(z0s[j][4*(kj-1)+2*(k36-1)+k45],traces[:,t]) for t in 1:size(traces,2)] for kj in 1:2 for k36 in 1:2 for k45 in 1:2] for j in 1:64]

z1s = [[[z1(kj,k3,k25,n1[t],n0[t],j) for t in 1:size(traces,1)] for kj in 0:1 for k3 in 0:1 for k25 in 0:1] for j in 1:64]
corrs1 = [[[cor(z1s[j][4*(kj-1)+2*(k3-1)+k25],traces[:,t]) for t in 1:size(traces,2)] for kj in 1:2 for k3 in 1:2 for k25 in 1:2] for j in 1:64]

plot()
for kj in 1:2
    for k36 in 1:2
        for k45 in 1:2
            plot!(map(abs,corrs0[1][4*(kj-1)+2*(k36-1)+k45]))
        end
    end
end

cle = Array{UInt8}(undef,128)
for i in 1:64
    maxi = 0
    kmaxi = 0
    for kj in 1:2
        for k36 in 1:2
            for k45 in 1:2
                for t in 1:size(traces,2)
                    if abs(corrs0[i][4*(kj-1)+(k36-1)+k45][t]) > maxi 
                        maxi = abs(corrs0[i][4*(kj-1)+(k36-1)+k45][t])
                        kmaxi = kj
                    end
                end
            end
        end
    end
    cle[i] = kmaxi - 1
end

for i in 1:64
    p = plot()
    for kj in 1:2
        for k36 in 1:2
            for k45 in 1:2
                plot!(map(abs,corrs0[i][4*(kj-1)+2*(k36-1)+k45]))
            end
        end
    end
    savefig(p,"Mesures_ref/daemen_cpa_bit"*string(i)*".png")
end