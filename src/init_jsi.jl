@doc """
    init_jsi(commands, modeldirs, noises)

!!! note "Advanced"
        init_jsi(commands, modeldirs, noises; <keyword arguments>)

Initialize the package JustSayIt.

# Arguments
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
    model(name::AbstractString=DEFAULT_MODEL_NAME)::PyObject                                            = _models[name]
    noises(modelname::AbstractString)                                                                   = _noises[modelname]  # NOTE: no return value declaration as would be <:AbstractArray{String} which is not possible.
    noises_names()                                                                                      = keys(_noises)
    recognizer(id::AbstractString)::PyObject                                                            = _recognizers[id]
    controller(name::AbstractString)::PyObject                                                          = if (name in keys(_controllers)) return _controllers[name] else error("The controller for $name is not available as it has not been set up in init_jsi.") end
    set_controller(name::AbstractString, c::PyObject)                                                   = (_controllers[name] = c; return)


    function init_jsi(commands::Dict{String, <:Any}, modeldirs::Dict{String, String}, noises::Dict{String, <:AbstractArray{String}}; vosk_log_level::Integer=-1)
        Vosk.SetLogLevel(vosk_log_level)

        # Validate and store the commands, adding the help command to it.
        if haskey(commands, COMMAND_NAME_SLEEP) error("the command name $COMMAND_NAME_SLEEP is reserved for putting JustSayIt to sleep. Please choose another command name for your command.") end
        if haskey(commands, COMMAND_NAME_AWAKE) error("the command name $COMMAND_NAME_AWAKE is reserved for awaking JustSayIt. Please choose another command name for your command.") end
        for cmd_name in keys(commands)
            if !(typeof(commands[cmd_name]) <: eltype(values(_commands))) error("the command belonging to commmand name $command_name is of an invalid. Valid are functions (e.g., Keyboard.type), keys (e.g., Key.ctrl or 'f') and tuples of keys (e.g., (Key.ctrl, 'c') )") end
        end
        _commands = commands

        # Verify that DEFAULT_MODEL_NAME is listed in modeldirs and noises. Set the values for the  other surely required models (i.e. which are used in the Commands submodule) to the same as the default if not available.
        if !haskey(modeldirs, DEFAULT_MODEL_NAME) error("a directory for the 'default' model is mandatory.") end
        if !haskey(modeldirs, TYPE_MODEL_NAME) error("a directory for the 'type' model is mandatory.") end
        if haskey(modeldirs, "") error("an empty string is not valid as model identifier.") end
        if !haskey(noises, DEFAULT_MODEL_NAME) error("a noises list for 'default' model is mandatory (e.g. `NOISES_ENGLISH`).") end
        if !haskey(noises, TYPE_MODEL_NAME)
            noises[TYPE_MODEL_NAME] = noises[DEFAULT_MODEL_NAME]
            @warn("no noises given for model \"type\" - falling back to noises configuration of model 'default' when typing.")
        end
        _noises = noises

        # If the modeldirs point to the default path, download a model if none is present (asumed present if the folder is present)
        if modeldirs[DEFAULT_MODEL_NAME] == DEFAULT_MODELDIRS[DEFAULT_MODEL_NAME]
            if !isdir(modeldirs[DEFAULT_MODEL_NAME])
                @info "No 'default' model found in its default location: downloading small english model ($DEFAULT_ENGLISH_MODEL_ARCHIVE) from '$DEFAULT_MODEL_REPO' (~40 MB)..."
                modeldepot = joinpath(modeldirs[DEFAULT_MODEL_NAME], "..")
                download_and_unzip(modeldepot, DEFAULT_ENGLISH_MODEL_ARCHIVE, DEFAULT_MODEL_REPO)
            end
        end
        if modeldirs[TYPE_MODEL_NAME] == DEFAULT_MODELDIRS[TYPE_MODEL_NAME]
            if !isdir(modeldirs[TYPE_MODEL_NAME])
                @info "No 'type' model found in its default location: download (optional) accurate large english model ($DEFAULT_ENGLISH_TYPE_MODEL_ARCHIVE) from '$DEFAULT_MODEL_REPO' (~1 GB)?"
                answer = ""
                while !(answer in ["yes", "no"]) println("Type \"yes\" or \"no\":")
                    answer = readline()
                end
                if answer == "yes"
                    modeldepot = joinpath(modeldirs[TYPE_MODEL_NAME], "..")
                    download_and_unzip(modeldepot, DEFAULT_ENGLISH_TYPE_MODEL_ARCHIVE, DEFAULT_MODEL_REPO)
                else
                    modeldirs[TYPE_MODEL_NAME] = modeldirs[DEFAULT_MODEL_NAME]
                    @warn("Not downloading `type` model: falling back to model `default` for typing.")
                end
            end
        end

        # Set up a default recognizer for each model as well as the command name recognizer.
        for modelname in keys(modeldirs)
            if !isdir(modeldirs[modelname])
                tilde_errmsg = ""
                if startswith(modeldirs[modelname], "~") tilde_errmsg = " Tildes ('~') in strings are not expanded for portability reasons (consider using 'homedir()')." end
                error("directory $(modeldirs[modelname]) does not exist.$tilde_errmsg")
            end
            _models[modelname] = Vosk.Model(modeldirs[modelname])
            _recognizers[modelname] = Vosk.KaldiRecognizer(model(modelname), SAMPLERATE)
            if modelname == DEFAULT_MODEL_NAME
                grammar = json([keys(commands)..., COMMAND_NAME_SLEEP, COMMAND_NAME_AWAKE, noises[modelname]..., UNKNOWN_TOKEN])
                _recognizers[COMMAND_RECOGNIZER_ID] = Vosk.KaldiRecognizer(model(modelname), SAMPLERATE, grammar)
            end
        end

        # Set up the special recognizers defined by voiceargs.
        for f_name in voicearg_f_names()
            for voicearg in keys(voiceargs(f_name))
                kwargs = voiceargs(f_name)[voicearg]
                if haskey(kwargs, :model) && !haskey(modeldirs, kwargs[:model]) error("no directory was given for the model $(kwargs[:model]) required for voicearg $voicearg in function $f_name.") end # NOTE: this error should only ever occur for user defined @voicearg functions; all funtions in submodule Commands must use
                if haskey(kwargs, :valid_input)
                    modelname = haskey(kwargs, :model) ? kwargs[:model] : DEFAULT_MODEL_NAME
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
