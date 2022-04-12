using Test
using JustSayIt
using JustSayIt.API
using PyCall
import JustSayIt: DEFAULT_MODEL_NAME, TYPE_MODEL_NAME, MODELDIR_PREFIX, DEFAULT_NOISES, DIGITS_ENGLISH
import JustSayIt: voicearg_f_names, voiceargs, recognizer


# Test setup
@voiceargs space=>(valid_input=["world", "universe"]) hello(space::String) = println("hello $space")

@enum Name julia python
@voiceargs (n1=>(valid_input_auto=true), n2=>(valid_input_auto=true)) hi(n1::Name, n2::Name) = println("hi $n1 and $n2")

@voiceargs (
    nr=>(valid_input=[keys(DIGITS_ENGLISH)...], interpret_function=Keyboard.interpret_digits, use_max_speed=true),
    name=>(valid_input_auto=true),
    question=>(model=TYPE_MODEL_NAME, vararg_end="end", vararg_max=10, vararg_timeout=5.0)
) function ask(nr::Integer, name::Name, question::String...)
    println("[Q$nr] Hi $name, could you please $(join(question," "))?")
end

commands = Dict("help"  => Help.help,
                "hello" => hello)
modeldirs = Dict(DEFAULT_MODEL_NAME => joinpath(MODELDIR_PREFIX, "vosk-model-small-en-us-0.15"),
                 TYPE_MODEL_NAME    => joinpath(MODELDIR_PREFIX, "vosk-model-small-en-us-0.15"))
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
            @test issetequal(keys(voiceargs(:ask)[:question]), [:model, :vararg_end, :vararg_max, :vararg_timeout])
        end;
        @testset "kwarg content" begin
            @testset "recognizers" begin
                @test isa(voiceargs(:hello)[:space][:recognizer], PyObject)
                @test isa(voiceargs(:hi)[:n1][:recognizer], PyObject)
                @test isa(voiceargs(:hi)[:n2][:recognizer], PyObject)
                @test isa(voiceargs(:ask)[:nr][:recognizer], PyObject)
                @test isa(voiceargs(:ask)[:name][:recognizer], PyObject)
            end;
            @testset "valid_input" begin
                @test voiceargs(:hello)[:space][:valid_input] == ["world", "universe"]
                @test voiceargs(:hi)[:n1][:valid_input] == ["julia", "python"]
                @test voiceargs(:hi)[:n2][:valid_input] == ["julia", "python"]
                @test voiceargs(:ask)[:nr][:valid_input] == [keys(DIGITS_ENGLISH)...]
                @test voiceargs(:ask)[:name][:valid_input] == ["julia", "python"]
            end;
            @testset "valid_input_auto" begin
                @test voiceargs(:hi)[:n1][:valid_input_auto] == true
                @test voiceargs(:hi)[:n2][:valid_input_auto] == true
                @test voiceargs(:ask)[:name][:valid_input_auto] == true
            end;
            @testset "interpret_function" begin
                @test voiceargs(:ask)[:nr][:interpret_function] == Keyboard.interpret_digits
            end;
            @testset "use_max_speed" begin
                @test voiceargs(:ask)[:nr][:use_max_speed] == true
            end;
            @testset "model" begin
                @test voiceargs(:ask)[:question][:model] == TYPE_MODEL_NAME
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
        @test isa(recognizer(:hello, :space), PyObject)
        @test isa(recognizer(:hi, :n1), PyObject)
        @test isa(recognizer(:hi, :n2), PyObject)
        @test isa(recognizer(:ask, :nr), PyObject)
        @test isa(recognizer(:ask, :name), PyObject)
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
