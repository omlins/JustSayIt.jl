let
    global reader, active_reader_id, active_reader_samplerate, start_reading, stop_reading, read_wav, finalize_reader
    _readers::Dict{String, Union{Base.Process,PyObject,IOBuffer}}               = Dict{String, Union{Base.Process,PyObject,IOBuffer}}()
    _active_reader_id::String                                                   = ""
    _active_reader_samplerate::Int                                              = -1
    reader(id::String=DEFAULT_READER_ID)::Union{Base.Process,PyObject,IOBuffer} = _readers[id]
    active_reader_id()::String                                                  = (if (_active_reader_id=="") @APIUsageError("no reader is active.") end; return _active_reader_id)
    active_reader_samplerate()::Int                                             = (if (_active_reader_samplerate==-1) @APIUsageError("no reader is active.") end; return _active_reader_samplerate)

    function start_reading(filename::String; id::String=DEFAULT_READER_ID, async::Bool=false, pre_silence::AbstractFloat=0.0, post_silence::AbstractFloat=0.0) # NOTE: here could be started multiple readers.
        if async
            if (pre_silence > 0.0) || (post_silence > 0.0) @IncoherentArgumentError("the keyword arguments pre_silence and post_silence are not supported for async reading.") end
            wait_nonempty(filename)
            wav_reader = Wave.open(filename, "rb")
            check_wav(wav_reader)
            _readers[id] = wav_reader
            _active_reader_id = id
            _active_reader_samplerate = wav_reader.getframerate()
            return _readers[id]
        else
            audio = read_wav(filename)
            if (pre_silence > 0.0)  audio = prepend_silence(audio; duration=pre_silence) end
            if (post_silence > 0.0) audio = append_silence(audio; duration=post_silence) end
            start_reading(audio; id=id)
        end
    end

    function start_reading(audio::AbstractVector{UInt8}; id::String=DEFAULT_READER_ID) # NOTE: here could be started multiple readers.
        _readers[id] = IOBuffer(audio)
        _active_reader_id = id
        _active_reader_samplerate = SAMPLERATE
        return _readers[id]
    end

    function start_reading(audio_input_cmd::Cmd; id::String=DEFAULT_READER_ID) # NOTE: here could be started multiple readers.
        _readers[id] = open(audio_input_cmd)
        _active_reader_id = id
        _active_reader_samplerate = SAMPLERATE
        return _readers[id]
    end

    function stop_reading(; id::String=DEFAULT_READER_ID)
        close(_readers[id])
    end

    function finalize_reader()
        @info "Finalizing readers..."
        for id in keys(_readers)
            try
                stop_reading(id=id)
            catch e
                @warn "Failed to stop reader $id: $e"
            end
        end
        return
    end

    function check_wav(reader::PyObject)
        channels = reader.getnchannels()
        sampwidth = reader.getsampwidth()
        comptype = reader.getcomptype()
        if channels != 1 || sampwidth != 2 || comptype != "NONE"
            @FileError("the audio file must be WAV format mono PCM (obtained: $channels channels, $sampwidth bytes per sample, compression type: $comptype)")
        end
    end

    function read_wav(filepath::String)
        wav_reader = start_reading(filepath; async=true)
        check_wav(wav_reader)
        samplerate = wav_reader.getframerate()
        audio = zeros(UInt8, wav_reader.getnframes()*sizeof(AUDIO_ELTYPE))
        bytes_read = readbytes!(wav_reader, audio)
        audio = resample(audio; input_samplerate=samplerate, output_samplerate=SAMPLERATE)
        close(wav_reader)
        if (bytes_read == 0) @FileError("file $filepath could not be read.") end
        return audio
    end

    function wait_nonempty(filepath; timeout=2.0, sleeptime=0.05)
        start_time = time()
        last_size = 0
        while time() - start_time < timeout
            sleep(sleeptime)
            if isfile(filepath)
                size = filesize(filepath)
                if size > 0
                    if size == last_size
                        return
                    else
                        last_size = size
                    end
                end
            end
        end
        @FileError("file $filepath is empty or not stable after $timeout seconds.")
    end

end
