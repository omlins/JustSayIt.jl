let
    global tts, init_tts, finalize_tts, switch_tts, stream, create_tts_stream, is_tts_stream, feed_tts, play_tts, is_playing_tts, pause_tts, resume_tts, set_tts_async, tts_async_default, set_tts_async_default, stop_tts, say, dump
    _engines::Dict{String, PyObject}                         = Dict("system" => PyNULL(), "kokoro" => PyNULL())
    _streams::Dict{String, Dict{String, PyObject}}           = Dict()
    _async_default::Bool                                     = true
    _default_engine::String                                  = ""
    _audiooutput_id::Int64                                   = -1
    _progresser::Union{Task, Nothing}                        = nothing
    engine(enginename::String)::PyObject                     = _engines[enginename]
    stream(enginename::String, streamname::String)::PyObject = _streams[enginename][streamname]
    tts_async_default()::Bool                                = _async_default
    set_tts_async_default(async::Bool)                       = (_async_default = async)
    tts()::String                                            = _default_engine
    audiooutput()::Int64                                     = _audiooutput_id


    function init_tts(; audiooutput_id::Int=-1, audiooutput_name::String="")
        enginename = Preferences.@load_preference("TTS_ENGINE", use_gpu() ? TTS_DEFAULT_ENGINE : TTS_DEFAULT_ENGINE_CPU)
        if isempty(enginename) @APIUsageError("TTS engine name cannot be empty.") end
        select_audiooutput_id(audiooutput_id, audiooutput_name)
        map_supported_engines() # Construct the mapping of supported engines
        switch_tts(enginename; silent=true)
    end

    function finalize_tts()
        @info "Finalizing TTS..."
        for (enginename, engine) in _engines
            if (engine != PyNULL())
                for streamname in keys(_streams[enginename])
                    if is_tts_stream(enginename, streamname)
                        @debug "Stopping TTS stream $streamname of engine $enginename..."
                        stop_tts(enginename=enginename, streamname=streamname)
                    end
                end
            end
        end
    end                

    function select_audiooutput_id(audiooutput_id::Int, audiooutput_name::String)
        if (audiooutput_id >= 0) && !isempty(audiooutput_name) @IncoherentArgumentError("both audiooutput_id and audiooutput_name are provided.") end
        _audiooutput_id = (audiooutput_id >= 0) ? audiooutput_id : get_audiooutput_id(audiooutput_name)
        print_audiooutput(_audiooutput_id)
    end

    function get_audiooutput_id(audiooutput_name::String)
        audiooutput_id = -1
        if isempty(audiooutput_name) return audiooutput_id end
        available_audiooutputs = Sounddevice.query_devices()
        for d in available_audiooutputs
            if startswith(strip(lowercase(d["name"])), strip(lowercase(audiooutput_name)))
                audiooutput_id = d["index"]
                break
            end
        end
        return audiooutput_id
    end

    function print_audiooutput(audiooutput_id::Int)
        if (audiooutput_id >= 0)
            audiooutput_info = Sounddevice.query_devices(audiooutput_id)
            device_info_msg = "audio output device $audiooutput_id: $(audiooutput_info["name"])"
        else
            @info "Using default audio output device (no audiooutput_name or audiooutput_id provided, or it is not valid)."
            device_info_msg = "default audio output device"
        end
        available_audiooutputs = Sounddevice.query_devices()
        @info "Using $device_info_msg\n(available devices:\n$(join(["$(d["index"]): $(d["name"])" for d in available_audiooutputs],"\n"))\n)"
    end

    function map_supported_engines()
        TTS_SUPPORTED_LOCALENGINES["system"] = RealtimeTTS.SystemEngine
        TTS_SUPPORTED_LOCALENGINES["kokoro"] = RealtimeTTS.KokoroEngine
    end

    function switch_tts(enginename::String; silent::Bool=false)
        install_tts(enginename)                           # Install the engine if not already installed
        load_tts(enginename)                              # Load the engine if not already loaded
        create_tts_stream(enginename, TTS_DEFAULT_STREAM) # Create a default stream if not already created
        _default_engine = enginename
        test_sentence = "Text to speech engine $enginename is ready to use."
        nb_tokens = length(split(test_sentence))
        tic();  feed_tts(test_sentence);  t_stream = toc()
        tokens_per_second = nb_tokens / t_stream
        println("TTS engine $enginename accomplished a small test task in $(round(t_stream, digits=3)) seconds: $(round(tokens_per_second, digits=1)) tokens/s.")
        if (silent) stop_tts()
        else        play_tts()
        end
    end

    function install_tts(enginename::String)
        if !is_tts_installed(enginename)
            @info "To run a TTS engine locally, it must be installed with pip (the default TTS engine used is $TTS_DEFAULT_ENGINE). Install the engine $enginename now?"
            answer = ""
            while !(answer in ["yes", "no"]) println("Type \"yes\" or \"no\":")
                answer = readline()
            end
            if answer == "yes"
                try
                    Conda.pip("install", "RealtimeTTS[$(join([keys(_engines)..., enginename], ", "))]")
                catch   
                    @ArgumentError("Engine $enginename could not be installed. Please check the engine name and possibly try again.")
                end
                if !is_tts_installed(enginename) @ExternalError("Installing the engine $enginename failed.") end
                _engines[enginename] = PyNULL()
                map_supported_engines() # Re-map the supported engines to include the freshly installed engine
            else
                @ExternalError("Installation aborted. You can choose a different engine or set `use_tts=false`.")
            end
        end
        println("TTS engine $enginename is ready to use.")
    end

    function load_tts(enginename::String)
        if !is_tts_loaded(enginename)
            tic();
            if haskey(TTS_SUPPORTED_LOCALENGINES, enginename)
                _engines[enginename] = TTS_SUPPORTED_LOCALENGINES[enginename]()
            else
                @ArgumentError("Engine $enginename is not supported.")
            end
            t_load = toc()
            println("TTS engine $enginename was loaded in $(round(t_load, digits=3)) seconds.")
        end
    end

    function create_tts_stream(enginename::String, streamname::String; muted::Bool=false)
        if !haskey(_streams, enginename) _streams[enginename] = Dict() end
        if !haskey(_streams[enginename], streamname)
            if (audiooutput() >= 0)
                _streams[enginename][streamname] = RealtimeTTS.TextToAudioStream(engine(enginename), output_device_index=audiooutput(), muted=muted)
            else
                _streams[enginename][streamname] = RealtimeTTS.TextToAudioStream(engine(enginename), muted=muted)
            end
        end
    end

    is_tts_installed(enginename::String) = haskey(_engines, enginename)
    is_tts_loaded(enginename::String)    = (engine(enginename) != PyNULL())
    is_tts_stream(enginename::String, streamname::String) = (haskey(_streams, enginename) && haskey(_streams[enginename], streamname))

    function feed_tts(text::AbstractString; enginename::String=tts(), streamname::String=TTS_DEFAULT_STREAM, clean=true)
        if (clean) text = replace(text, "\\n" => "", "\\t" => "") end
        stream(enginename, streamname).feed(text)
    end

    function play_tts(; enginename::String=tts(), streamname::String=TTS_DEFAULT_STREAM, async::Bool=tts_async_default(), wavfile::String="", on_audio_chunk::Union{Function,Nothing}=nothing, playout_chunk_size::Int=-1, flush::Bool=false)
        if (!isempty(wavfile) && !isnothing(on_audio_chunk)) @IncoherentArgumentError("Both `wavfile` and `on_audio_chunk` are provided, but only one can be used at a time.") end
        if !is_playing_tts(enginename=enginename, streamname=streamname)
            _stream = stream(enginename, streamname)
            if !isempty(wavfile)
                async ? _stream.play_async(output_wavfile=wavfile) : _stream.play(output_wavfile=wavfile)
            elseif !isnothing(on_audio_chunk)
                async ? _stream.play_async(on_audio_chunk=on_audio_chunk) : _stream.play(on_audio_chunk=on_audio_chunk)
            else
                async ? _stream.play_async() : _stream.play()
            end
            if flush
                if (async) @APIUsageError("Flushing is not supported for asynchronous playback.")
                else       _stream.stop(); # NOTE: this flush implementation could be improved, but flushing should normally not be necessary.
                end
            end
            start_progresser(async; enginename=enginename, streamname=streamname)
        end
    end

    function say(text::AbstractString; enginename::String=tts(), streamname::String=TTS_DEFAULT_STREAM, async::Bool=tts_async_default(), flush::Bool=false)
        if use_tts()
            if !is_tts_stream(enginename, streamname) create_tts_stream(enginename, streamname) end
            feed_tts(text; enginename=enginename, streamname=streamname)
            play_tts(; enginename=enginename, streamname=streamname, async=async, flush=flush)
        end
        return nothing
    end

    function dump(text::AbstractString; muted::Bool=true, wavfile::String="", playout_chunk_size::Int=-1, enginename::String=tts(), streamname::String=(muted ? TTS_FILE_STREAM : TTS_FILE_PLAY_STREAM), async::Bool=tts_async_default())
        if use_tts()
            to_stdout = isempty(wavfile)
            if !is_tts_stream(enginename, streamname) create_tts_stream(enginename, streamname, muted=muted) end
            feed_tts(text; enginename=enginename, streamname=streamname)
            if to_stdout
                play_tts(enginename=enginename, streamname=streamname, async=async, on_audio_chunk=write_to_stdout, playout_chunk_size=playout_chunk_size)
            else
                play_tts(enginename=enginename, streamname=streamname, async=async, wavfile=wavfile)
            end
        end
        return nothing
    end
    
    function write_to_stdout(audiochunk::PyObject) # RealtimeTTS automatically converts audiochunk to Int16; to match the requirements of `audio_input_cmd`, which is AUDIO_ELTYPE, it must be ensured that these are the same. Furthermore, in RealtimeTTS, the chunks passed to the on_audio_chunk callback are byte buffers representing interleaved audio. This is evident from the _on_audio_chunk method.
        if (audiochunk == PyNULL) @warn "Audio chunk is empty, nothing to write." return end
        format, channels, samplerate = engine(tts()).get_stream_info()
        if (format ∉ [AUDIO_ELTYPE, Float32]) @APIUsageError("Writing to stdout is not supported for this TTS engine: $format not supported.") end
        audiochunk = resample(audiochunk; input_samplerate=samplerate, output_samplerate=SAMPLERATE)
        chunk = PyCall.convert(Vector{UInt8}, audiochunk)
        if channels == 1
            chunk_mono = chunk
        elseif channels == 2
            chunk_i16 = reinterpret(Int16, chunk)
            if length(chunk_i16) % 2 != 0 # Ensure reshape works correctly for interleaved [L0 R0 L1 R1 ...] format, even when the stream is truncated.
                @warn "Stereo audio chunk has odd number of samples, ignoring last sample."
                chunk_i16 = @view chunk_i16[1:end-1]
            end
            chunk_stereo_i16 = reshape(chunk_i16, channels, :)
            chunk_mono_i16 = @view chunk_stereo_i16[1, :]  # left channel
            chunk_mono = reinterpret(UInt8, chunk_mono_i16)
        else
            @APIUsageError("Writing to stdout is not supported for this TTS engine: $channels channels not supported.")            
        end
        Base.write(stdout, chunk_mono)
        flush(stdout)
        return nothing
    end

    function progress_tts_stream(; enginename::String=tts(), streamname::String=TTS_DEFAULT_STREAM)
        while is_playing_tts(enginename=enginename, streamname=streamname)
            Time.sleep(0.001)
            yield()
        end
    end

    function start_progresser(async::Bool; enginename::String=tts(), streamname::String=TTS_DEFAULT_STREAM)
        if async
            if isnothing(_progresser) || !istaskstarted(_progresser) || istaskdone(_progresser)
                _progresser = Threads.@spawn progress_tts_stream(enginename=enginename, streamname=streamname) #NOTE: currently only a single progresser is required.
                @debug "Progresser started for TTS engine $enginename and stream $streamname: $(_progresser)."
            end
        else
            progress_tts_stream(enginename=enginename, streamname=streamname)
        end
    end

    function stop_progresser(enginename::String=tts(), streamname::String=TTS_DEFAULT_STREAM)
        if !isnothing(_progresser) && istaskstarted(_progresser) && !istaskdone(_progresser)
            schedule(_progresser, InterruptException())
            @debug "Stopping progresser for TTS engine $enginename and stream $streamname: $(_progresser)."
            wait(_progresser)
        end
        _progresser = nothing
    end
end
