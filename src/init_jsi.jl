"""
    init_jsi()
    init_jsi(<keyword arguments>)

Initialize the package JustSayIt.

# Keyword arguments
- `default_language::String="$(LANG.EN_US)"`: the default language, which is used for the voice arguments and for typing when no other language is specified (noted with its IETF language tag https://en.wikipedia.org/wiki/IETF_language_tag). Currently supported are: english-US ("en-us"), German ("de"), French ("fr") and Spanish ("es").
- `type_languages::String|AbstractArray{String}=default_language`: the languages used for typing, where the first is the default type language (noted with its IETF language tag https://en.wikipedia.org/wiki/IETF_language_tag). Currently supported are: english-US ("en-us"), German ("de"), French ("fr") and Spanish ("es"). Type `?Keyboard.type` for information about typing or say "help type" after having started JustSayIt.
- `use_llm::Bool=true`: whether to use a Large Language Model (LLM) for advanced features as the summary or translation of text (default is `true).
- `use_tts::Bool=true`: whether to use text-to-speech (TTS) functionality for voice enhancement of certain commands and for enabling the text-to-speech commands of the model TTS (default is `true`).
- `tts_async_default::Bool=true`: whether to use asynchronous TTS by default. The default (`true`) requires using of headphones, because in asynchronous mode, the TTS voice can naturally trigger commands by accident.
- `use_gpu::Bool=true`: whether to use GPU, enabling the use of better performing STT, TTS and LLM models (default is `true`).
- `microphone_id::Int`: the id of the microphone to be used, instead of the default microphone. JustSayIt prints available devices and their ids at the start of the application.
- `microphone_name::String`: the name of the microphone to be used, instead of the default microphone. JustSayIt prints available devices at the start of the application (names are sometimes better used instead of ids, because the latter can change dynamically in certain OS). The name is case-insensitive and must match the beginning of the printed device name (if there are multiple matches, the first is used).
- `audiooutput_id::Int`: the id of the audio output device to be used, instead of the default audio output device. JustSayIt prints available devices and their ids at the start of the application.
- `audiooutput_name::String`: the name of the audio output device to be used, instead of the default audio output device. JustSayIt prints available devices at the start of the application (names are sometimes better used instead of ids, because the latter can change dynamically in certain OS). The name is case-insensitive and must match the beginning of the printed device name (if there are multiple matches, the first is used).

!!! note "Advanced"
    - `modeldirs::Dict{String, String}`: the directories where the unziped speech recognition models to be used are located. If `modeldirs` is not set, then it is automatically defined according to the `default_language` and `type_languages` set. Models are downloadable from here: https://alphacephei.com/vosk/models
    - `noises::Dict{String, <:AbstractArray{String}}=DEFAULT_NOISES`: for each model, an array of strings with noises (tokens that are to be ignored in the speech as, e.g., "huh").
    - `audio_input_cmd::Cmd=nothing`: a command that returns an audio stream to replace the default audio recorder. The audio stream must fullfill the following properties: `samplerate=$SAMPLERATE`, `channels=$AUDIO_IO_CHANNELS` and `format=$AUDIO_ELTYPE` (signed 16-bit integer).


# Examples

#### Define custom `modeldirs`
```
using JustSayIt
modeldirs = Dict(MODELNAME.DEFAULT.EN_US => "$(homedir())/mymodels/vosk-model-small-en-us-0.15",
                 MODELNAME.TYPE.EN_US    => "$(homedir())/mymodels/vosk-model-en-us-daanzu-20200905",
                 MODELNAME.DEFAULT.FR    => "$(homedir())/mymodels/vosk-model-small-fr-0.22",
                 MODELNAME.TYPE.FR       => "$(homedir())/mymodels/vosk-model-fr-0.6-linto-2.2.0")
start(modeldirs=modeldirs, default_language="$(LANG.EN_US)", type_languages=["$(LANG.EN_US)","$(LANG.FR)"])
```

#### Define `audio_input_cmd`
```
# Use a custom command to create the audio input stream - instead of the default recorder (the rate, channels and format must not be chosen different!)
using JustSayIt
audio_input_cmd = `arecord --rate=$SAMPLERATE --channels=$AUDIO_IO_CHANNELS --format=S16_LE`
start(audio_input_cmd=audio_input_cmd)
```

# Default Vosk model directories
```
$(pretty_dict_string(DEFAULT_VOSK_MODELDIRS))
```

# Default `noises`
```
$(pretty_dict_string(DEFAULT_NOISES))
```
"""
function init_jsi(; default_language::String=LANG.EN_US, type_languages::Union{String,AbstractArray{String}}=default_language, use_llm::Bool=true, use_tts::Bool=true, tts_async_default::Bool=true, use_gpu::Bool=true, microphone_id::Int=-1, microphone_name::String="", audiooutput_id::Int=-1, audiooutput_name::String="", audio_input_cmd::Union{Cmd,Nothing}=nothing, modeldirs::Union{Nothing, Dict{String,String}}=nothing, noises::Dict{String,<:AbstractArray{String}}=DEFAULT_NOISES, record::Bool=true)
    if (default_language ∉ LANG) @KeywordArgumentError("invalid `default_language` (obtained \"$default_language\"). Valid are: \"$(join(LANG, "\", \"", "\" and \""))\".") end
    if isa(type_languages, String) type_languages = String[type_languages] end
    for l in type_languages
        if (l ∉ LANG) @KeywordArgumentError("invalid `type_language` (obtained \"$l\"). Valid are: \"$(join(LANG, "\", \"", "\" and \""))\".") end
    end
    stt_freespeech_engine = use_gpu ? STT_DEFAULT_FREESPEECH_ENGINE : STT_DEFAULT_FREESPEECH_ENGINE_CPU
    if isnothing(modeldirs)
        modelnames_type    = modelname.(MODELTYPE_SPEECH, type_languages)
        modelnames_default = [modelname(MODELTYPE_DEFAULT, default_language); modelname.(MODELTYPE_DEFAULT, type_languages)] #NOTE: a small ("default") model is also required for the type languages in order to deal with keywords etc (valid input restricted...).
        if stt_freespeech_engine=="faster-whisper"
            modelnames_type   = vcat(modelnames_type, [modelname(MODELTYPE_SPEECH)])
            modeldirs_type    = Dict(key => DEFAULT_WHISPER_MODELDIRS[key] for key in keys(DEFAULT_WHISPER_MODELDIRS) if key in modelnames_type)
            modeldirs_default = Dict(key => DEFAULT_VOSK_MODELDIRS[key] for key in keys(DEFAULT_VOSK_MODELDIRS) if key in modelnames_default)
            modeldirs = merge(modeldirs_type, modeldirs_default)
        elseif stt_freespeech_engine=="vosk"
            modelnames = vcat(modelnames_type, modelnames_default)
            modeldirs  = Dict(key => DEFAULT_VOSK_MODELDIRS[key] for key in keys(DEFAULT_VOSK_MODELDIRS) if key in modelnames)
        end
    end

    # Set global options.
    set_default_language(default_language)
    set_type_languages(type_languages)
    set_use_gpu(use_gpu)
    set_use_tts(use_tts)
    set_use_llm(use_llm)
    set_perf_debug()

    # Initialize components.
    @info "JustSayIt: I am getting ready..."
    if (use_tts) init_tts(audiooutput_id=audiooutput_id, audiooutput_name=audiooutput_name) end
    say("Hi there! I am getting ready...")
    if (use_llm) init_llm() end
    init_stt(modeldirs, noises; freespeech_engine=stt_freespeech_engine)
    set_initialized(true)

    # Start the recorder.
    set_tts_async_default(tts_async_default) # NOTE: the TTS async default must be set after initializatins, but before the recording is started (until this point, TTS can be asynchronous in any case without potentially triggering commands by accident)
    if record
        start_recording(; audio_input_cmd=audio_input_cmd, microphone_id=microphone_id, microphone_name=microphone_name)
        set_default_streamer(recorder)
    end
end
