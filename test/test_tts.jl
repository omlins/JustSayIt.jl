using Test
using JustSayIt
using PyCall
import JustSayIt: dump
import JustSayIt: start_tts, set_tts_async_default, TTS_DEFAULT_ENGINE, TTS_DEFAULT_ENGINE_CPU
import JustSayIt: MODELNAME, VOSK_MODELDIR_PREFIX, DEFAULT_NOISES, AUDIO_ELTYPE, COMMAND_RECOGNIZER_ID
import JustSayIt: init_jsi, finalize_jsi, recognizer, Recognizer, noises, reader, start_reading, stop_reading, read_wav, set_default_streamer, reset_all, reset, next_partial_recognition, next_recognition, next_token, _is_next, is_next, _are_next, are_next

# Test setup
commands = Dict("help" => Help.help)
modeldirs = Dict(MODELNAME.DEFAULT.EN_US => joinpath(VOSK_MODELDIR_PREFIX, "vosk-model-small-en-us-0.15"),
                 MODELNAME.TYPE.EN_US    => joinpath(VOSK_MODELDIR_PREFIX, "vosk-model-small-en-us-0.15"))
init_jsi(commands, modeldirs, DEFAULT_NOISES)
use_gpu = true
tts_engine = use_gpu ? TTS_DEFAULT_ENGINE : TTS_DEFAULT_ENGINE_CPU
start_tts(tts_engine)
set_tts_async_default(false)

@testset "$(basename(@__FILE__))" begin
    @testset "1. single-word synthesis" begin
        cmd = "help"
        id = cmd
        audio_input_cmd = `julia -e 'using JustSayIt; JustSayIt.dump("help huh")'`
        start_reading(audio_input_cmd, id=id)
        set_default_streamer(reader, id)

        text = next_recognition(recognizer(COMMAND_RECOGNIZER_ID))
        @test split(text)[end] == cmd

        stop_reading(id=id)
    end;
end;
