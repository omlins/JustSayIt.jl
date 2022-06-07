using Test

@testset "$(basename(@__FILE__))" begin
    @testset "1. using JustSayIt" begin
        using JustSayIt
        @test true
    end;
    @testset "2. using JustSayIt.API" begin
        using JustSayIt.API
        @test true
    end;
end;
