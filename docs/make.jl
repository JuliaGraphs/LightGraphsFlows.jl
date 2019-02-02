using Documenter
using LightGraphsFlows
import LightGraphs
const lg = LightGraphs

makedocs(
    modules = [LightGraphsFlows],
    format = Documenter.HTML(),
    sitename = "LightGraphsFlows",
	pages = Any[
		"Getting started"    => "index.md",
        "Maxflow algorithms" => "maxflow.md",
        "Multiroute flows"   => "multiroute.md",
        "Min-cost flows"     => "mincost.md",
        "Min-cut"            => "mincut.md",
    ]
)

deploydocs(
    deps        = nothing,
    make        = nothing,
    repo        = "github.com/JuliaGraphs/LightGraphsFlows.jl.git",
    target      = "build",
    osname      = "linux"
)
