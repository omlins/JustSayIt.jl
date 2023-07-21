using Test
using JustSayIt
using JustSayIt.API
using PyCall
import JustSayIt: MODELNAME, MODELDIR_PREFIX, DEFAULT_NOISES, DIGITS
import JustSayIt: init_jsi, finalize_jsi, voicearg_f_names, voiceargs, recognizer, Recognizer


# Test setup
@voiceargs space=>(valid_input=["world", "universe"]) hello(space::String) = println("hello $space")

@enum Name julia python
@voiceargs (n1=>(valid_input_auto=true), n2=>(valid_input_auto=true)) hi(n1::Name, n2::Name) = println("hi $n1 and $n2")

@voiceargs (
    nr=>(valid_input=(LANG.EN_US=>[keys(DIGITS[LANG.EN_US])...],LANG.FR=>[keys(DIGITS[LANG.FR])...]), interpret_function=Keyboard.interpret_digits_EN_US, use_max_speed=true),
    name=>(valid_input_auto=true),
    question=>(model=MODELNAME.TYPE.EN_US, ignore_unknown=true, vararg_end="end", vararg_max=10, vararg_timeout=5.0)
) function ask(nr::Integer, name::Name, question::String...)
    println("[Q$nr] Hi $name, could you please $(join(question," "))?")
end

commands = Dict("help"  => Help.help,
                "hello" => hello)
modeldirs = Dict(MODELNAME.DEFAULT.EN_US => joinpath(MODELDIR_PREFIX, "vosk-model-small-en-us-0.15"),
                 MODELNAME.TYPE.EN_US    => joinpath(MODELDIR_PREFIX, "vosk-model-small-en-us-0.15"))
init_jsi(commands, modeldirs, DEFAULT_NOISES)


@testset "$(basename(@__FILE__))" begin
    @testset "1. voicearg dictionary" begin
        @testset "functions" begin
            @test :hello in voicearg_f_names()
            @test :hi in voicearg_f_names()
            @test :ask in voicearg_f_names()
        end;
        @testset "voiceargs" begin
            @test issetequal(keys(voiceargs(:hello)), [:space])
            @test issetequal(keys(voiceargs(:hi)), [:n1, :n2])
            @test issetequal(keys(voiceargs(:ask)), [:nr, :name, :question])
        end;
        @testset "kwargs" begin
            @test issetequal(keys(voiceargs(:hello)[:space]), [:recognizer, :valid_input])
            @test issetequal(keys(voiceargs(:hi)[:n1]), [:recognizer, :valid_input, :valid_input_auto])
            @test issetequal(keys(voiceargs(:hi)[:n2]), [:recognizer, :valid_input, :valid_input_auto])
            @test issetequal(keys(voiceargs(:ask)[:nr]), [:recognizer, :valid_input, :interpret_function, :use_max_speed])
            @test issetequal(keys(voiceargs(:ask)[:name]), [:recognizer, :valid_input, :valid_input_auto])
            @test issetequal(keys(voiceargs(:ask)[:question]), [:model, :ignore_unknown, :vararg_end, :vararg_max, :vararg_timeout])
        end;
        @testset "kwarg content" begin
            @testset "recognizers" begin
                @test isa(voiceargs(:hello)[:space][:recognizer], Recognizer)
                @test isa(voiceargs(:hi)[:n1][:recognizer], Recognizer)
                @test isa(voiceargs(:hi)[:n2][:recognizer], Recognizer)
                @test isa(voiceargs(:ask)[:nr][:recognizer], Recognizer)
                @test isa(voiceargs(:ask)[:name][:recognizer], Recognizer)
            end;
            @testset "valid_input" begin
                @test voiceargs(:hello)[:space][:valid_input] == ["world", "universe"]
                @test voiceargs(:hi)[:n1][:valid_input] == ["julia", "python"]
                @test voiceargs(:hi)[:n2][:valid_input] == ["julia", "python"]
                @test voiceargs(:ask)[:nr][:valid_input] == Dict(LANG.EN_US=>[keys(DIGITS[LANG.EN_US])...],LANG.FR=>[keys(DIGITS[LANG.FR])...])
                @test voiceargs(:ask)[:name][:valid_input] == ["julia", "python"]
            end;
            @testset "valid_input_auto" begin
                @test voiceargs(:hi)[:n1][:valid_input_auto] == true
                @test voiceargs(:hi)[:n2][:valid_input_auto] == true
                @test voiceargs(:ask)[:name][:valid_input_auto] == true
            end;
            @testset "interpret_function" begin
                @test voiceargs(:ask)[:nr][:interpret_function] == Keyboard.interpret_digits_EN_US
            end;
            @testset "use_max_speed" begin
                @test voiceargs(:ask)[:nr][:use_max_speed] == true
            end;
            @testset "ignore_unknown" begin
                @test voiceargs(:ask)[:question][:ignore_unknown] == true
            end;
            @testset "model" begin
                @test voiceargs(:ask)[:question][:model] == MODELNAME.TYPE.EN_US
            end;
            @testset "vararg_end" begin
                @test voiceargs(:ask)[:question][:vararg_end] == "end"
            end;
            @testset "vararg_max" begin
                @test voiceargs(:ask)[:question][:vararg_max] == 10
            end;
            @testset "vararg_timeout" begin
                @test voiceargs(:ask)[:question][:vararg_timeout] == 5.0
            end;
        end;
    end;
    @testset "2. recognizers" begin
        @test isa(recognizer(:hello, :space), Recognizer)
        @test isa(recognizer(:hi, :n1), Recognizer)
        @test isa(recognizer(:hi, :n2), Recognizer)
        @test isa(recognizer(:ask, :nr), Recognizer)
        @test isa(recognizer(:ask, :name), Recognizer)
    end;
    @testset "3. voicearg wrapper" begin
        @testset "defined" begin
            @test length(methods(hello)) == 2
            @test length(methods(hi)) == 2
            @test length(methods(ask)) == 2
        end;
    end;
end;


# Test tear down
finalize_jsi()
