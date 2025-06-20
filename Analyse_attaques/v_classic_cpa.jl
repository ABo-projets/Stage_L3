"""Classic CPA attack : for each key hypothesis, compute the output of the first round of the S-BOX and look at its Hamming weight
    see if there is a good Pearson correlation with the power consumption over the 2000 time samples"""

using Plots
using Statistics
using InformationMeasures
using NPZ

clairs = npzread("Mesures/pts_bis.npy")
chiffres = npzread("Mesures/cts_bis.npy")
traces = npzread("Mesures/traces_bis.npy")
nonces = npzread("Mesures/nonces_bis.npy")

IV = 0x00001000808c0001

real_key = [0x2b, 0x7e, 0x15, 0x16, 0x28, 0xae, 0xd2, 0xa6, 0xab, 0xf7, 0x15, 0x88, 09, 0xcf, 0x4f, 0x3c]

function hw_vert(state)
    p = 0
    for k in 1:5
        if state[k] >= 0x1
            p += 1
        end
    end
    return p
end

function sbox(state)
    state[1] = state[5] ⊻ state[1]
    state[5] = state[5] ⊻ state[4]
    state[3] = state[3] ⊻ state[2];
    ts = [state[1] ⊻ 1, state[2] ⊻ 1, state[3] ⊻ 1, state[4] ⊻ 1, state[5] ⊻ 1]
    for i in 1:5
       ts[i] = ts[i] & state[i%5 + 1] 
    end
    for i in 1:5
        state[i] = state[i] ⊻ ts[i%5+1]
    end
    state[2] ⊻= state[1]
    state[1] ⊻= state[5]
    state[4] ⊻= state[3]
    state[3] ⊻= 1;

    state
end

function HW_postperm(state,i)
    if i>=57 && i <=60  
        state[3] ⊻= 1
    end
    hw_vert(sbox(state))
end

function cut(x,k)
    x = UInt8(x)
    x = (x<<(7-k))>>7
end

states = [[[[(UInt64(IV)<<(i-1))>>63, UInt64(k), UInt64(kprim), cut(nonces[t, (i+7)÷8],(i-1)%8), cut(nonces[t, (i+7)÷8+8],(i-1)%8)] for t in 1:40000] for k in 0:1 for kprim in 0:1] for i in 1:64]
mats_pred = [[[HW_postperm(states[i][2*(k-1)+kprim][t],i) for t in 1:40000] for k in 1:2 for kprim in 1:2] for i in 1:64]
corrs = [[[get_mutual_information(mats_pred[i][2*(k-1)+kprim],traces[:,t]) for t in 1:2000] for k in 1:2 for kprim in 1:2] for i in 1:64]

plot()
for k in 1:2
    for kprim in 1:2
        plot!(corrs[64][2*(k-1)+kprim])
    end
end

cle = Array{UInt8}(undef,128)
for i in 1:64
    maxi = 0
    kmaxi = 0
    kprimmaxi = 0
    for k in 1:2
        for kprim in 1:2
            for t in 1:2000
                if abs(corrs[i][2*(k-1)+kprim][t]) > maxi 
                    maxi = abs(corrs[i][2*(k-1)+kprim][t])
                    kmaxi = k
                    kprimmaxi = kprim
                end
            end
        end
    end
    cle[i] = kmaxi - 1
    cle[64 + i] = kprimmaxi - 1
end