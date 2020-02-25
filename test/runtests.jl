using LightGraphsFlows
using Test
using LightGraphs
import SimpleTraits
const lg = LightGraphs

using LinearAlgebra: diag

using JuMP
import GLPK

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
        "mincost",
        "mincut",
        ]
    tp = joinpath(testdir, "$(t).jl")
    include(tp)
end
