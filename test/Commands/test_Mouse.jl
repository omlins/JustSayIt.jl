using Test
using JustSayIt

functions = [:click_double, :click_left, :click_middle, :click_right, :click_triple, :press_left, :release_left]

@testset "$(basename(@__FILE__))" begin
    @testset "Module Mouse available" begin
        @test @isdefined Mouse
    end
    @testset "function $f available" for f in functions
        @test f in names(Mouse; all=true)
    end;
end;
