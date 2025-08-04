function resample(audio::PyObject; input_samplerate::Int=default_streamer_samplerate(), output_samplerate::Int=SAMPLERATE)
    if input_samplerate == output_samplerate
        return audio
    else
        if isempty(audio) @APIUsageError("The audio stream is empty.") end
        np_audio = Numpy.frombuffer(audio, dtype=AUDIO_ELTYPE_NUMPY())
        resampled_audio = Scipy.signal.resample_poly(np_audio, output_samplerate, input_samplerate)
        int_audio = safe_int_audio(resampled_audio)
        byte_audio = reinterpret(UInt8, int_audio) |> collect
        if isempty(byte_audio) @APIUsageError("The resampled audio stream is empty.") end
        return PyCall.pybytes(byte_audio)
    end
end

resample(audio::AbstractVector{UInt8}; kwargs...) = PyCall.convert(Vector{UInt8}, resample(PyCall.pybytes(audio); kwargs...))

function concatenate_audio(audio1::PyObject, audio2::PyObject)
    audio1_data = Numpy.frombuffer(audio1, dtype=AUDIO_ELTYPE_NUMPY())
    audio2_data = Numpy.frombuffer(audio2, dtype=AUDIO_ELTYPE_NUMPY())
    concatenated_audio = Numpy.concatenate([audio1_data, audio2_data])
    byte_audio = reinterpret(UInt8, concatenated_audio) |> collect
    return PyCall.pybytes(byte_audio)
end

function add_silence(prepend::Bool, audio::PyObject, duration::AbstractFloat, samplerate::Int)
    num_samples = round(Int, duration * samplerate)
    silence = Numpy.zeros(num_samples, dtype=AUDIO_ELTYPE_NUMPY())

    # Generate low-energy random noise instead of pure zeros
    # noise_amplitude = 0.01  # Very low amplitude (1% of max)
    # random_noise = noise_amplitude * Numpy.random.randn(num_samples)
    # silence = safe_int_audio(random_noise, T=AUDIO_ELTYPE)

    # Read silence from a wav file and convert it to the right format
    # silence_wav_path = joinpath(dirname(dirname(@__DIR__)), "JustSayIt", "test", "samples", "silence", "silence_5001ms.wav")
    # silence_data = read_wav(silence_wav_path)
    # silence = Numpy.frombuffer(silence_data, dtype=AUDIO_ELTYPE_NUMPY())
    
    audio_data = Numpy.frombuffer(audio, dtype=AUDIO_ELTYPE_NUMPY())
    if (prepend) padded_audio = Numpy.concatenate([silence, audio_data])  # Prepend silence
    else         padded_audio = Numpy.concatenate([audio_data, silence])  # Append silence
    end
    byte_audio = reinterpret(UInt8, padded_audio) |> collect
    return PyCall.pybytes(byte_audio)
end

prepend_silence(audio::PyObject; duration::AbstractFloat=30.0, samplerate::Int=SAMPLERATE) = add_silence(true, audio, duration, samplerate)
append_silence(audio::PyObject; duration::AbstractFloat=5.0, samplerate::Int=SAMPLERATE)   = add_silence(false, audio, duration, samplerate)

prepend_silence(audio::AbstractVector{UInt8}; kwargs...) = PyCall.convert(Vector{UInt8}, prepend_silence(PyCall.pybytes(audio); kwargs...))
append_silence(audio::AbstractVector{UInt8}; kwargs...)  = PyCall.convert(Vector{UInt8}, append_silence(PyCall.pybytes(audio); kwargs...))

function safe_int_audio(x::AbstractVector{<:Real}; T::Type=AUDIO_ELTYPE)
    if (T === Int16) x_clipped = clamp.(x, -32768, 32767)
    else             @APIUsageError("Unsupported type T: $T")
    end
    return round.(T, x_clipped)
end

function AUDIO_ELTYPE_NUMPY()
    if   (AUDIO_ELTYPE === Int16) return Numpy.int16
    else                          @APIUsageError("Unsupported AUDIO_ELTYPE: $AUDIO_ELTYPE")
    end
end


## Functions for unit testing

function generate_audio_input(f::Function, text_with_silence::AbstractVector; muted::Bool=true, wavfile::String="", enginename::String=tts())
    pyaudio = generate_audio(text_with_silence; muted=muted, wavfile=wavfile, enginename=enginename)
    audio = PyCall.convert(Vector{UInt8}, pyaudio)
    start_reading(audio)
    set_default_streamer(reader; isreader=true)
    try
        result = f()
        return result
    finally
        stop_reading()
    end
end

function generate_audio(text_with_silence::AbstractVector; muted::Bool=true, wavfile::String="", enginename::String=tts())
    if isempty(text_with_silence) @APIUsageError("no text with silence provided.") end
    if wavfile == ""
        filepath, io = mktemp(ramdisk_tempdir())
        close(io) # Close it so RealtimeTTS can write to it
    else
        filepath = wavfile
    end
    audio = PyCall.pybytes(zeros(UInt8, 0))
    for x in text_with_silence
        if isa(x, AbstractString)
            dump_audio(x; muted=muted, wavfile=filepath, enginename=enginename)
            audio = concatenate_audio(audio, PyCall.pybytes(read_wav(filepath)))
        elseif isa(x, Real)
            x = Float64(x)
            if (x < 0.0) @IncoherentArgumentError("negative silence duration $x provided.") end
            audio = append_silence(audio; duration=x)
        else
            @ArgumentError("invalid type of text_with_silence element: $(typeof(x)). Expected AbstractString or Real.")
        end
    end
    if wavfile != "" # Write the audio in addition to the wavfile if specified (e.g. for debugging)
        writer = Wave.open(wavfile, "wb")
        writer.setnchannels(AUDIO_IO_CHANNELS)
        writer.setsampwidth(sizeof(AUDIO_ELTYPE))
        writer.setframerate(SAMPLERATE)
        writer.writeframes(audio)
        writer.close()
    else
        rm(filepath; force=true) # Remove the temporary file
    end
    return audio
end
