using Test
using JustSayIt
using JustSayIt.API
using PyCall
import JustSayIt: MODELNAME, MODELDIR_PREFIX, DEFAULT_NOISES, COMMAND_RECOGNIZER_ID
import JustSayIt: init_jsi, finalize_jsi, recognizer, noises, reader, start_reading, stop_reading, read_wav, set_default_streamer, reset_all, _are_next


# Test setup
const SAMPLEDIR_CMD     = joinpath("samples", "commands")
const SAMPLEDIR_SILENCE = joinpath("samples", "silence")

commands = Dict("help"      => Help.help,
                "type"      => Keyboard.type,
                "ma"        => Mouse.click_left,
                "select"    => Mouse.press_left,
                "okay"      => Mouse.release_left,
                "middle"    => Mouse.click_middle,
                "right"     => Mouse.click_right,
                "double"    => Mouse.click_double,
                "triple"    => Mouse.click_triple,
                "email"     => Email.email,
                "internet"  => Internet.internet,
                "copy"      => (Key.ctrl, 'c'),
                # "cut"       => (Key.ctrl, 'x'), # NOTE: this is used to test the handling of an unrecognised keyword.
                "paste"     => (Key.ctrl, 'v'),
                "undo"      => (Key.ctrl, 'z'),
                "redo"      => (Key.ctrl, Key.shift, 'z'),
                "page up"   => Key.page_up,
                "page down" => Key.page_down,
                );
modeldirs = Dict(MODELNAME.DEFAULT.EN_US => joinpath(MODELDIR_PREFIX, "vosk-model-small-en-us-0.15"),
                 MODELNAME.TYPE.EN_US    => joinpath(MODELDIR_PREFIX, "vosk-model-small-en-us-0.15"))
init_jsi(commands, modeldirs, DEFAULT_NOISES)

samples = Dict("help"      => read_wav(joinpath(SAMPLEDIR_CMD, "help.wav")),
               "type"      => read_wav(joinpath(SAMPLEDIR_CMD, "type.wav")),
               "ma"        => read_wav(joinpath(SAMPLEDIR_CMD, "ma.wav")),
               "select"    => read_wav(joinpath(SAMPLEDIR_CMD, "select.wav")),
               "okay"      => read_wav(joinpath(SAMPLEDIR_CMD, "okay.wav")),
               "middle"    => read_wav(joinpath(SAMPLEDIR_CMD, "middle.wav")),
               "right"     => read_wav(joinpath(SAMPLEDIR_CMD, "right.wav")),
               "double"    => read_wav(joinpath(SAMPLEDIR_CMD, "double.wav")),
               "triple"    => read_wav(joinpath(SAMPLEDIR_CMD, "triple.wav")),
               "email"     => read_wav(joinpath(SAMPLEDIR_CMD, "email.wav")),
               "internet"  => read_wav(joinpath(SAMPLEDIR_CMD, "internet.wav")),
               "copy"      => read_wav(joinpath(SAMPLEDIR_CMD, "copy.wav")),
               "cut"       => read_wav(joinpath(SAMPLEDIR_CMD, "cut.wav")),
               "paste"     => read_wav(joinpath(SAMPLEDIR_CMD, "paste.wav")),
               "undo"      => read_wav(joinpath(SAMPLEDIR_CMD, "undo.wav")),
               "redo"      => read_wav(joinpath(SAMPLEDIR_CMD, "redo.wav")),
               "page up"   => read_wav(joinpath(SAMPLEDIR_CMD, "page_up.wav")),
               "page down" => read_wav(joinpath(SAMPLEDIR_CMD, "page_down.wav")),
               );
sample_commands = read_wav(joinpath(SAMPLEDIR_CMD, "commands.wav"))
_2  = read_wav(joinpath(SAMPLEDIR_SILENCE, "silence_2001ms.wav"))


@testset "$(basename(@__FILE__))" begin
    @testset "1. print available commands as @info" begin
        id = "commands"
        start_reading([sample_commands; _2]; id=id)
        set_default_streamer(reader, id)
        @test_logs (:info,) Help.help()
        stop_reading(id=id)
    end;
    @testset "2. print specific command help as @info ($cmd)" for cmd in keys(commands)
        sample = samples[cmd]
        id     = cmd
        start_reading([sample; _2]; id=id)
        set_default_streamer(reader, id)
        _are_next(cmd, recognizer(COMMAND_RECOGNIZER_ID), noises(MODELNAME.DEFAULT.EN_US); use_partial_recognitions=false, ignore_unknown=false) # NOTE: this full recognition call is required to have safe reproducable results in the following help call.
        @test_logs (:info,) Help.help()
        stop_reading(id=id)
    end;
    @testset "3. Keyword not recognized @info" begin
        id = "cut"
        start_reading([samples["cut"]; _2]; id=id)
        set_default_streamer(reader, id)
        @test_logs (:info,"Keyword not recognized.") Help.help()
        stop_reading(id=id)
    end;
    recognizer(COMMAND_RECOGNIZER_ID).Reset()
    reset_all(hard=true)
end;


# Test tear down
finalize_jsi()
