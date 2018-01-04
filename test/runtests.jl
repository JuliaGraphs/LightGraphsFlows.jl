using LightGraphsFlows
using Base.Test
import LightGraphs
import SimpleTraits
const lg = LightGraphs

const testdir = dirname(@__FILE__)

testgraphs(g) = [g, lg.Graph{UInt8}(g), lg.Graph{Int16}(g)]
testdigraphs(g) = [g, lg.DiGraph{UInt8}(g), lg.DiGraph{Int16}(g)]

for t in [
        "edmonds_karp",
        "dinic",
        "boykov_kolmogorov",
        "push_relabel",
        "maximum_flow",
        "multiroute_flow",
        "mincost"]
    tp = joinpath(testdir, "$(t).jl")
    include(tp)
end
