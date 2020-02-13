"""
    mincost_flow(graph, node_demand, edge_capacity, edge_cost, solver,<keyword arguments>)

Find a flow satisfying the `node_demand` at each node and `edge_capacity` constraints for each edge
while minimizing the `dot(edge_cost, flow)`.

-`node_demand` is a vector of nodal values, which should be positive for sources and
 negative at sink nodes, and ignored for all other nodes.

- The problem can be seen as a linear programming problem and uses a LP
solver under the hood. We use Clp in the examples and tests.

Returns a flow matrix, flow[i,j] corresponds to the flow on the (i,j) arc.
# Arguments
- `edge_demand::AbstractMatrix`: demand a minimum flow for a given edge.
- `edge_demand_exact=true`: changes the capacity of a non zero edge to the demanded value
- `source_nodes::AbstractVector` Sources at which the nodal netflow is allowed to be greater than nodal demand **
- `sink_nodes::AbstractVector` Sinks at which the nodal netflow is allowed to be less than nodal demand **
   ** source_nodes & sink_nodes are only needed when nodal flow are not explictly set in node_demand

### Usage Example:

```julia
julia> using Clp: ClpSolver # use your favorite LP solver here
julia> g = lg.DiGraph(6) # Create a flow-graph
julia> lg.add_edge!(g, 5, 1)
julia> lg.add_edge!(g, 5, 2)
julia> lg.add_edge!(g, 3, 6)
julia> lg.add_edge!(g, 4, 6)
julia> lg.add_edge!(g, 1, 3)
julia> lg.add_edge!(g, 1, 4)
julia> lg.add_edge!(g, 2, 3)
julia> lg.add_edge!(g, 2, 4)
julia> w = zeros(6,6)
julia> w[1,3] = 10.
julia> w[1,4] = 5.
julia> w[2,3] = 2.
julia> w[2,4] = 2.
julia> demand = spzeros(6)
julia> demand[5] = 2
julia> demand[6] = -2
julia> capacity = ones(6,6)
julia> flow = mincost_flow(g, demand, capacity, w, ClpSolver())
```
"""
function mincost_flow end

@traitfn function mincost_flow(g::AG::lg.IsDirected,
		node_demand::AbstractVector,
		edge_capacity::AbstractMatrix,
		edge_cost::AbstractMatrix,
		optimizer;
		edge_demand::Union{Nothing,AbstractMatrix} = nothing,
		source_nodes::AbstractVector{<:Integer} = Vector{Int}(), #Source nodes at which to allow a netflow greater than nodal demand
		sink_nodes::AbstractVector{<:Integer} = Vector{Int}()	 #Sink nodes at which to allow a netflow less than nodal demand
		) where {AG <: lg.AbstractGraph}

	m = JuMP.Model(optimizer)
	vtxs = vertices(g)

	@variable(m, 0 <= f[i=vtxs,j=vtxs; (i,j) in lg.edges(g)] <= edge_capacity[i, j])
	@objective(m, Min, sum(f[src(e),dst(e)] * edge_cost[src(e), dst(e)] for e in lg.edges(g)))
	for v in lg.vertices(g)
	    if v in source_nodes
            @constraint(m,
                sum(f[vin, v] for vin in lg.inneighbors(g, v)) <= sum(f[v, vout] for vout in outneighbors(g, v))
            )
	    elseif v in sink_nodes
            @constraint(m,
                sum(f[vin, v] for vin in lg.inneighbors(g, v)) - sum(f[v, vout] for vout in outneighbors(g, v)) >= node_demand[v]
            )
	    else
            @constraint(m,
                sum(f[vin, v] for vin in lg.inneighbors(g, v)) == sum(f[v, vout] for vout in outneighbors(g, v))
            )
        end
	end
    if edge_demand isa AbstractMatrix
        for e in lg.edges(g)
            (i,j) = Tuple(e)
            JuMP.set_lower_bound(f[i,j], edge_demand[i,j])
        end
    end
    optimize!(m)
    ts = termination_status(m)
    result_flow = spzeros(nv(g), nv(g))
    if ts != MOI.OPTIMAL
        @warn "Problem does not have an optimal solution, status: $(ts)"
        return result_flow
    end
    for e in lg.edges(g)
        (i,j) = Tuple(e)
        result_flow[i,j] = JuMP.value(f[i,j])
    end
    return result_flow
end
