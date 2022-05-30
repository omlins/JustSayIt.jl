using Test
using JustSayIt

functions = [:email]

@testset "$(basename(@__FILE__))" begin
    @testset "Module Email available" begin
        @test @isdefined Email
    end
    @testset "function $f available" for f in functions
        @test f in names(Email; all=true)
    end;
end;
