"""
    mincost_flow(graph, node_demand, edge_capacity, edge_cost, solver,<keyword arguments>)

Find a flow satisfying the `node_demand` at each node and `edge_capacity` constraints for each edge
while minimizing the `sum(edge_cost.*flow)`.

-`node_demand` is a vector of nodal values, which should be positive for sources and
 negative at sink nodes, any node with zero demand is a transport node

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


function mincost_flow(g::lg.DiGraph,
		node_demand::AbstractVector,
		edge_capacity::AbstractMatrix,
		edge_cost::AbstractMatrix,
		solver::AbstractMathProgSolver;
		edge_demand::Union{Nothing,AbstractMatrix} = nothing,
		edge_demand_exact::Bool = false, #If true changes capacity of that node to the value in edge demand
		source_nodes::AbstractVector{<:Integer} = Vector{Integer}(), #Source nodes at which to allow a netflow greater than nodal demand
		sink_nodes::AbstractVector{<:Integer} = Vector{Integer}()	 #Sink nodes at which to allow a netflow less than nodal demand
		)
	T = eltype(g)
	VT = promote_type(eltype(edge_capacity),eltype(node_demand),eltype(edge_cost))

	nv = lg.nv(g)
	ne = lg.ne(g)
	b = Vector{VT}(undef,nv)
	AI = Vector{T}(undef,2*ne)
	AJ = Vector{T}(undef,2*ne)
	AV = Vector{VT}(undef,2*ne)
	edge_costs = Vector{VT}(undef,ne)
	upperbounds = Vector{VT}(undef,ne)
	lowerbounds = Vector{VT}(undef,ne)
	sense = ['=' for _ in 1:nv]

	has_edge_demand= edge_demand !== nothing

	inds = [-1,0]
	for (n,e) in enumerate(lg.edges(g))
		inds .+= 2
		s = lg.src(e)
		t = lg.dst(e)
		AI[inds] = [s,t] #the node index
		AJ[inds] = [n,n]  #the edge index
		AV[inds] = [1,-1]
		upperbounds[n] = edge_capacity[s,t]
		lowerbounds[n] = has_edge_demand ? edge_demand[s,t] : zero(VT)
		if edge_demand_exact && has_edge_demand && lowerbounds[n] != 0
			upperbounds[n] = lowerbounds[n]
		end

		edge_costs[n] = edge_cost[s,t]
	end
	for n = 1:nv
		b[n] = node_demand[n]
	end

	for n in source_nodes
		sense[n] = '>'
	end
	for n in sink_nodes
		sense[n] = '<'
	end


	A = sparse(AI,AJ,AV,nv,ne)
	# return (edge_costs, A, sense, b, lowerbounds, upperbounds, solver)
	sol = linprog(edge_costs, A, sense, b, lowerbounds, upperbounds, solver)
	sol_sparse = sparse(view(AI,1:2:2*ne),view(AI,2:2:2*ne),sol.sol,nv,nv)
	return sol_sparse
end

@deprecate mincost_flow(g::lg.DiGraph,
		capacity::AbstractMatrix,
		demand::AbstractMatrix,
		cost::AbstractMatrix,
		solver::AbstractMathProgSolver,
		source::Int, # if source and/or sink omitted or not in nodes, circulation problem
		sink::Int)  mincost_flow(g,spzeros(lg.nv(g)),capacity,cost,solver,edge_demand=demand,source_nodes=[source],sink_nodes=[sink])

@deprecate mincost_flow(g::lg.DiGraph,
		capacity::AbstractMatrix,
		demand::AbstractMatrix,
		cost::AbstractMatrix,
		solver::AbstractMathProgSolver
		)  mincost_flow(g,spzeros(lg.nv(g)),capacity,cost,solver,edge_demand=demand)
