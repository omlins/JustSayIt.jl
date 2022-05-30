using Test
using JustSayIt
using PyCall
import JustSayIt: recorder, active_recorder_id, start_recording, stop_recording, pause_recording, restart_recording

# Test setup
const SAMPLEDIR_CMD = joinpath("samples", "commands")


@testset "$(basename(@__FILE__))" begin
    @testset "1. start/stop/pause/restart recording from audio input cmd" begin
        id = "help"
        cmd = `julia -e 'using JustSayIt; JustSayIt.read_wav(joinpath("samples","commands","help.wav"))'`
        @test isa(start_recording(;audio_input_cmd=cmd, id=id), Base.Process)
        @test active_recorder_id() == id
        @test isa(recorder(id), Base.Process)
        pause_recording()
        restart_recording()
        @test isa(recorder(id), Base.Process)
        stop_recording(id=id)
    end;
    @static if !Sys.iswindows()
        @testset "2. start/stop/pause/restart recording from mic" begin
            id = "mic"
            @test isa(start_recording(id=id), PyObject)
            @test active_recorder_id() == id
            @test isa(recorder(id), PyObject)
            pause_recording()
            restart_recording()
            @test isa(recorder(id), PyObject)
            stop_recording(id=id)
        end;
    end
end;
