using Test
using JustSayIt
using JustSayIt.API
using PyCall
import JustSayIt: MODELNAME, VOSK_MODELDIR_PREFIX, DEFAULT_NOISES, AUDIO_ELTYPE, COMMAND_RECOGNIZER_ID
import JustSayIt: init_jsi, finalize_jsi, recognizer, Recognizer, noises, reader, start_reading, stop_reading, read_wav, set_default_streamer, reset_all, reset, next_partial_recognition, next_recognition, next_token, _is_next, is_next, _are_next, are_next


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
                "cut"       => (Key.ctrl, 'x'),
                "paste"     => (Key.ctrl, 'v'),
                "undo"      => (Key.ctrl, 'z'),
                "redo"      => (Key.ctrl, Key.shift, 'z'),
                "page up"   => Key.page_up,
                "page down" => Key.page_down,
                );
modeldirs = Dict(MODELNAME.DEFAULT.EN_US => joinpath(VOSK_MODELDIR_PREFIX, "vosk-model-small-en-us-0.15"),
                 MODELNAME.TYPE.EN_US    => joinpath(VOSK_MODELDIR_PREFIX, "vosk-model-small-en-us-0.15"))
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
_05 = read_wav(joinpath(SAMPLEDIR_SILENCE, "silence_501ms.wav"))
_1  = read_wav(joinpath(SAMPLEDIR_SILENCE, "silence_1001ms.wav"))
_2  = read_wav(joinpath(SAMPLEDIR_SILENCE, "silence_2001ms.wav"))
_5  = read_wav(joinpath(SAMPLEDIR_SILENCE, "silence_5001ms.wav"))

twoword_cmds    = ["page up", "page down"]
singleword_cmds = [cmd for cmd in keys(commands) if cmd ∉ twoword_cmds]


@testset "$(basename(@__FILE__))" begin
    @testset "1. dynamic recognizers" begin
        valid_input = ["world", "universe"]
        @test isa(recognizer(valid_input, noises(MODELNAME.DEFAULT.EN_US)), Recognizer)
        @test isa(recognizer(valid_input, noises(MODELNAME.TYPE.EN_US); modelname=MODELNAME.TYPE.EN_US), Recognizer)
    end;
    @testset "2. single-word recognitions ($cmd)" for cmd in singleword_cmds
        sample = samples[cmd]
        id     = cmd
        start_reading([sample; _2]; id=id)
        set_default_streamer(reader, id)
        @testset "partial" begin
            text, is_partial_result, has_timed_out = next_partial_recognition(recognizer(COMMAND_RECOGNIZER_ID))
            @test split(text)[end] == cmd
            @test is_partial_result
            @test !has_timed_out
        end;
        @testset "full" begin
            text = next_recognition(recognizer(COMMAND_RECOGNIZER_ID))
            @test split(text)[end] == cmd
        end;
        stop_reading(id=id)
    end;
    @testset "3. two-word recognitions ($cmd)" for cmd in twoword_cmds
        sample = samples[cmd]
        id     = cmd
        start_reading([sample; _2]; id=id)
        set_default_streamer(reader, id)
        @testset "full" begin
            next_partial_recognition(recognizer(COMMAND_RECOGNIZER_ID))
            text = next_recognition(recognizer(COMMAND_RECOGNIZER_ID))
            @test join(split(text)[end-1:end], " ") == cmd
        end;
        stop_reading(id=id)
    end;
    reset(recognizer(COMMAND_RECOGNIZER_ID), hard=true)
    reset_all(hard=true)
    @testset "4. token buffering - max speed ($cmd)" for cmd in singleword_cmds
        sample = samples[cmd]
        id     = cmd
        start_reading([sample; _05]; id=id)
        set_default_streamer(reader, id)
        @testset "_is_next" begin
            @test _is_next(cmd, recognizer(COMMAND_RECOGNIZER_ID), noises(MODELNAME.DEFAULT.EN_US); use_partial_recognitions=true, ignore_unknown=false)
        end;
        # NOTE: The recogniser resets implied by dynamic recognisers in the following tests seem to break these tests.
        # @testset "is_next" begin
        #     @test is_next(cmd; use_max_speed=true, ignore_unknown=false)
        # end;
        # @testset "is_next (multi-token check)" begin
        #     @test is_next(["cat", cmd, "dog"]; use_max_speed=true, ignore_unknown=false)
        # end;
        @testset "next_token" begin
            token = next_token(recognizer(COMMAND_RECOGNIZER_ID), noises(MODELNAME.DEFAULT.EN_US); use_partial_recognitions=true, ignore_unknown=false)
            @test token == cmd
        end;
        stop_reading(id=id)
    end;
    @testset "5. token buffering - max accuracy ($cmd)" for cmd in singleword_cmds
        sample = samples[cmd]
        id     = cmd
        start_reading([sample; _2]; id=id)
        set_default_streamer(reader, id)
        @testset "_is_next" begin
            @test _is_next(cmd, recognizer(COMMAND_RECOGNIZER_ID), noises(MODELNAME.DEFAULT.EN_US); use_partial_recognitions=false, ignore_unknown=false)
        end;
        # NOTE: The recogniser resets implied by dynamic recognisers in the following tests seem to break these tests.
        # @testset "is_next" begin
        #     @test is_next(cmd; use_max_speed=false, ignore_unknown=false)
        # end;
        # @testset "is_next (multi-token check)" begin
        #     @test is_next(["cat", cmd, "dog"]; use_max_speed=false, ignore_unknown=false)
        # end;
        @testset "next_token" begin
            token = next_token(recognizer(COMMAND_RECOGNIZER_ID), noises(MODELNAME.DEFAULT.EN_US); use_partial_recognitions=false, ignore_unknown=false)
            @test token == cmd
        end;
        stop_reading(id=id)
    end;
    @testset "6. token buffering (two-word retrieval) - max accuracy ($cmd)" for cmd in twoword_cmds
        sample = samples[cmd]
        id     = cmd
        start_reading([sample; _2]; id=id)
        set_default_streamer(reader, id)
        @testset "_are_next" begin
            tokens = String.(split(cmd))
            is_match, match = _are_next(tokens, recognizer(COMMAND_RECOGNIZER_ID), noises(MODELNAME.DEFAULT.EN_US); use_partial_recognitions=false, ignore_unknown=false)
            @test is_match
            @test join(match, " ") == cmd
        end;
        @testset "are_next" begin
            tokens = String.(split(cmd))
            is_match, match = are_next(tokens; use_max_speed=false, ignore_unknown=false)
            @test is_match
            @test join(match, " ") == cmd
        end;
        @testset "are_next (additional tokens for check)" begin
            tokens = String.(split("cat "*cmd*" dog"))
            is_match, match = are_next(tokens; use_max_speed=false, ignore_unknown=false)
            @test is_match
            @test join(match, " ") == cmd
        end;
        @testset "next_token" begin
            token  = next_token(recognizer(COMMAND_RECOGNIZER_ID), noises(MODELNAME.DEFAULT.EN_US); use_partial_recognitions=false, ignore_unknown=false)
            tokens = token * " " * next_token(recognizer(COMMAND_RECOGNIZER_ID), noises(MODELNAME.DEFAULT.EN_US); use_partial_recognitions=false, ignore_unknown=false)
            @test tokens == cmd
        end;
        stop_reading(id=id)
    end;
end;


# Test tear down
finalize_jsi()
