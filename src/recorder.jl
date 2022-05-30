@doc """
    start_recording()
    start_recording(<keyword arguments>)

Start recording.

# Arguments
!!! note "Keyword arguments"
    - `id`: an id to retrieve recorder as an alternative to reusing the returned recorder handle.
    - `audio_input_cmd::Cmd=nothing`: a command that returns an audio stream to replace the default audio recorder. The audio stream must fullfill the following properties: `samplerate=$SAMPLERATE`, `channels=$AUDIO_IN_CHANNELS` and `format=Int16` (signed 16-bit integer).

# Examples
```
# Use a custom command to create the audio input stream - instead of the default recorder (the rate, channels and format must not be chosen different!)
audio_input_cmd = `arecord --rate=$SAMPLERATE --channels=$AUDIO_IN_CHANNELS --format=S16_LE`
start_recording(audio_input_cmd=audio_input_cmd)
```

See also: [`stop_recording`](@ref)
"""
start_recording

@doc """
    stop_recording()
    stop_recording(<keyword arguments>)

Stop recording.

# Arguments
!!! note "Keyword arguments"
    - `id`: an id to retrieve recorder as an alternative to reusing the returned recorder handle.

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
    global recorder, active_recorder_id, start_recording, stop_recording, pause_recording, restart_recording
    _recorders::Dict{String, Union{Base.Process,PyObject}}                 = Dict{String, Union{Base.Process,PyObject}}()
    _active_recorder_id::String                                            = ""
    _active_recorder_cmd::Union{Cmd,Nothing}                               = nothing
    recorder(id::String=DEFAULT_RECORDER_ID)::Union{Base.Process,PyObject} = _recorders[id]
    active_recorder_id()::String                                           = (if (_active_recorder_id=="") error("no recorder is active.") end; return _active_recorder_id)

    function start_recording(; id::String=DEFAULT_RECORDER_ID, audio_input_cmd::Union{Cmd,Nothing}=nothing) # NOTE: here could be started multiple recorders.
        if !isnothing(audio_input_cmd)
            _recorders[id] = open(audio_input_cmd)
            _active_recorder_cmd = audio_input_cmd
        else # Default recorder
            _recorders[id] = Sounddevice.RawInputStream(samplerate=SAMPLERATE, channels=AUDIO_IN_CHANNELS, dtype=lowercase(string(AUDIO_ELTYPE)), blocksize=Int(AUDIO_READ_MAX/sizeof(AUDIO_ELTYPE)))
            _recorders[id].start()
            _active_recorder_cmd = nothing
        end
        _active_recorder_id = id
        return _recorders[id]
    end

    function stop_recording(; id::String=DEFAULT_RECORDER_ID)
        close(_recorders[id])
    end

    pause_recording()   = (stop_recording(id=active_recorder_id()); return)
    restart_recording() = (start_recording(id=active_recorder_id(), audio_input_cmd=_active_recorder_cmd); return)
end
