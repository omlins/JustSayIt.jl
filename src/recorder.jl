@doc """
    start_recording()
    start_recording(<keyword arguments>)

Start recording.

# Arguments
!!! note "Keyword arguments"
    - `id`: an id to retrieve recorder as an alternative to reusing the returned recorder handle.
    - `audio_input_cmd::Cmd=nothing`: a command that returns an audio stream to replace the default audio recorder. The audio stream must fullfill the following properties: `samplerate=$SAMPLERATE`, `channels=$AUDIO_IO_CHANNELS` and `format=Int16` (signed 16-bit integer).

# Examples
```
# Use a custom command to create the audio input stream - instead of the default recorder (the rate, channels and format must not be chosen different!)
audio_input_cmd = `arecord --rate=$SAMPLERATE --channels=$AUDIO_IO_CHANNELS --format=S16_LE`
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

Pause recording of the active recorder.

See also: [`restart_recording`](@ref)
"""
pause_recording

@doc """
    restart_recording()

Restart recording of the last active recorder.

See also: [`pause_recording`](@ref)
"""
restart_recording

let
    global recorder, active_recorder_id, active_recorder_samplerate, start_recording, stop_recording, pause_recording, restart_recording, finalize_recorder
    _recorders::Dict{String, Union{Base.Process,PyObject}}                 = Dict{String, Union{Base.Process,PyObject}}()
    _active_recorder_id::String                                            = ""
    _active_recorder_cmd::Union{Cmd,Nothing}                               = nothing
    _active_recorder_samplerate::Int                                       = -1
    recorder(id::String=DEFAULT_RECORDER_ID)::Union{Base.Process,PyObject} = _recorders[id]
    active_recorder_id()::String                                           = (if (_active_recorder_id=="") @APIUsageError("no recorder is active.") end; return _active_recorder_id)
    active_recorder_samplerate()::Int                                      = (if (_active_recorder_samplerate==-1) @APIUsageError("no recorder is active.") end; return _active_recorder_samplerate)

    function start_recording(; id::String=DEFAULT_RECORDER_ID, audio_input_cmd::Union{Cmd,Nothing}=nothing, microphone_id::Int=-1, microphone_name::String="") # NOTE: here could be started multiple recorders.
        if !isnothing(audio_input_cmd)
            _recorders[id] = open(audio_input_cmd)
            _active_recorder_cmd = audio_input_cmd
            _active_recorder_samplerate = SAMPLERATE
        else # Default recorder
            if (microphone_id >= 0) && !isempty(microphone_name) @IncoherentArgumentError("both microphone_id and microphone_name are provided.") end
            microphone_id = (microphone_id >= 0) ? microphone_id : get_microphone_id(microphone_name)
            try
                if (microphone_id >= 0)
                    _recorders[id] = Sounddevice.RawInputStream(channels=AUDIO_IO_CHANNELS, dtype=AUDIO_ELTYPE_STR, blocksize=AUDIO_BLOCKSIZE, device=microphone_id)
                else
                    @info "Using default microphone (no microphone_name or microphone_id provided, or it is not valid)."
                    _recorders[id] = Sounddevice.RawInputStream(channels=AUDIO_IO_CHANNELS, dtype=AUDIO_ELTYPE_STR, blocksize=AUDIO_BLOCKSIZE)
                end
            catch e
                @ExternalError("Failed to open the audio input stream; check if the chosen microphone is blocked by another application.\n $e")
            end
            print_microphone(_recorders[id])
            _recorders[id].start()
            _active_recorder_cmd = nothing
            _active_recorder_samplerate =_recorders[id].samplerate
        end
        _active_recorder_id = id
        return _recorders[id]
    end

    function stop_recording(; id::String=DEFAULT_RECORDER_ID)
        close(_recorders[id])
    end

    function finalize_recorder()
        @info "Finalizing recorders..."
        for id in keys(_recorders)
            try
                stop_recording(id=id)
            catch e
                @warn "Failed to stop recorder $id: $e"
            end
        end
        return
    end

    pause_recording()   = (stop_recording(id=active_recorder_id()); return)
    restart_recording() = (start_recording(id=active_recorder_id(), audio_input_cmd=_active_recorder_cmd); return)

    function get_microphone_id(microphone_name::String)
        microphone_id = -1
        if isempty(microphone_name) return microphone_id end
        available_devices = Sounddevice.query_devices()
        for d in available_devices
            if startswith(strip(lowercase(d["name"])), strip(lowercase(microphone_name)))
                microphone_id = d["index"]
                break
            end
        end
        return microphone_id
    end

    function print_microphone(recorder::PyObject)
        microphone_id     = recorder.device[1]
        microphone_info   = Sounddevice.query_devices(microphone_id)
        available_devices = Sounddevice.query_devices()
        @info "Using microphone $microphone_id: $(microphone_info["name"])\n(available devices:\n$(join(["$(d["index"]): $(d["name"])" for d in available_devices],"\n"))\n)"
    end
    
end
