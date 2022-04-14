using Test
using JustSayIt
using JustSayIt.API
using PyCall
import JustSayIt: DEFAULT_MODEL_NAME, TYPE_MODEL_NAME, MODELDIR_PREFIX, COMMAND_RECOGNIZER_ID
import JustSayIt: command_names, command, noises_names, noises, model, recognizer

@testset "$(basename(@__FILE__))" begin
    @testset "1. initialization" begin
        commands = Dict("help"    => Help.help,
                        "type"    => Keyboard.type,
                        "redo"    => (Key.ctrl, Key.shift, 'z'),
                        "upwards" => Key.page_up)
        modeldirs = Dict(DEFAULT_MODEL_NAME => joinpath(MODELDIR_PREFIX, "vosk-model-small-en-us-0.15"),
                         TYPE_MODEL_NAME    => joinpath(MODELDIR_PREFIX, "vosk-model-small-en-us-0.15"))
        mynoises  = Dict(DEFAULT_MODEL_NAME => ["huh"],
                         TYPE_MODEL_NAME    => ["huhuh"])
        init_jsi(commands, modeldirs, mynoises)
        @testset "commands" begin
            @test command_names() == keys(commands)
            @test command("help") == Help.help
            @test command("type") == Keyboard.type
            @test command("redo") == (Key.ctrl, Key.shift, 'z')
            @test command("upwards") == Key.page_up
        end;
        @testset "noises" begin
            @test noises_names() == keys(mynoises)
            @test noises(DEFAULT_MODEL_NAME) == ["huh"]
            @test noises(TYPE_MODEL_NAME) == ["huhuh"]
        end;
        @testset "models" begin
            @test isa(model(DEFAULT_MODEL_NAME), PyObject)
        end;
        @testset "recognizers" begin
            @test isa(recognizer(DEFAULT_MODEL_NAME), PyObject)
            @test isa(recognizer(COMMAND_RECOGNIZER_ID), PyObject)
        end;
        finalize_jsi()
    end;
end;
