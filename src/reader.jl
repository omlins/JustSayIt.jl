let
    global reader, active_reader_id, start_reading, stop_reading, read_wav
    _readers::Dict{String, Union{Base.Process,PyObject,IOBuffer}}               = Dict{String, Union{Base.Process,PyObject,IOBuffer}}()
    _active_reader_id::String                                                   = ""
    reader(id::String=DEFAULT_READER_ID)::Union{Base.Process,PyObject,IOBuffer} = _readers[id]
    active_reader_id()::String                                                  = (if (_active_reader_id=="") @APIUsageError("no reader is active.") end; return _active_reader_id)

    function start_reading(filename::String; id::String=DEFAULT_READER_ID) # NOTE: here could be started multiple readers.
        _readers[id] = Wave.open(filename, "rb")
        check_wav(_readers[id])
        _active_reader_id = id
        return _readers[id]
    end

    function start_reading(audio::AbstractVector{UInt8}; id::String=DEFAULT_READER_ID) # NOTE: here could be started multiple readers.
        _readers[id] = IOBuffer(audio)
        _active_reader_id = id
        return _readers[id]
    end

    function start_reading(audio_input_cmd::Cmd; id::String=DEFAULT_READER_ID) # NOTE: here could be started multiple readers.
        _readers[id] = open(audio_input_cmd)
        _active_reader_id = id
        return _readers[id]
    end

    function stop_reading(; id::String=DEFAULT_READER_ID)
        close(_readers[id])
    end

    function check_wav(reader::PyObject)
        if reader.getnchannels() != 1 || reader.getsampwidth() != 2 || reader.getcomptype() != "NONE" || reader.getframerate() != SAMPLERATE
            @FileError("the audio file must be WAV format mono PCM @ $SAMPLERATE Hz.")
        end
    end

    function read_wav(filepath::String)
        wav_reader = start_reading(filepath)
        audio = zeros(UInt8, wav_reader.getnframes()*sizeof(AUDIO_ELTYPE))
        bytes_read = readbytes!(wav_reader, audio)
        close(wav_reader)
        if (bytes_read == 0) @FileError("file $filepath could not be read.") end
        return audio
    end
end
