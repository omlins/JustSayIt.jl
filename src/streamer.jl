import Base: readbytes!, close
let
    global default_streamer, set_default_streamer, readbytes!, close
    _default_streamer::Tuple{Function, String}                = (recorder, DEFAULT_RECORDER_ID)
    default_streamer()::Union{Base.Process,PyObject,IOBuffer} = _default_streamer[1](_default_streamer[2])
    set_default_streamer(streamerkind::Function, id::String)  = (_default_streamer = (streamerkind, id); return)

    function readbytes!(stream::PyObject, b::AbstractVector{UInt8}, nb=length(b))
        nb_frames = Int(nb/sizeof(AUDIO_ELTYPE))
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
end
