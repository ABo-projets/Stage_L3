using NPZ
using Statistics
using InformationMeasures
using Plots
using Random

traces_2 = npzread("Mesures_HW2/traces.npy")
traces_3 = npzread("Mesures_HW3/traces.npy")

traces = vcat(traces_2,traces_3)

IM_hw = [get_mutual_information(traces[:,t],[i for i in 2:3 for j in 1:5000]) for t in 1:size(traces,2)]
IM_alea = [get_mutual_information(traces[:,t],rand((2,3),10000)) for t in 1:size(traces,2)]

plot(IM_hw)
plot!(IM_alea)
