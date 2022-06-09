@doc """
    init_jsi(commands, modeldirs, noises)

!!! note "Advanced"
        init_jsi(commands, modeldirs, noises; <keyword arguments>)

Initialize the package JustSayIt.

# Arguments
- `default_language::String`: the default language, which is used for the command names, for the voice arguments and for typing when no other language is specified (noted with its IETF langauge tag https://en.wikipedia.org/wiki/IETF_language_tag). Currently supported are: english-US ("en-us"), German ("de"), French ("fr") and Spanish ("es").
- `type_languages::AbstractArray{String}`: the languages used for typing (noted with its IETF langauge tag https://en.wikipedia.org/wiki/IETF_language_tag). Currently supported are: english-US ("en-us"), German ("de"), French ("fr") and Spanish ("es"). Type `?Keyboard.type` for information about typing or say "help type" after having started JustSayIt.
- `commands::Dict{String, <:Any}`: the commands to be recognized with their mapping to a function or to a keyboard key or shortcut.
- `modeldirs::Dict{String, String}`: the directories where the unziped speech recognition models to be used are located. Models are downloadable from here: https://alphacephei.com/vosk/models
- `noises::Dict{String, <:AbstractArray{String}}`: for each model, an array of strings with noises (tokens that are to be ignored in the speech as, e.g., "huh").
!!! note "Advanced keyword arguments"
    - `vosk_log_level::Integer=-1`: the vosk log level (see in the Vosk documentation for details).

See also: [`finalize_jsi`](@ref)
"""
init_jsi

let
    global init_jsi, command, command_names, model, noises, noises_names, recognizer, controller, set_controller
    _commands::Dict{String, Union{Function, PyKey, NTuple{N,PyKey} where N}}                            = Dict{String, Union{Function, PyKey, NTuple{N,PyKey} where N}}()
    _models::Dict{String, PyObject}                                                                     = Dict{String, PyObject}()
    _noises::Dict{String, <:AbstractArray{String}}                                                      = Dict{String, Array{String}}()
    _recognizers::Dict{String, PyObject}                                                                = Dict{String, PyObject}()
    _controllers::Dict{String, PyObject}                                                                = Dict{String, PyObject}()
    command(name::AbstractString)                                                                       = _commands[name]
    command_names()                                                                                     = keys(_commands)
    model(name::AbstractString=MODELNAME.DEFAULT.EN_US)::PyObject                                            = _models[name]
    noises(modelname::AbstractString)                                                                   = _noises[modelname]  # NOTE: no return value declaration as would be <:AbstractArray{String} which is not possible.
    noises_names()                                                                                      = keys(_noises)
    recognizer(id::AbstractString)::PyObject                                                            = _recognizers[id]
    controller(name::AbstractString)::PyObject                                                          = if (name in keys(_controllers)) return _controllers[name] else @APIUsageError("The controller for $name is not available as it has not been set up in init_jsi.") end
    set_controller(name::AbstractString, c::PyObject)                                                   = (_controllers[name] = c; return)


    function init_jsi(default_language::String, type_languages::AbstractArray{String}, commands::Dict{String, <:Any}, modeldirs::Dict{String, String}, noises::Dict{String, <:AbstractArray{String}}; vosk_log_level::Integer=-1)
        Vosk.SetLogLevel(vosk_log_level)
        modelname_default = modelname(MODELTYPE_DEFAULT, default_language)

        # Validate and store the commands, adding the help command to it.
        if haskey(commands, COMMAND_NAME_SLEEP) @ArgumentError("the command name $COMMAND_NAME_SLEEP is reserved for putting JustSayIt to sleep. Please choose another command name for your command.") end
        if haskey(commands, COMMAND_NAME_AWAKE) @ArgumentError("the command name $COMMAND_NAME_AWAKE is reserved for awaking JustSayIt. Please choose another command name for your command.") end
        for cmd_name in keys(commands)
            if !(typeof(commands[cmd_name]) <: eltype(values(_commands))) @ArgumentError("the command belonging to commmand name $command_name is of an invalid. Valid are functions (e.g., Keyboard.type), keys (e.g., Key.ctrl or 'f') and tuples of keys (e.g., (Key.ctrl, 'c') )") end
        end
        _commands = commands

        # Verify that there is an entry for the default language and selected type languages in modeldirs and noises. Set the values for the other surely required models (i.e. which are used in the Commands submodule) to the same as the default if not available.
        if haskey(modeldirs, "") @ArgumentError("an empty string is not valid as model identifier.") end
        if !haskey(modeldirs, modelname_default) @ArgumentError("a model directory for the default language (\"$default_language\") is mandatory (entry \"$modelname_default\" is missing).") end
        if !haskey(noises,    modelname_default) @ArgumentError("a noises list for the default language (\"$default_language\") is mandatory (entry \"$modelname_default\" is missing).") end
        for lang in type_languages
            if !haskey(modeldirs, modelname(MODELTYPE_TYPE, lang)) @ArgumentError("a model directory for each selected type model is mandatory (entry \"$(modelname(MODELTYPE_TYPE,lang))\" for type language \"$lang\" is missing).") end
            if !haskey(noises,    modelname(MODELTYPE_TYPE, lang)) @ArgumentError("a noises list for each selected type model is mandatory (entry \"$(modelname(MODELTYPE_TYPE,lang))\" for type language \"$lang\" is missing).") end
        end
        _noises = noises

        # If the modeldir for the default language points to the default path, download a model if none is present (asumed present if the folder is present)
        modeldir = modeldirs[modelname_default]
        if modeldir == DEFAULT_MODELDIRS[modelname_default]
            if !isdir(modeldir)
                filename = basename(modeldir) * ".zip"
                @info "No model for the default language (\"$default_language\") found in its default location ($(modeldir)): downloading small model ($filename) from '$DEFAULT_MODEL_REPO' (~30-70 MB)..."
                modeldepot = joinpath(modeldir, "..")
                download_and_unzip(modeldepot, filename, DEFAULT_MODEL_REPO)
            end
        end
        # For each of the type languages, if the corresponding modeldir points to the default path, download a model if none is present (asumed present if the folder is present)
        for lang in type_languages
            modelname_lang = modelname(MODELTYPE_TYPE, lang)
            modeldir = modeldirs[modelname_lang]
            if modeldir == DEFAULT_MODELDIRS[modelname_lang]
                if !isdir(modeldir)
                    filename = basename(modeldir) * ".zip"
                    @info "No model for the type language (\"$lang\") found in its default location ($(modeldir)): download (optional) accurate large model ($filename) from '$DEFAULT_MODEL_REPO' (~1-2 GB)?"
                    answer = ""
                    while !(answer in ["yes", "no"]) println("Type \"yes\" or \"no\":")
                        answer = readline()
                    end
                    if answer == "yes"
                        modeldepot = joinpath(modeldir, "..")
                        download_and_unzip(modeldepot, filename, DEFAULT_MODEL_REPO)
                    else
                        if lang == default_language
                            @warn("Not downloading large accurate model for typing the default language (\"$lang\"): falling back to default model for typing.")
                            modeldirs[modelname_lang] = modeldirs[modelname_default]
                        else
                            @warn("Not downloading large accurate model for typing language \"$lang\": falling back to small model for typing.")
                            modeldirs[modelname_lang] = DEFAULT_MODELDIRS[modelname(MODELTYPE_DEFAULT, lang)]
                            modeldir = modeldirs[modelname_lang]
                            if !isdir(modeldir)
                                filename = basename(modeldir) * ".zip"
                                @info "No small model for language \"$lang\" found in its default location ($(modeldir)): downloading small model ($filename) from '$DEFAULT_MODEL_REPO' (~30-70 MB)..."
                                modeldepot = joinpath(modeldir, "..")
                                download_and_unzip(modeldepot, filename, DEFAULT_MODEL_REPO)
                            end
                        end
                    end
                end
            end
        end

        # Set up a default recognizer for each model as well as the command name recognizer.
        for modelname in keys(modeldirs)
            if !isdir(modeldirs[modelname])
                tilde_errmsg = ""
                if startswith(modeldirs[modelname], "~") tilde_errmsg = " Tildes ('~') in strings are not expanded for portability reasons (consider using 'homedir()')." end
                @ArgumentError("directory $(modeldirs[modelname]) does not exist.$tilde_errmsg")
            end
            _models[modelname] = Vosk.Model(modeldirs[modelname])
            _recognizers[modelname] = Vosk.KaldiRecognizer(model(modelname), SAMPLERATE)
            if modelname == modelname_default
                grammar = json([keys(commands)..., COMMAND_NAME_SLEEP, COMMAND_NAME_AWAKE, noises[modelname]..., UNKNOWN_TOKEN])
                _recognizers[COMMAND_RECOGNIZER_ID] = Vosk.KaldiRecognizer(model(modelname), SAMPLERATE, grammar)
            end
        end

        # Set up the special recognizers defined by voiceargs.
        for f_name in voicearg_f_names()
            for voicearg in keys(voiceargs(f_name))
                kwargs = voiceargs(f_name)[voicearg]
                if haskey(kwargs, :model) && !haskey(modeldirs, kwargs[:model]) @ArgumentError("no directory was given for the model $(kwargs[:model]) required for voicearg $voicearg in function $f_name.") end # NOTE: this error should only ever occur for user defined @voicearg functions; all funtions in submodule Commands must use
                if haskey(kwargs, :valid_input)
                    modelname = haskey(kwargs, :model) ? kwargs[:model] : modelname_default
                    grammar = json([kwargs[:valid_input]..., noises[modelname]..., UNKNOWN_TOKEN])
                    set_recognizer(f_name, voicearg, Vosk.KaldiRecognizer(model(modelname), SAMPLERATE, grammar))
                end
            end
            @debug "Voiceargs of function `$f_name`:" voiceargs(f_name)
        end

        # Call the garbage collector to avoid having it running right after starting to use JustSayIt.
        GC.gc()
    end

end

_noises(args...) = noises(args...)


function download_and_unzip(destination, filename, repository)
    progress = nothing
    previous = 0
    function show_progress(total::Integer, now::Integer)
        if (total > 0) && (now != previous)
            if isnothing(progress) progress = ProgressMeter.Progress(total; dt=0.1, desc="Download ($(Base.format_bytes(total))): ", color=:magenta, output=stderr) end
            ProgressMeter.update!(progress, now)
        end
        previous = now
    end
    mkpath(destination)
    filepath = joinpath(destination, filename)
    Downloads.download(repository * "/" * filename, filepath; progress=show_progress)
    @pywith Zipfile.ZipFile(filepath, "r") as archive begin
        archive.extractall(destination)
    end
end
