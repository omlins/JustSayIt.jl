using Test
using JustSayIt
using JustSayIt.API
import JustSayIt: validate_voiceconfig, VALID_VOICEARGS_KWARGS, @prettyexpand, remove_linenumbernodes!
import JustSayIt.Exceptions: KeywordArgumentError

# Test setup
f1(x; y=1, language="")             = "$x,$y,$language"
f2(x; y=1, language="", timeout="") = "$x,$y,$language,$timeout"


@testset "$(basename(@__FILE__))" begin
    @testset "1. validate voiceconfig" begin
        @test (; language="de") == validate_voiceconfig((; language="de"))
        @test (language="de", timeout=5.0) == validate_voiceconfig((language="de", timeout=5.0))
    end;
    
    @testset "2. @voiceconfig expansion" begin
        @testset "call" begin
            expansion = @prettyexpand @voiceconfig language="de" f1(1; y=2)
            @test expansion == :(f1(1; y = 2, JustSayIt.validate_voiceconfig((; $(Expr(:(=), :language, "de"))))...))

            expansion = @prettyexpand @voiceconfig (language="de", timeout=5.0) f2(1; y=2)
            @test expansion == :(f2(1; y = 2, JustSayIt.validate_voiceconfig((language = "de", timeout = 5.0))...))

            expansion = @prettyexpand @voiceconfig language="de" f1(1)
            @test expansion == :(f1(1; JustSayIt.validate_voiceconfig((; $(Expr(:(=), :language, "de"))))...))
        end;
        @testset "symbol" begin
            expansion = @prettyexpand @voiceconfig language="de" f1
            @test expansion == remove_linenumbernodes!(:(((args...,; kwargs...)->begin 
                f1(args...; kwargs..., JustSayIt.validate_voiceconfig((; $(Expr(:(=), :language, "de"))))...)
            end)))

            expansion = @prettyexpand @voiceconfig (language="it", timeout=5.0) f2
            @test expansion == remove_linenumbernodes!(:(((args...,; kwargs...)->begin 
                f2(args...; kwargs..., JustSayIt.validate_voiceconfig((language = "it", timeout = 5.0))...)
            end)))
        end;
    end;
    
    @testset "3. @voiceconfig call" begin
        g1 = @voiceconfig language="de" f1
        g2 = @voiceconfig (language="de", timeout=5.0) f2
        @testset "direct call" begin
            @test "1,2,de"     == @voiceconfig language="de" f1(1; y=2)
            @test "1,2,de,5.0" == @voiceconfig (language="de", timeout=5.0) f2(1; y=2)
            @test "1,1,de"     == @voiceconfig language="de" f1(1)
        end;
        @testset "symbol call" begin     
            @test "1,2,de"     == g1(1; y=2)
            @test "1,2,de,5.0" == g2(1; y=2)
            @test "1,1,de"     == g1(1)
        end;
    end;
        
    @testset "4. error handling" begin
        @testset "validate voiceconfig" begin
            @testset "invalid types" begin
                @test_throws ArgumentError validate_voiceconfig(:language => "de")
                @test_throws ArgumentError validate_voiceconfig(Dict(:language => "de"))
                @test_throws ArgumentError validate_voiceconfig("de")
                @test_throws ArgumentError validate_voiceconfig(99)
            end;
            @testset "invalid keys" begin
                @test_throws KeywordArgumentError validate_voiceconfig((; language="de", invalid_key="value"))
            end;
            @testset "invalid values" begin
                @test_throws KeywordArgumentError validate_voiceconfig((; language=:de))
                @test_throws KeywordArgumentError validate_voiceconfig((; timeout=5))
                @test_throws KeywordArgumentError validate_voiceconfig((; use_max_speed="true"))
            end;
        end;
    end;
end;