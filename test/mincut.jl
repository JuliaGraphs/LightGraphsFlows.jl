@testset "Mincut" begin

    g = lg.CompleteDiGraph(5)
    cap1 = [
       0.0 2.0 2.0 0.0 0.0
       0.0 0.0 0.0 0.0 3.0
       0.0 1.0 0.0 3.0 0.0
       0.0 0.0 0.0 0.0 1.0
       0.0 0.0 0.0 0.0 0.0
    ];
    (part1, part2, value) = LightGraphsFlows.mincut(g,1,5,cap1,LightGraphsFlows.PushRelabelAlgorithm())
    @test value ≈ 4.0
    @test part1 == [1]
    @test sort(part2) == collect(2:5)
    cap2 = [
       0.0 3.0 2.0 0.0 0.0
       0.0 0.0 0.0 0.0 3.0
       0.0 1.0 0.0 3.0 0.0
       0.0 0.0 0.0 0.0 1.5
       0.0 0.0 0.0 0.0 0.0
    ];
    (part1, part2, value) = LightGraphsFlows.mincut(g,1,5,cap2,LightGraphsFlows.PushRelabelAlgorithm())
    @test value ≈ 4.5
    @test sort(part1) == collect(1:4)
    @test part2 == [5]

    g2 = lg.DiGraph(5)
    lg.add_edge!(g2,1,2)
    lg.add_edge!(g2,1,3)
    lg.add_edge!(g2,3,4)
    lg.add_edge!(g2,3,2)
    lg.add_edge!(g2,2,5)

    (part1, part2, value) = LightGraphsFlows.mincut(g2,1,5,cap1,LightGraphsFlows.PushRelabelAlgorithm())
    @test value ≈ 3.0
    @test sort(part1) == [1,3,4]
    @test sort(part2) == [2,5]    

end
