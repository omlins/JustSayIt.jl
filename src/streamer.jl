import Base: readbytes!, close
let
    global default_streamer, set_default_streamer, default_streamer_samplerate, finalize_streamer, close, readbytes!
    _default_streamer::Tuple{Function, String}                           = (()->nothing, "")
    _default_streamer_samplerate::Int                                    = -1
    default_streamer()::Union{Base.Process,PyObject,IOBuffer}            = _default_streamer[1](_default_streamer[2])
    set_default_streamer(streamer::Function; isreader::Bool=false, 
        id::String=(isreader ? DEFAULT_READER_ID : DEFAULT_RECORDER_ID)) = (_default_streamer = (streamer, id); _default_streamer_samplerate = (isreader) ? active_reader_samplerate() : active_recorder_samplerate(); return)
    default_streamer_samplerate()::Int                                   = (if (_default_streamer_samplerate==-1) @APIUsageError("no default streamer set.") end; return _default_streamer_samplerate)

    function readbytes!(stream::PyObject, b::AbstractVector{UInt8}, nb=length(b))
        nb_frames = nb ÷ sizeof(AUDIO_ELTYPE)
        if stream.__class__ == Wave.Wave_read
            tmp = Vector{UInt8}(stream.readframes(nb_frames))
            b[1:length(tmp)] .= tmp
            return length(tmp)
        elseif stream.__class__ == Sounddevice.RawInputStream
            b .= stream.read(nb_frames)[1]
            return nb
        else
            @APIUsageError("PyObject of unknown class.")
        end
    end

    close(stream::PyObject) = stream.close()

    function finalize_streamer() 
        @info "Finalizing streamer..."
        close(default_streamer())
        return
    end
end
