using Test
using JustSayIt
using JustSayIt.API
using PyCall
import JustSayIt: MODELNAME, VOSK_MODELDIR_PREFIX, DEFAULT_NOISES, DEFAULT_READER_ID
import JustSayIt: init_jsi, init_commands, finalize_jsi, reader, start_reading, set_default_streamer

commands = Dict("help"      => Help.help,
                "type"      => Keyboard.type)
modeldirs = Dict(MODELNAME.DEFAULT.EN_US => joinpath(VOSK_MODELDIR_PREFIX, "vosk-model-small-en-us-0.15"),
                 MODELNAME.TYPE.EN_US    => joinpath(VOSK_MODELDIR_PREFIX, "vosk-model-small-en-us-0.15"))
const HELP_WAV = joinpath(@__DIR__, "samples", "commands", "help.wav")

init_jsi(modeldirs=modeldirs, noises=DEFAULT_NOISES, use_llm=false, use_tts=false, record=false)
init_commands(commands)
start_reading(HELP_WAV)
set_default_streamer(reader; isreader=true, id=DEFAULT_READER_ID)


@testset "$(basename(@__FILE__))" begin
    @testset "1. finalizing" begin
        finalize_jsi()
        @test true # meaning reached that point.
    end;
end;
