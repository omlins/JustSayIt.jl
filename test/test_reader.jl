using Test
using JustSayIt
using PyCall
import JustSayIt: reader, active_reader_id, start_reading, stop_reading, read_wav

# Test setup
const SAMPLEDIR_CMD = joinpath(@__DIR__, "samples", "commands")
const HELP_WAV      = joinpath(SAMPLEDIR_CMD, "help.wav")


@testset "$(basename(@__FILE__))" begin
    @testset "1. read wav" begin
        sample = read_wav(HELP_WAV)
        @test isa(sample, Vector{UInt8})
        @test length(sample) == 25012
    end
    @testset "2. start/stop reading from byte vector" begin
        sample = read_wav(HELP_WAV)
        id = "help"
        @test isa(start_reading(sample; id=id), IOBuffer)
        @test active_reader_id() == id
        @test isa(reader(id), IOBuffer)
        stop_reading(id=id)
    end;
    @testset "3. start/stop reading from file" begin
        id = "help"
        @test isa(start_reading(HELP_WAV; id=id), IOBuffer)
        @test active_reader_id() == id
        @test isa(reader(id), IOBuffer)
        stop_reading(id=id)
    end;
    @testset "4. start/stop reading from audio input cmd" begin
        id = "help"
        script = "using JustSayIt; JustSayIt.read_wav($(repr(HELP_WAV)))"
        cmd = `$(Base.julia_cmd()) --project=$(Base.active_project()) -e $script`
        @test isa(start_reading(cmd; id=id), Base.Process)
        @test active_reader_id() == id
        @test isa(reader(id), Base.Process)
        stop_reading(id=id)
    end;
end;
