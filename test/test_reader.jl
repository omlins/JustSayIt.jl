using Test
using JustSayIt
using PyCall
import JustSayIt: reader, active_reader_id, start_reading, stop_reading, read_wav

# Test setup
const SAMPLEDIR_CMD = joinpath("samples", "commands")


@testset "$(basename(@__FILE__))" begin
    @testset "1. read wav" begin
        sample = read_wav(joinpath(SAMPLEDIR_CMD, "help.wav"))
        @test isa(sample, Vector{UInt8})
        @test length(sample) == 68938
    end
    @testset "2. start/stop reading from byte vector" begin
        sample = read_wav(joinpath(SAMPLEDIR_CMD, "help.wav"))
        id = "help"
        @test isa(start_reading(sample; id=id), IOBuffer)
        @test active_reader_id() == id
        @test isa(reader(id), IOBuffer)
        stop_reading(id=id)
    end;
    @testset "3. start/stop reading from file" begin
        id = "help"
        @test isa(start_reading(joinpath(SAMPLEDIR_CMD, "help.wav"); id=id), PyObject)
        @test active_reader_id() == id
        @test isa(reader(id), PyObject)
        stop_reading(id=id)
    end;
    @testset "4. start/stop reading from audio input cmd" begin
        id = "help"
        cmd = `julia -e 'using JustSayIt; JustSayIt.read_wav(joinpath("samples","commands","help.wav"))'`
        @test isa(start_reading(cmd; id=id), Base.Process)
        @test active_reader_id() == id
        @test isa(reader(id), Base.Process)
        stop_reading(id=id)
    end;
end;
