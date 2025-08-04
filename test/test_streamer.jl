using Test
using JustSayIt
using PyCall
import JustSayIt: MODELNAME, VOSK_MODELDIR_PREFIX, DEFAULT_NOISES, DEFAULT_READER_ID, AUDIO_ELTYPE
import JustSayIt: init_jsi, finalize_jsi, reader, start_reading, stop_reading, set_default_streamer, default_streamer

# Test setup
const SAMPLEDIR_CMD = joinpath("samples", "commands")

commands = Dict("help"      => Help.help,
                "type"      => Keyboard.type)
modeldirs = Dict(MODELNAME.DEFAULT.EN_US => joinpath(VOSK_MODELDIR_PREFIX, "vosk-model-small-en-us-0.15"),
                 MODELNAME.TYPE.EN_US    => joinpath(VOSK_MODELDIR_PREFIX, "vosk-model-small-en-us-0.15"))

init_jsi(commands, modeldirs, DEFAULT_NOISES)
start_reading(joinpath(SAMPLEDIR_CMD, "help.wav"))


@testset "$(basename(@__FILE__))" begin
    @testset "1. readbytes! (from wave reader)" begin
        wav_reader = reader()
        sample = zeros(UInt8, wav_reader.getnframes()*sizeof(AUDIO_ELTYPE))
        bytes_read = readbytes!(wav_reader, sample)
        @test bytes_read == 68938
    end;
    @testset "2. set default streamer" begin
        @test_throws KeyError default_streamer()
        set_default_streamer(reader, DEFAULT_READER_ID)
        @test isa(default_streamer(), PyObject)
    end
end;


# Test tear down
stop_reading()
finalize_jsi()
