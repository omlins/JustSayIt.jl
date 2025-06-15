@doc """
    init_stt(modeldirs, noises)

!!! note "Advanced"
        init_stt(modeldirs, noises; <keyword arguments>)

Initialize the speech-to-text (STT) functionality of JustSayIt.

# Arguments
- `modeldirs::Dict{String, String}`: the directories where the unziped speech recognition models to be used are located. Models are downloadable from here: https://alphacephei.com/vosk/models
- `noises::Dict{String, <:AbstractArray{String}}`: for each model, an array of strings with noises (tokens that are to be ignored in the speech as, e.g., "huh").

# Keyword arguments
- `default_language::String="$(LANG.EN_US)"`: the default language, which is used for the command names, for the voice arguments and for typing when no other language is specified (noted with its IETF langauge tag https://en.wikipedia.org/wiki/IETF_language_tag). Currently supported are: english-US ("en-us"), German ("de"), French ("fr") and Spanish ("es").
- `type_languages::String|AbstractArray{String}=["$(LANG.EN_US)"]`: the languages used for typing, where the first is the default type language (noted with its IETF langauge tag https://en.wikipedia.org/wiki/IETF_language_tag). Currently supported are: english-US ("en-us"), German ("de"), French ("fr") and Spanish ("es"). Type `?Keyboard.type` for information about typing or say "help type" after having started JustSayIt.
!!! note "Advanced"
    - `vosk_log_level::Integer=-1`: the vosk log level (see in the Vosk documentation for details).

See also: [`finalize_tts`](@ref)
"""
init_stt
let
    global init_stt, finalize_stt, modelname_default, model, noises, noises_names, recognizer, set_recognizer, has_recognizer, set_recognizer_persistent, use_static_recognizers
    _modelname_default::String                                                                          = ""
    _models::Dict{String, PyObject}                                                                     = Dict{String, PyObject}()
    _noises::Dict{String, <:AbstractArray{String}}                                                      = Dict{String, Array{String}}()
    _recognizers::Dict{String, Recognizer}                                                              = Dict{String, Recognizer}()
    _use_static_recognizers                                                                             = true
    modelname_default()                                                                                 = _modelname_default
    model(name::AbstractString=modelname_default())::PyObject                                           = _models[name]
    noises(modelname::AbstractString=modelname_default())                                               = _noises[modelname]  # NOTE: no return value declaration as would be <:AbstractArray{String} which is not possible.
    noises_names()                                                                                      = keys(_noises)
    recognizer(id::AbstractString)::Recognizer                                                          = _recognizers[id]
    set_recognizer(id::AbstractString, r::Recognizer)                                                   = (_recognizers[id] = r; return)
    has_recognizer(id::AbstractString)::Bool                                                            = haskey(_recognizers, id)
    set_recognizer_persistent(id::AbstractString, persistent::Bool)                                     = if has_recognizer(id) _recognizers[id].is_persistent = persistent; else @ArgumentError("No recognizer with id $id found to set persistent flag to $persistent.") end
    use_static_recognizers()::Bool                                                                      = _use_static_recognizers
    set_static_recognizers_usage()                                                                      = if haskey(ENV,"JSI_USE_STATIC_RECOGNIZERS") _use_static_recognizers = (parse(Int64,ENV["JSI_USE_STATIC_RECOGNIZERS"]) > 0); end


    function init_stt(modeldirs::Dict{String, String}, noises::Dict{String, <:AbstractArray{String}}; freespeech_engine::String=STT_DEFAULT_FREESPEECH_ENGINE, vosk_log_level::Integer=-1)
        # Set global options.
        Vosk.SetLogLevel(vosk_log_level)
        set_static_recognizers_usage()

        # Set the default model
        _modelname_default = modelname(MODELTYPE_DEFAULT, default_language())

        # Verify that there is an entry for the default language and selected type languages in modeldirs and noises. Set the values for the other surely required models (i.e. which are used in the Commands submodule) to the same as the default if not available.
        if haskey(modeldirs, "") @ArgumentError("an empty string is not valid as model identifier.") end
        if !haskey(modeldirs, _modelname_default) @ArgumentError("a model directory for the default language ($(lang_str(default_language()))) is mandatory (entry \"$_modelname_default\" is missing).") end
        if !haskey(noises,    _modelname_default) @ArgumentError("a noises list for the default language ($(lang_str(default_language()))) is mandatory (entry \"$_modelname_default\" is missing).") end
        for lang in type_languages()
            if !haskey(modeldirs, modelname(MODELTYPE_SPEECH, lang)) && (freespeech_engine == "vosk") @ArgumentError("a model directory for each selected type model is mandatory (entry \"$(modelname(MODELTYPE_SPEECH,lang))\" for type language $(lang_str(lang)) is missing).") end
            if !haskey(noises,    modelname(MODELTYPE_SPEECH, lang)) @ArgumentError("a noises list for each selected type model is mandatory (entry \"$(modelname(MODELTYPE_SPEECH,lang))\" for type language $(lang_str(lang)) is missing).") end
        end
        _noises = noises

        # If the modeldir for the default language points to the default path, download a model if none is present (asumed present if the folder is present)
        modeldir = modeldirs[_modelname_default]
        if modeldir == DEFAULT_VOSK_MODELDIRS[_modelname_default]
            if !isdir(modeldir)
                filename = basename(modeldir) * ".zip"
                @voiceinfo "No model for the default language ($(lang_str(default_language()))) found in its default location ($(modeldir)): downloading small model ($filename) from '$DEFAULT_VOSK_MODEL_REPO' (~30-70 MB)..."
                modeldepot = joinpath(modeldir, "..")
                download_and_unzip(modeldepot, filename, DEFAULT_VOSK_MODEL_REPO)
            end
        end

        # For each of the type languages, if the corresponding modeldir points to the default path, download a large and small model (for keyword handling etc.) if none is present (asumed present if the folder is present)
        if freespeech_engine == "vosk"
            for lang in type_languages()
                modelname_lang = modelname(MODELTYPE_SPEECH, lang)
                modeldir = modeldirs[modelname_lang]
                if modeldir == DEFAULT_VOSK_MODELDIRS[modelname_lang]
                    if !isdir(modeldir)
                        if modeldir == ""
                            @warn("No large accurate model for typing in $(lang_str(lang)) available: falling back to small model for typing.")
                            modeldirs[modelname_lang] = DEFAULT_VOSK_MODELDIRS[modelname(MODELTYPE_DEFAULT, lang)]
                            modeldir = modeldirs[modelname_lang]
                            if !isdir(modeldir)
                                filename = basename(modeldir) * ".zip"
                                @voiceinfo "No small model for $(lang_str(lang)) found in its default location ($(modeldir)): downloading small model ($filename) from '$DEFAULT_VOSK_MODEL_REPO' (~30-70 MB)..."
                                modeldepot = joinpath(modeldir, "..")
                                download_and_unzip(modeldepot, filename, DEFAULT_VOSK_MODEL_REPO)
                            end
                        else
                            filename = basename(modeldir) * ".zip"
                            @voiceinfo "No accurate large model for the type language ($(lang_str(lang))) found in its default location ($(modeldir)): download (optional) accurate large model ($filename) from '$DEFAULT_VOSK_MODEL_REPO' (~1-2 GB)?"
                            answer = ""
                            while !(answer in ["yes", "no"]) println("Type \"yes\" or \"no\":")
                                answer = readline()
                            end
                            if answer == "yes"
                                modeldepot = joinpath(modeldir, "..")
                                download_and_unzip(modeldepot, filename, DEFAULT_VOSK_MODEL_REPO)
                                # Download also the small module for handling of type keywords etc.
                                modelname_lang = modelname(MODELTYPE_DEFAULT, lang)
                                modeldir = modeldirs[modelname_lang]
                                if modeldir == DEFAULT_VOSK_MODELDIRS[modelname_lang]
                                    if !isdir(modeldir)
                                        filename = basename(modeldir) * ".zip"
                                        @voiceinfo "No small dynamic model for the type language ($(lang_str(lang))) found in its default location ($(modeldir)): downloading small model ($filename) from '$DEFAULT_VOSK_MODEL_REPO' (~30-70 MB)..."
                                        modeldepot = joinpath(modeldir, "..")
                                        download_and_unzip(modeldepot, filename, DEFAULT_VOSK_MODEL_REPO)
                                    end
                                end
                            else
                                if lang == default_language()
                                    @warn("Not downloading large accurate model for typing the default language ($(lang_str(lang))): falling back to default model for typing.")
                                    modeldirs[modelname_lang] = modeldirs[_modelname_default]
                                else
                                    @warn("Not downloading large accurate model for typing in $(lang_str(lang)): falling back to small model for typing.")
                                    modeldirs[modelname_lang] = DEFAULT_VOSK_MODELDIRS[modelname(MODELTYPE_DEFAULT, lang)]
                                    modeldir = modeldirs[modelname_lang]
                                    if !isdir(modeldir)
                                        filename = basename(modeldir) * ".zip"
                                        @voiceinfo "No small model for $(lang_str(lang)) found in its default location ($(modeldir)): downloading small model ($filename) from '$DEFAULT_VOSK_MODEL_REPO' (~30-70 MB)..."
                                        modeldepot = joinpath(modeldir, "..")
                                        download_and_unzip(modeldepot, filename, DEFAULT_VOSK_MODEL_REPO)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end

        # If no type model was set for the default language make it point to the default model.
        if freespeech_engine == "vosk"
            modelname_type = modelname(MODELTYPE_SPEECH, default_language())
            if !haskey(modeldirs, modelname_type)
                @warn("The default language ($(lang_str(default_language()))) was not selected as typing language. The small language model will therefore be used should any command require typing in the default language.")
                modeldirs[modelname_type] = DEFAULT_VOSK_MODELDIRS[modelname(MODELTYPE_DEFAULT, default_language())]
            end
        end

        # Set up a default recognizer for each model as well as the command name recognizer.
        for modelname in keys(modeldirs)
            if (freespeech_engine == "vosk") && !isdir(modeldirs[modelname])
                tilde_errmsg = ""
                if startswith(modeldirs[modelname], "~") tilde_errmsg = " Tildes ('~') in strings are not expanded for portability reasons (consider using 'homedir()')." end
                @ArgumentError("directory $(modeldirs[modelname]) does not exist.$tilde_errmsg")
            end
            backend = infer_backend(modeldirs[modelname])
            _models[modelname] = create_model(backend, modeldirs[modelname])
            _recognizers[modelname] = create_recognizer(backend, modelname)
        end

        # Set up the special recognizers defined by voiceargs.
        for f_name in voicearg_f_names()
            for voicearg in keys(voiceargs(f_name))
                kwargs    = voiceargs(f_name)[voicearg]
                lang      = haskey(kwargs, :model) ? join(split(kwargs[:model], "-")[2:end], "-") : default_language()
                modelname = haskey(kwargs, :model) ? kwargs[:model] : _modelname_default
                if (modeltype(modelname) == MODELTYPE_DEFAULT && lang in [default_language(); type_languages()]) || (modeltype(modelname) == MODELTYPE_SPEECH && lang in type_languages()) # Recognizers are only setup for models that are needed, i.e., models for languages that were selected with the arguments default_language or type_languages.
                    if !haskey(modeldirs, modelname) @ArgumentError("no directory was given for the model $(kwargs[:model]) required for voicearg $voicearg in function $f_name.") end # NOTE: this error should only ever occur for user defined @voicearg functions; all funtions in submodule Commands must use
                    if haskey(kwargs, :valid_input)
                        valid_input = isa(kwargs[:valid_input],AbstractArray{String}) ? kwargs[:valid_input] : kwargs[:valid_input][default_language()]
                        grammar     = json([valid_input..., noises[modelname]..., UNKNOWN_TOKEN])
                        set_recognizer(f_name, voicearg, Recognizer(Vosk.KaldiRecognizer(model(modelname), SAMPLERATE, grammar), true))
                    end
                end
            end
            @debug "Voiceargs of function `$f_name`:" voiceargs(f_name)
        end

        # Call the garbage collector to avoid having it running right after starting to use JustSayIt.
        GC.gc()
    end

    function finalize_stt()
        @info "Finalizing STT..."
        for r in values(_recognizers)
            finalize(r)
        end
    end

    function finalize(recognizer::Recognizer)
        backend = recognizer.backend
        transcriber = recognizer.transcriber
        if backend == :RealtimeSTT
            if transcriber != PyNULL() && transcriber.is_running()
                transcriber.stop()
            end
        end
    end

    function create_model(backend::Symbol, modeldir::String)::PyObject
        if     (backend==:Vosk)         return Vosk.Model(modeldir)
        elseif (backend==:RealtimeSTT)  return PyNULL()  # NOTE: RealtimeSTT backend does currently not require a model
        end
    end

    function create_recognizer(backend::Symbol, modelname::String)::Recognizer
        if backend==:Vosk 
            return Recognizer(backend, Vosk.KaldiRecognizer(model(modelname), SAMPLERATE))
        elseif backend==:RealtimeSTT
            lang = modellang(modelname)
            lang = (lang == LANG_AUTO) ? "" : lang
            r = RealtimeSTT.AudioToTextRecorder(post_speech_silence_duration=2.0, min_length_of_recording=0.0, min_gap_between_recordings=0.0, use_main_model_for_realtime=true, model="tiny", language=lang, allowed_latency_limit=10000, use_microphone=false, spinner=false)
            return Recognizer(backend, r, Transcriber(r))
        end
    end

    function infer_backend(modeldir::String)::Symbol
        if     startswith(modeldir, VOSK_MODELDIR_PREFIX) return :Vosk
        elseif startswith(modeldir, RSTT_MODELDIR_PREFIX) return :RealtimeSTT
        else   @ArgumentError("The backend for the model directory $modeldir could not be inferred.")
        end
    end

end
