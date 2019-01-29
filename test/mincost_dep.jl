using Clp: ClpSolver
using SparseArrays: spzeros
#This is for testing of the depreciated interface.   Please remove once that interface is removed
@testset "Minimum-cost flow Depreciated" begin

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
    w = zeros(6,6)
    w[1,3] = 10.
    w[1,4] = 5.
    w[2,3] = 2.
    w[2,4] = 2.
    # v2 -> sink have demand of one
    demand = spzeros(6,6)
    demand[3,6] = 1
    demand[4,6] = 1
    capacity = ones(6,6)

    flow = mincost_flow(g, capacity, demand, w, ClpSolver(), 5, 6)
    @test flow[5,1] == 1
    @test flow[5,2] == 1
    @test flow[3,6] == 1
    @test flow[4,6] == 1
    @test flow[1,4] == 1
    @test flow[2,4] == 0
    @test flow[2,3] == 1
    @test flow[1,3] == 0
    @test sum(diag(flow)) == 0

    # flow conservation property
    for n1 = 1:4
        @test sum(flow[n1,:]) ≈ sum(flow[:,n1])
    end

    # no demand => null flow
    d2 = spzeros(6,6)
    flow = mincost_flow(g, capacity, d2, w, ClpSolver(), 5, 6)
    for idx in 1:6
        for jdx in 1:6
            @test flow[idx,jdx] ≈ 0.0
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
    flow = mincost_flow(g, capacity, demand, costs, ClpSolver())
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
    flow = mincost_flow(g, capacity, demand, costs, ClpSolver())
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
