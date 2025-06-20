"""Classic CPA attack : for each key hypothesis, compute the output of the first round of the S-BOX and look at its Hamming weight
    see if there is a good Pearson correlation with the power consumption over the 2000 time samples"""

using Plots
using Statistics
using NPZ

clairs = npzread("Mesures/pts.npy")
chiffres = npzread("Mesures/cts.npy")
traces = npzread("Mesures/traces.npy")
nonces = npzread("Mesures/nonces.npy")

IV = [0,0,0,0,1,0,0,0,8,0,8,0xc,0,0,0,1]

real_key = [0x2b, 0x7e, 0x15, 0x16, 0x28, 0xae, 0xd2, 0xa6, 0xab, 0xf7, 0x15, 0x88, 09, 0xcf, 0x4f, 0x3c]

function hw(x)
    p = 0
    while x>0
        if x%2 == 1
            p+=1
        end
        x = x ÷ 2
    end
    return p
end

function sbox(state)
    state[1] = state[5] ⊻ state[1]
    state[5] = state[5] ⊻ state[4]
    state[3] = state[3] ⊻ state[2];
    ts = [~state[1], ~state[2], ~state[3], ~state[4], ~state[5]]
    for i in 1:5
       ts[i] = ts[i] & state[i%5 + 1] 
    end
    for i in 1:5
        state[i] = state[i] ⊻ ts[i%5+1]
    end
    state[2] = state[2] ⊻ state[1]
    state[1] = state[1] ⊻ state[5]
    state[4] = state[4] ⊻ state[3]
    state[3] = ~state[3];

    state
end

function HW_postperm(state,i,add_const)
    if add_const
        state[3] = state[3] ⊻ 0xf
    end
    hw(sbox(state)[i])
end

function cut(x,first_half)
    x = UInt8(x)
    if first_half
        x >>= 4
    else
        x = (x<<4)>>4
    end
    x
end

states = [[[[UInt8(IV[b]), UInt8(k), UInt8(kprim), cut(nonces[t, (b+1)÷2],b%2==1), cut(nonces[t, (b+1)÷2+8],b%2==1)] for t in 1:3000] for k in 0:15 for kprim in 0:15] for b in 1:16]
mats_pred = [[[[HW_postperm(states[b][16*(k-1)+kprim][t],i,b==15) for t in 1:3000] for k in 1:16 for kprim in 1:16] for b in 1:16] for i in 1:5]
corrs = [[[[cor(mats_pred[i][b][16*(k-1)+kprim],traces[:,t]) for t in 1:2000] for k in 1:16 for kprim in 1:16] for b in 1:16] for i in 1:5]

cle = Array{UInt8}(undef,32)
for i in 1:16
    maxi = 0
    kmaxi = 0
    kprimmaxi = 0
    for k in 1:16
        for kprim in 1:16
            for t in 1:2000
                if abs(corrs[5][i][16*(k-1)+kprim][t]) > maxi 
                    maxi = abs(corrs[5][i][16*(k-1)+kprim][t])
                    kmaxi = k
                    kprimmaxi = kprim
                end
            end
        end
    end
    cle[i] = kmaxi - 1
    cle[16 + i] = kprimmaxi - 1
end