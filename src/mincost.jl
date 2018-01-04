function mincost_flow(g::lg.DiGraph, 
		capacity::AbstractMatrix,
		demand::AbstractMatrix,
		cost::AbstractMatrix,
		source::Int,
		sink::Int,
		solver::AbstractMathProgSolver = GLPKSolverMIP())
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
	JuMP.@objective(m, :Min, sum(flow[i,j]*cost[i,j] for i=1:lg.nv(g),j=1:lg.nv(g)))
	solution = JuMP.solve(m)
	return JuMP.getvalue(flow)
end
