@doc """
    start_recording()

!!! note "Advanced"
        start_recording(<keyword arguments>)

Start recording.

# Arguments
!!! note "Advanced keyword arguments"
    - `audio_input_cmd::Cmd=nothing`: a command that returns an audio stream to replace the default audio recorder. The audio stream must fullfill the following properties: `samplerate=$SAMPLERATE`, `channels=$AUDIO_IN_CHANNELS` and `format=Int16` (signed 16-bit integer).

# Examples
```
# Use a custom command to create the audio input stream - instead of the default recorder (the rate, channels and format must not be chosen different!)
audio_input_cmd = `arecord --rate=$SAMPLERATE --channels=$AUDIO_IN_CHANNELS --format=S16_LE`
just_say_it(audio_input_cmd=audio_input_cmd)
```

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

import Base: readbytes!, close
let
    global recorder, start_recording, stop_recording, pause_recording, restart_recording, readbytes!, close
    _recorders::Dict{String, Union{Base.Process,PyObject}}                 = Dict{String, Union{Base.Process,PyObject}}()
    _active_recorder_id::String                                            = ""
    recorder(id::String=DEFAULT_RECORDER_ID)::Union{Base.Process,PyObject} = _recorders[id]
    active_recorder_id()::String                                           = (if (_active_recorder_id=="") error("no recorder is active.") end; return _active_recorder_id)

    function start_recording(id::String=DEFAULT_RECORDER_ID; audio_input_cmd::Union{Cmd,Nothing}=nothing) # NOTE: here could be started multiple recorders.
        if !isnothing(audio_input_cmd)
            _recorders[id] = open(audio_input_cmd)
        else # Default recorder
            _recorders[id] = Sounddevice.RawInputStream(samplerate=SAMPLERATE, channels=AUDIO_IN_CHANNELS, dtype=lowercase(string(AUDIO_ELTYPE)), blocksize=Int(AUDIO_READ_MAX/sizeof(AUDIO_ELTYPE)))
            _recorders[id].start()
        end
        _active_recorder_id = id
    end

    function stop_recording(id::String=DEFAULT_RECORDER_ID)
        close(_recorders[id])
    end

    function readbytes!(stream::PyObject, b::AbstractVector{UInt8}, nb=length(b))
        nb_frames = Int(nb/sizeof(AUDIO_ELTYPE))
        b .= stream.read(nb_frames)[1]
        return nb
    end

    close(stream::PyObject) = stream.close()

    pause_recording()   = (stop_recording(active_recorder_id()); return)
    restart_recording() = (start_recording(active_recorder_id()); return)
end
