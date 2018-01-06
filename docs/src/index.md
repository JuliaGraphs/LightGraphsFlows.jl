 # LightGraphsFlows.jl: flow algorithms for LightGraphs

```@meta
CurrentModule = LightGraphsFlows
DocTestSetup = quote
    using LightGraphsFlows
    import LightGraphs
    const lg = LightGraphs
end
```

```@autodocs
Modules = [LightGraphsFlows]
Pages = ["LightGraphsFlows.jl"]
Order = [:function, :type]
```

## Max flow algorithms

```@autodocs
Modules = [LightGraphsFlows]
Pages = ["maxflow.jl", "boykov_kolmogorov.jl", "push_relabel.jl", "dinic.jl", "edmonds_karp.jl"]
Order = [:function, :type]
```

## Multi-route flow

```@autodocs
Modules = [LightGraphsFlows]
Pages = ["multiroute_flow.jl", "ext_multiroute_flow.jl", "kishimoto.jl"]
Order = [:function, :type]
```
