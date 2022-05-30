using Test
using JustSayIt

functions = [:internet]

@testset "$(basename(@__FILE__))" begin
    @testset "Module Internet available" begin
        @test @isdefined Internet
    end
    @testset "function $f available" for f in functions
        @test f in names(Internet; all=true)
    end;
end;
