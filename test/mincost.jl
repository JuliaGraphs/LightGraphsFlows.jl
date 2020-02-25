import GLPK
using JuMP

using SparseArrays: spzeros

@testset "Minimum-cost flow" begin

    # bipartite oriented + source & sink
    # source 5, sink 6, v1 {1, 2} v2 {3, 4}
    g = lg.DiGraph(6)
    lg.add_edge!(g, 5, 1)
    lg.add_edge!(g, 5, 2)
    lg.add_edge!(g, 3, 6)
    lg.add_edge!(g, 4, 6)
    lg.add_edge!(g, 1, 3)
    lg.add_edge!(g, 1, 4)
    lg.add_edge!(g, 2, 3)
    lg.add_edge!(g, 2, 4)
    cost = zeros(6,6)
    cost[1,3] = 10.
    cost[1,4] = 5.
    cost[2,3] = 2.
    cost[2,4] = 2.
    # v2 -> sink have demand of one
    demand = spzeros(6,6)
    demand[3,6] = 1
    demand[4,6] = 1
    capacity = ones(6,6)

    o = with_optimizer(GLPK.Optimizer)
    node_demand = spzeros(lg.nv(g))
    flow = mincost_flow(g, node_demand, capacity, cost, o, edge_demand=demand, source_nodes=[5], sink_nodes=[6])
    @test flow[5,1] ≈ 1
    @test flow[5,2] ≈ 1
    @test flow[3,6] ≈ 1
    @test flow[4,6] ≈ 1
    @test flow[1,4] ≈ 1
    @test flow[2,4] ≈ 0
    @test flow[2,3] ≈ 1
    @test flow[1,3] ≈ 0

    # flow conservation property
    for n1 = 1:4
        @test sum(flow[n1, nout] for nout in outneighbors(g, n1)) ≈ sum(flow[nin, n1] for nin in inneighbors(g, n1))
    end

    #--- Same test without edge_demands & positive cost should result in null flow
    flow = mincost_flow(g, node_demand, capacity, cost, o, source_nodes=[5], sink_nodes=[6])
    
    @test flow[5,1] ≈ 0
    @test flow[5,2] ≈ 0
    @test flow[3,6] ≈ 0
    @test flow[4,6] ≈ 0
    @test flow[1,4] ≈ 0
    @test flow[2,4] ≈ 0
    @test flow[2,3] ≈ 0
    @test flow[1,3] ≈ 0

    # flow conservation property
    for n1 = 1:4
        @test sum(flow[n1,:]) ≈ sum(flow[:,n1])
    end


    #run same test again with nodal demands
    node_demand=spzeros(6)
    node_demand[5]=-2
    node_demand[6]=2
    #--- Same test without edge_demands
    flow = mincost_flow(g, node_demand, capacity, cost, o, source_nodes=[5],sink_nodes=[6])
    @test flow[5,1] ≈ 1
    @test flow[5,2] ≈ 1
    @test flow[3,6] ≈ 1
    @test flow[4,6] ≈ 1
    @test flow[1,4] ≈ 1
    @test flow[2,4] ≈ 0
    @test flow[2,3] ≈ 1
    @test flow[1,3] ≈ 0
    @test sum(diag(flow)) ≈ 0

    # flow conservation property
    for n1 = 1:4
        @test sum(flow[n1,:]) ≈ sum(flow[:,n1])
    end


    # no demand => null flow
    d2 = spzeros(6,6)
    flow = mincost_flow(g, spzeros(lg.nv(g)), capacity, cost, o, edge_demand=d2, source_nodes=[5], sink_nodes=[6])
    for i in 1:6
        for j in 1:6
            @test flow[i,j] ≈ 0.0
        end
    end

    # graph without sink or source
    g = lg.DiGraph(6)
    # create circuit
    for s in 1:5
        lg.add_edge!(g, s, s+1)
    end
    lg.add_edge!(g, 6, 1)
    lg.add_edge!(g, 2, 5) # shortcut

    capacity = ones(6,6)
    demand = spzeros(6,6)
    demand[1,2] = 1
    costs = ones(6,6)
    flow = mincost_flow(g,spzeros(lg.nv(g)), capacity, costs, o, edge_demand=demand)
    active_flows = [(1,2), (2,5), (5,6),(6,1)]
    for s in 1:6
        for t in 1:6
            if (s,t) in active_flows
                @test flow[s,t] ≈ 1.
            else
                @test flow[s,t] ≈ 0.
            end
        end
    end
    # flow conservation property
    for n1 = 1:6
        @test sum(flow[n1,:]) ≈ sum(flow[:,n1])
    end
    # higher short-circuit cost
    costs[2,5] = 10.
    flow = mincost_flow(g,spzeros(lg.nv(g)), capacity, costs, o, edge_demand=demand)
    active_flows = [(1,2),(2,3),(3,4),(4,5),(5,6),(6,1)]
    for s in 1:6
        for t in 1:6
            if (s,t) in active_flows
                @test flow[s,t] ≈ 1.
            else
                @test flow[s,t] ≈ 0.
            end
        end
    end
    # flow conservation property
    for n1 = 1:6
        @test sum(flow[n1,:]) ≈ sum(flow[:,n1])
    end
end
