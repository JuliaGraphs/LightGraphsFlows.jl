"""
    mincost_flow(graph, capacity, demand, cost[, source][, sink][, solver])

Find a flow satisfying the `demand` and `capacity` constraints for each edge
while minimizing the `sum(cost.*flow)`.

- If `source` and `sink` are specified, they are allowed a net flow production,
consumption respectively. All other nodes must respect the flow conservation
property.

- The problem can be seen as a linear programming problem and uses a LP 
solver under the hood. The default solver is GLPKSolverLP.

Returns a flow matrix, flow[i,j] corresponds to the flow on the (i,j) arc.

### Usage Example:

```julia
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
julia> flow = mincost_flow(g, capacity, demand, w, 5, 6)
```
"""
function mincost_flow(g::lg.DiGraph, 
		capacity::AbstractMatrix,
		demand::AbstractMatrix,
		cost::AbstractMatrix,
		source::Int = -1, # if source and/or sink omitted or not in nodes, circulation problem 
		sink::Int = -1,
		solver::AbstractMathProgSolver = GLPKSolverLP())
	m = JuMP.Model(solver = solver)
	flow = JuMP.@variable(m, x[1:lg.nv(g),1:lg.nv(g)] >= 0.)
	JuMP.@constraint(m,
		[i=1:lg.nv(g),j=1:lg.nv(g)],
		flow[i,j] - demand[i,j] >= 0.
	)
	JuMP.@constraint(m,
		[i=1:lg.nv(g),j=1:lg.nv(g)],
		capacity[i,j] - flow[i,j] >= 0.
	)
	for n1 in 1:lg.nv(g)
		for n2 in 1:lg.nv(g)
			if !lg.has_edge(g,n1,n2)
				JuMP.@constraint(m, flow[n1,n2] <= 0.)
			end
		end
	end
	# flow conservation constraints
	for node in 1:lg.nv(g)
		if node != source && node != sink
			JuMP.@constraint(m,
				sum(flow[node,j] for j in 1:lg.nv(g)) -
				sum(flow[i,node] for i in 1:lg.nv(g)) == 0
			)
		end
	end
	# source is a net flow producer
	if source ∈ 1:lg.nv(g)
		JuMP.@constraint(m,
			sum(flow[source,j] for j in 1:lg.nv(g)) -
			sum(flow[i,source] for i in 1:lg.nv(g)) >= 0
		)
	end
	# source is a net flow consumer
	if sink ∈ 1:lg.nv(g)
		JuMP.@constraint(m,
			sum(flow[sink,j] for j in 1:lg.nv(g)) -
			sum(flow[i,sink] for i in 1:lg.nv(g)) <= 0
		)
	end
	JuMP.@objective(m, :Min, sum(flow[i,j]*cost[i,j] for i=1:lg.nv(g),j=1:lg.nv(g)))
	solution = JuMP.solve(m)
	return JuMP.getvalue(flow)
end
