"""
    mincost_flow(graph, capacity, demand, cost, solver, [, source][, sink])

Find a flow satisfying the `demand` and `capacity` constraints for each edge
while minimizing the `sum(cost.*flow)`.

- If `source` and `sink` are specified, they are allowed a net flow production,
consumption respectively. All other nodes must respect the flow conservation
property.

- The problem can be seen as a linear programming problem and uses a LP 
solver under the hood. We use Clp in the examples and tests.

Returns a flow matrix, flow[i,j] corresponds to the flow on the (i,j) arc.

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
julia> # v2 -> sink have demand of one
julia> demand = spzeros(6,6)
julia> demand[3,6] = 1
julia> demand[4,6] = 1
julia> capacity = ones(6,6)
julia> flow = mincost_flow(g, capacity, demand, w, ClpSolver(), 5, 6)
```
"""
function mincost_flow(g::lg.DiGraph, 
		capacity::AbstractMatrix,
		demand::AbstractMatrix,
		cost::AbstractMatrix,
		solver::AbstractMathProgSolver,
		source::Int = -1, # if source and/or sink omitted or not in nodes, circulation problem 
		sink::Int = -1)
	flat_cap = collect(Iterators.flatten(capacity))
	flat_dem = collect(Iterators.flatten(demand))
	flat_cost = collect(Iterators.flatten(cost))
	n = lg.nv(g)
	b = zeros(n+n*n)
	A = spzeros(n+n*n,n*n)
	sense = ['=' for _ in 1:n]
	append!(sense, ['>' for _ in 1:n*n])
	for node in 1:n
		if sink == node
			sense[sink] = '>'
		elseif source == node
			sense[source] = '<'
		end
		col_idx = (node-1)*n+1:node*n
		line_idx = node:n:n*n
		for jdx in col_idx
			A[node,jdx] = A[node,jdx]+1.0
		end
		for idx in line_idx
			A[node,idx] = A[node,idx]-1.0
		end
	end
	for src in 1:n
		for dst in 1:n
			if lg.Edge(src,dst) ∉ lg.edges(g)
				A[n+src+n*(dst-1),src+n*(dst-1)] = 1
				sense[n+src+n*(dst-1)] = '<'
			end
		end
	end
	sol = linprog(flat_cost, A, sense, b, flat_dem, flat_cap, solver)
	[sol.sol[idx + n*(jdx-1)] for idx=1:n,jdx=1:n]
end
