module LightGraphsFlows

import LightGraphs
const lg = LightGraphs
using SimpleTraits: @traitfn, @traitimpl
import SimpleTraits

using MathProgBase.HighLevelInterface: linprog
using MathProgBase.SolverInterface: AbstractMathProgSolver

import Base: getindex, size, transpose, ctranspose

include("maximum_flow.jl")
include("edmonds_karp.jl")
include("dinic.jl")
include("boykov_kolmogorov.jl")
include("push_relabel.jl")
include("multiroute_flow.jl")
include("kishimoto.jl")
include("ext_multiroute_flow.jl")
include("mincost.jl")
include("mincut.jl")

export
maximum_flow, EdmondsKarpAlgorithm, DinicAlgorithm, BoykovKolmogorovAlgorithm, PushRelabelAlgorithm,
multiroute_flow, KishimotoAlgorithm, ExtendedMultirouteFlowAlgorithm, mincost_flow, mincut

end
