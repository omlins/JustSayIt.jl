@doc """
    start_recording()

Start recording.

See also: [`stop_recording`](@ref)
"""
start_recording

@doc """
    stop_recording()

Stop recording.

See also: [`start_recording`](@ref)
"""
stop_recording

@doc """
    pause_recording()

Pause recording of active recorder.

See also: [`restart_recording`](@ref)
"""
pause_recording

@doc """
    restart_recording()

Restart recording of last active recorder.

See also: [`pause_recording`](@ref)
"""
restart_recording

let
    global recorder, start_recording, stop_recording, pause_recording, restart_recording
    _recorders::Dict{String, Base.Process}                 = Dict{String, Base.Process}()
    _active_recorder_id::String                            = ""
    recorder(id::String=DEFAULT_RECORDER_ID)::Base.Process = _recorders[id]
    active_recorder_id()::String                           = (if (_active_recorder_id=="") error("no recorder is active.") end; return _active_recorder_id)

    function start_recording(id::String=DEFAULT_RECORDER_ID)
        _recorders[id] = open(`$RECORDER_BACKEND $RECORDER_ARGS`) # NOTE: here could be started multiple recorders.
        _active_recorder_id = id
    end

    function stop_recording(id::String=DEFAULT_RECORDER_ID)
        close(_recorders[id])
    end

    pause_recording()   = (stop_recording(active_recorder_id()); return)
    restart_recording() = (start_recording(active_recorder_id()); return)
end
