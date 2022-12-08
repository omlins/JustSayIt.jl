@doc """
    init_jsi(commands, modeldirs, noises)

!!! note "Advanced"
        init_jsi(commands, modeldirs, noises; <keyword arguments>)

Initialize the package JustSayIt.

# Arguments
- `commands::Dict{String, <:Any}`: the commands to be recognized with their mapping to a function or to a keyboard key or shortcut or a sequence of any of those.
- `modeldirs::Dict{String, String}`: the directories where the unziped speech recognition models to be used are located. Models are downloadable from here: https://alphacephei.com/vosk/models
- `noises::Dict{String, <:AbstractArray{String}}`: for each model, an array of strings with noises (tokens that are to be ignored in the speech as, e.g., "huh").

# Keyword arguments
- `default_language::String="$(LANG.EN_US)"`: the default language, which is used for the command names, for the voice arguments and for typing when no other language is specified (noted with its IETF langauge tag https://en.wikipedia.org/wiki/IETF_language_tag). Currently supported are: english-US ("en-us"), German ("de"), French ("fr") and Spanish ("es").
- `type_languages::String|AbstractArray{String}=["$(LANG.EN_US)"]`: the languages used for typing, where the first is the default type language (noted with its IETF langauge tag https://en.wikipedia.org/wiki/IETF_language_tag). Currently supported are: english-US ("en-us"), German ("de"), French ("fr") and Spanish ("es"). Type `?Keyboard.type` for information about typing or say "help type" after having started JustSayIt.
!!! note "Advanced"
    - `vosk_log_level::Integer=-1`: the vosk log level (see in the Vosk documentation for details).

See also: [`finalize_jsi`](@ref)
"""
init_jsi

let
    global init_jsi, default_language, type_languages, modelname_default, command, command_names, model, noises, noises_names, recognizer, controller, set_controller, do_perf_debug, use_static_recognizers, update_commands
    _default_language::String                                 = ""
    _type_languages::AbstractArray{String}                    = String[]
    _modelname_default::String                                = ""
    _commands                                                 = Dict{String, Union{Array, Union{Function, PyKey, NTuple{N,PyKey} where N, String, Cmd, Dict}}}() # NOTE: specifying the exact Dict type of the commands leads to a crash that appears to be due to erronous compilation.
    _commands_global                                          = Dict{String, Union{Array, Union{Function, PyKey, NTuple{N,PyKey} where N, String, Cmd, Dict}}}() # ...
    _activ_command_path                                       = Dict{String, Any}()
    _activ_command_leafs                                      = Dict{String, Any}()
    _activ_command_dicts                                      = Dict{String, Any}()
    _models::Dict{String, PyObject}                           = Dict{String, PyObject}()
    _noises::Dict{String, <:AbstractArray{String}}            = Dict{String, Array{String}}()
    _recognizers::Dict{String, Recognizer}                    = Dict{String, Recognizer}()
    _controllers::Dict{String, PyObject}                      = Dict{String, PyObject}()
    _do_perf_debug::Bool                                      = false
    _use_static_recognizers                                   = false
    default_language()                                        = _default_language
    type_languages()                                          = _type_languages
    modelname_default()                                       = _modelname_default
    command(name::AbstractString)                             = _commands[name]
    command_names()                                           = keys(_commands)
    model(name::AbstractString=modelname_default())::PyObject = _models[name]
    noises(modelname::AbstractString)                         = _noises[modelname]  # NOTE: no return value declaration as would be <:AbstractArray{String} which is not possible.
    noises_names()                                            = keys(_noises)
    recognizer(id::AbstractString)::Recognizer                = _recognizers[id]
    controller(name::AbstractString)::PyObject                = if (name in keys(_controllers)) return _controllers[name] else @APIUsageError("The controller for $name is not available as it has not been set up in init_jsi.") end
    set_controller(name::AbstractString, c::PyObject)         = (_controllers[name] = c; return)
    do_perf_debug()::Bool                                     = _do_perf_debug
    set_perf_debug()                                          = if haskey(ENV,"JSI_PERF_DEBUG") _do_perf_debug = (parse(Int64,ENV["JSI_PERF_DEBUG"]) > 0); end
    use_static_recognizers()::Bool                            = _use_static_recognizers
    set_static_recognizers_usage()                            = if haskey(ENV,"JSI_USE_STATIC_RECOGNIZERS") _use_static_recognizers = (parse(Int64,ENV["JSI_USE_STATIC_RECOGNIZERS"]) > 0); end
    
    function initialize_commands(commands)
        _activ_command_path  = Dict{String, Any}()
        _activ_command_leafs = Dict{String, Any}(cn => nothing for cn in keys(commands))
        _activ_command_dicts = [commands]
        _commands_global     = commands
    end

    function update_commands(; commands::Dict=Dict(), cmd_name::String="")
        if cmd_name != ""
            leafs = _activ_command_leafs
            path  = _activ_command_path
            level = 1
            while !haskey(leafs, cmd_name)
                level += 1
                node  = collect(keys(path))[1] # NOTE: path contains always only one key on each level.
                leafs = leafs[node]
                path  = path[node]
            end
            if !isempty(keys(path))
                node = collect(keys(path))[1] # NOTE: path contains always only one key on each level.
                delete!(path, node)
                leafs[node] = nothing
                _activ_command_dicts = _activ_command_dicts[1:level]
            end
            path[cmd_name]  = Dict{String, Any}()
            leafs[cmd_name] = Dict{String, Any}(cn => nothing for cn in keys(commands))
            push!(_activ_command_dicts, commands)
        end
        _commands = _activ_command_dicts[1]
        for c in _activ_command_dicts[2:end]
            _commands = merge(_commands, c) #TODO: Is this needed here? delete!(_commands, cmd_name) I don't think so. Merging multiple times will still always give the same result and there might also be other commands associated to the command name.
        end
        # grammar = json([command_names()..., COMMAND_NAME_SLEEP[default_language()], COMMAND_NAME_AWAKE[default_language()], noises(modelname_default())..., UNKNOWN_TOKEN])
        if haskey(_recognizers, COMMAND_RECOGNIZER_ID) _recognizers[COMMAND_RECOGNIZER_ID].is_persistent = false end # Mark recognizer as temporary to avoid that it will be reset for no benefit.
        # _recognizers[COMMAND_RECOGNIZER_ID] = Recognizer(Vosk.KaldiRecognizer(model(), SAMPLERATE, grammar), true)
        valid_input = [command_names()..., COMMAND_NAME_SLEEP[default_language()], COMMAND_NAME_AWAKE[default_language()]]
        _recognizers[COMMAND_RECOGNIZER_ID] = recognizer(valid_input, noises(modelname_default()); is_persistent=true)
        if !all_consumed() force_restart_recognition() end # If the recognizer was swapped within a word group, then force restart of recognition in order to achieve a proper transition to the recognizer.
        return
    end


    function init_jsi(commands::Dict{String, <:Any}, modeldirs::Dict{String, String}, noises::Dict{String, <:AbstractArray{String}}; default_language::String=LANG.EN_US, type_languages::AbstractArray{String}=[LANG.EN_US], vosk_log_level::Integer=-1)
        # Set global options.
        Vosk.SetLogLevel(vosk_log_level)
        set_perf_debug()
        set_static_recognizers_usage()

        # Store the language choice.
        _default_language  = default_language
        _type_languages    = type_languages
        _modelname_default = modelname(MODELTYPE_DEFAULT, default_language)

        # Validate and store the commands, adding the help command to it.
        if haskey(commands, COMMAND_NAME_SLEEP[default_language]) @ArgumentError("the command name $COMMAND_NAME_SLEEP[default_language] is reserved for putting JustSayIt to sleep. Please choose another command name for your command.") end
        if haskey(commands, COMMAND_NAME_AWAKE[default_language]) @ArgumentError("the command name $COMMAND_NAME_AWAKE[default_language] is reserved for awaking JustSayIt. Please choose another command name for your command.") end
        for cmd_name in keys(commands)
            if !(typeof(commands[cmd_name]) <: eltype(values(_commands))) @ArgumentError("the command belonging to commmand name $cmd_name is of an invalid type. Valid are functions (e.g., Keyboard.type), keys (e.g., Key.ctrl or 'f'), tuples of keys (e.g., (Key.ctrl, 'c') ) and arrays containing any combination of the afore noted.") end
            if isa(commands[cmd_name], Array)
                for subcmd in commands[cmd_name]
                    if (!(typeof(subcmd) <: eltype(values(_commands))) || isa(subcmd, Array)) @ArgumentError("a sub-command ($subcmd) belonging to commmand name $cmd_name is of an invalid type ($(typeof(subcmd))). Valid sub-commands are functions (e.g., Keyboard.type), keys (e.g., Key.ctrl or 'f') and tuples of keys (e.g., (Key.ctrl, 'c') )") end
                end
            end
        end
        initialize_commands(commands)

        # Verify that there is an entry for the default language and selected type languages in modeldirs and noises. Set the values for the other surely required models (i.e. which are used in the Commands submodule) to the same as the default if not available.
        if haskey(modeldirs, "") @ArgumentError("an empty string is not valid as model identifier.") end
        if !haskey(modeldirs, _modelname_default) @ArgumentError("a model directory for the default language ($(lang_str(default_language))) is mandatory (entry \"$_modelname_default\" is missing).") end
        if !haskey(noises,    _modelname_default) @ArgumentError("a noises list for the default language ($(lang_str(default_language))) is mandatory (entry \"$_modelname_default\" is missing).") end
        for lang in type_languages
            if !haskey(modeldirs, modelname(MODELTYPE_TYPE, lang)) @ArgumentError("a model directory for each selected type model is mandatory (entry \"$(modelname(MODELTYPE_TYPE,lang))\" for type language $(lang_str(lang)) is missing).") end
            if !haskey(noises,    modelname(MODELTYPE_TYPE, lang)) @ArgumentError("a noises list for each selected type model is mandatory (entry \"$(modelname(MODELTYPE_TYPE,lang))\" for type language $(lang_str(lang)) is missing).") end
        end
        _noises = noises

        # If the modeldir for the default language points to the default path, download a model if none is present (asumed present if the folder is present)
        modeldir = modeldirs[_modelname_default]
        if modeldir == DEFAULT_MODELDIRS[_modelname_default]
            if !isdir(modeldir)
                filename = basename(modeldir) * ".zip"
                @info "No model for the default language ($(lang_str(default_language))) found in its default location ($(modeldir)): downloading small model ($filename) from '$DEFAULT_MODEL_REPO' (~30-70 MB)..."
                modeldepot = joinpath(modeldir, "..")
                download_and_unzip(modeldepot, filename, DEFAULT_MODEL_REPO)
            end
        end

        # For each of the type languages, if the corresponding modeldir points to the default path, download a large and small model (for keyword handling etc.) if none is present (asumed present if the folder is present)
        for lang in type_languages
            modelname_lang = modelname(MODELTYPE_TYPE, lang)
            modeldir = modeldirs[modelname_lang]
            if modeldir == DEFAULT_MODELDIRS[modelname_lang]
                if !isdir(modeldir)
                    if modeldir == ""
                        @warn("No large accurate model for typing in $(lang_str(lang)) available: falling back to small model for typing.")
                        modeldirs[modelname_lang] = DEFAULT_MODELDIRS[modelname(MODELTYPE_DEFAULT, lang)]
                        modeldir = modeldirs[modelname_lang]
                        if !isdir(modeldir)
                            filename = basename(modeldir) * ".zip"
                            @info "No small model for $(lang_str(lang)) found in its default location ($(modeldir)): downloading small model ($filename) from '$DEFAULT_MODEL_REPO' (~30-70 MB)..."
                            modeldepot = joinpath(modeldir, "..")
                            download_and_unzip(modeldepot, filename, DEFAULT_MODEL_REPO)
                        end
                    else
                        filename = basename(modeldir) * ".zip"
                        @info "No accurate large model for the type language ($(lang_str(lang))) found in its default location ($(modeldir)): download (optional) accurate large model ($filename) from '$DEFAULT_MODEL_REPO' (~1-2 GB)?"
                        answer = ""
                        while !(answer in ["yes", "no"]) println("Type \"yes\" or \"no\":")
                            answer = readline()
                        end
                        if answer == "yes"
                            modeldepot = joinpath(modeldir, "..")
                            download_and_unzip(modeldepot, filename, DEFAULT_MODEL_REPO)
                            # Download also the small module for handling of type keywords etc.
                            modelname_lang = modelname(MODELTYPE_DEFAULT, lang)
                            modeldir = modeldirs[modelname_lang]
                            if modeldir == DEFAULT_MODELDIRS[modelname_lang]
                                if !isdir(modeldir)
                                    filename = basename(modeldir) * ".zip"
                                    @info "No small dynamic model for the type language ($(lang_str(lang))) found in its default location ($(modeldir)): downloading small model ($filename) from '$DEFAULT_MODEL_REPO' (~30-70 MB)..."
                                    modeldepot = joinpath(modeldir, "..")
                                    download_and_unzip(modeldepot, filename, DEFAULT_MODEL_REPO)
                                end
                            end
                        else
                            if lang == default_language
                                @warn("Not downloading large accurate model for typing the default language ($(lang_str(lang))): falling back to default model for typing.")
                                modeldirs[modelname_lang] = modeldirs[_modelname_default]
                            else
                                @warn("Not downloading large accurate model for typing in $(lang_str(lang)): falling back to small model for typing.")
                                modeldirs[modelname_lang] = DEFAULT_MODELDIRS[modelname(MODELTYPE_DEFAULT, lang)]
                                modeldir = modeldirs[modelname_lang]
                                if !isdir(modeldir)
                                    filename = basename(modeldir) * ".zip"
                                    @info "No small model for $(lang_str(lang)) found in its default location ($(modeldir)): downloading small model ($filename) from '$DEFAULT_MODEL_REPO' (~30-70 MB)..."
                                    modeldepot = joinpath(modeldir, "..")
                                    download_and_unzip(modeldepot, filename, DEFAULT_MODEL_REPO)
                                end
                            end
                        end
                    end
                end
            end
        end

        # If no type model was set for the default language make it point to the default model.
        modelname_type = modelname(MODELTYPE_TYPE, default_language)
        if !haskey(modeldirs, modelname_type)
            @warn("The default language ($(lang_str(default_language))) was not selected as typing language. The small language model will therefore be used should any command require typing in the default language.")
            modeldirs[modelname_type] = DEFAULT_MODELDIRS[modelname(MODELTYPE_DEFAULT, default_language)]
        end

        # Set up a default recognizer for each model as well as the command name recognizer.
        for modelname in keys(modeldirs)
            if !isdir(modeldirs[modelname])
                tilde_errmsg = ""
                if startswith(modeldirs[modelname], "~") tilde_errmsg = " Tildes ('~') in strings are not expanded for portability reasons (consider using 'homedir()')." end
                @ArgumentError("directory $(modeldirs[modelname]) does not exist.$tilde_errmsg")
            end
            _models[modelname] = Vosk.Model(modeldirs[modelname])
            _recognizers[modelname] = Recognizer(Vosk.KaldiRecognizer(model(modelname), SAMPLERATE), true)
        end
        update_commands()

        # Set up the special recognizers defined by voiceargs.
        for f_name in voicearg_f_names()
            for voicearg in keys(voiceargs(f_name))
                kwargs    = voiceargs(f_name)[voicearg]
                lang      = haskey(kwargs, :model) ? join(split(kwargs[:model], "-")[2:end], "-") : default_language
                modelname = haskey(kwargs, :model) ? kwargs[:model] : _modelname_default
                if (modeltype(modelname) == MODELTYPE_DEFAULT && lang in [default_language; type_languages]) || (modeltype(modelname) == MODELTYPE_TYPE && lang in type_languages) # Recognizers are only setup for models that are needed, i.e., models for languages that were selected with the arguments default_language or type_languages.
                    if !haskey(modeldirs, modelname) @ArgumentError("no directory was given for the model $(kwargs[:model]) required for voicearg $voicearg in function $f_name.") end # NOTE: this error should only ever occur for user defined @voicearg functions; all funtions in submodule Commands must use
                    if haskey(kwargs, :valid_input)
                        valid_input = isa(kwargs[:valid_input],AbstractArray{String}) ? kwargs[:valid_input] : kwargs[:valid_input][default_language]
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
