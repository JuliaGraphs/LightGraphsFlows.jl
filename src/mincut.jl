"""
    mincut(flow_graph::lg.IsDirected, source::Integer, target::Integer, capacity_matrix::AbstractMatrix, algorithm::AbstractFlowAlgorithm)

Compute the min-cut between `source` and `target` for the given graph.
First computes the maxflow using `algorithm` and then builds the partition of the residual graph
Returns a triplet `(part1, part2, flow)` with the partition containing the source, the partition containing the target (the rest) and the min-cut(max-flow) value
"""
function mincut(
        flow_graph::lg.DiGraph,             # the input graph
        source::Integer,                       # the source vertex
        target::Integer,                       # the target vertex
        capacity_matrix::AbstractMatrix,       # edge flow capacities
        algorithm::AbstractFlowAlgorithm       # keyword argument for algorithm
    )
    flow, flow_matrix = maximum_flow(flow_graph, source, target, capacity_matrix, algorithm)
    part1 = typeof(source)[]
    queue = [source]
    while !isempty(queue)
        node = pop!(queue)
        push!(part1, node)
        succs = [succ for succ in lg.outneighbors(flow_graph, node) if capacity_matrix[node,succ] - flow_matrix[node, succ]>0.0 && succ ∉ mincut]
        preds = [pred for pred in lg.inneighbors(flow_graph, node) if flow_matrix[pred,node]>0.0 && pred ∉ mincut]
        append!(queue, succs)
        append!(queue, preds)
    end
    part2 = [node for node in 1:lg.nv(flow_graph) if node ∉ part1]
    return (part1, part2, flow)
end
