using Test
using JustSayIt
using JustSayIt.API
using PyCall
import JustSayIt: MODELNAME, VOSK_MODELDIR_PREFIX, COMMAND_RECOGNIZER_ID, DEFAULT_READER_ID
import JustSayIt: init_jsi, init_commands, finalize_jsi, command_names, command, noises_names, noises, model, recognizer, Recognizer, reader, start_reading, set_default_streamer

const HELP_WAV = joinpath(@__DIR__, "samples", "commands", "help.wav")

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
        init_jsi(modeldirs=modeldirs, noises=mynoises, use_llm=false, use_tts=false, record=false)
        init_commands(commands)
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
        start_reading(HELP_WAV)
        set_default_streamer(reader; isreader=true, id=DEFAULT_READER_ID)
        finalize_jsi()
    end;
end;
