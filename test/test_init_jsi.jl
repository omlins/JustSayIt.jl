using Test
using JustSayIt
using JustSayIt.API
using PyCall
import JustSayIt: MODELNAME, VOSK_MODELDIR_PREFIX, COMMAND_RECOGNIZER_ID
import JustSayIt: init_jsi, finalize_jsi, command_names, command, noises_names, noises, model, recognizer, Recognizer

@testset "$(basename(@__FILE__))" begin
    @testset "1. initialization" begin
        commands = Dict("help"    => Help.help,
                        "type"    => Keyboard.type,
                        "redo"    => (Key.ctrl, Key.shift, 'z'),
                        "upwards" => Key.page_up)
        modeldirs = Dict(MODELNAME.DEFAULT.EN_US => joinpath(VOSK_MODELDIR_PREFIX, "vosk-model-small-en-us-0.15"),
                         MODELNAME.TYPE.EN_US    => joinpath(VOSK_MODELDIR_PREFIX, "vosk-model-small-en-us-0.15"))
        mynoises  = Dict(MODELNAME.DEFAULT.EN_US => ["huh"],
                         MODELNAME.TYPE.EN_US    => ["huhuh"])
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
            @test noises(MODELNAME.DEFAULT.EN_US) == ["huh"]
            @test noises(MODELNAME.TYPE.EN_US) == ["huhuh"]
        end;
        @testset "models" begin
            @test isa(model(MODELNAME.DEFAULT.EN_US), PyObject)
        end;
        @testset "recognizers" begin
            @test isa(recognizer(MODELNAME.DEFAULT.EN_US), Recognizer)
            @test isa(recognizer(COMMAND_RECOGNIZER_ID), Recognizer)
        end;
        finalize_jsi()
    end;
end;
