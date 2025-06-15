let
    global command, command_names, init_commands, update_commands
    _commands                                                                                           = Dict()
    _commands_global                                                                                    = Dict()
    _activ_command_path                                                                                 = Dict{String, Any}()
    _activ_command_leafs                                                                                = Dict{String, Any}()
    _activ_command_dicts                                                                                = Dict{String, Any}()
    command(name::AbstractString)                                                                       = _commands[name]
    command_names()                                                                                     = keys(_commands)


    function init_commands(commands::Dict{String, <:Any})
        validate_commands(commands)
        _activ_command_path  = Dict{String, Any}()
        _activ_command_leafs = Dict{String, Any}(cn => nothing for cn in keys(commands))
        _activ_command_dicts = [commands]
        _commands_global     = commands
        update_commands()
    end

    function validate_commands(commands::Dict{String, <:Any})
        command_type = Union{Array, Union{Function, PyKey, NTuple{N,PyKey} where N, String, Cmd, Dict}}
        if haskey(commands, COMMAND_NAME_SLEEP[default_language()]) @ArgumentError("the command name $(COMMAND_NAME_SLEEP[default_language()]) is reserved for putting JustSayIt to sleep. Please choose another command name for your command.") end
        if haskey(commands, COMMAND_NAME_AWAKE[default_language()]) @ArgumentError("the command name $(COMMAND_NAME_AWAKE[default_language()]) is reserved for awaking JustSayIt. Please choose another command name for your command.") end
        for cmd_name in keys(commands)
            if !(typeof(commands[cmd_name]) <: command_type) @ArgumentError("the command belonging to commmand name $cmd_name is of an invalid type. Valid are functions (e.g., Keyboard.type), keys (e.g., Key.ctrl or 'f'), tuples of keys (e.g., (Key.ctrl, 'c') ), commands (e.g. `firefox`), command dictionaries and arrays containing any combination of the afore noted.") end
            if isa(commands[cmd_name], Array)
                for subcmd in commands[cmd_name]
                    if (!(typeof(subcmd) <: command_type) || isa(subcmd, Array)) @ArgumentError("a sub-command ($subcmd) belonging to commmand name $cmd_name is of an invalid type ($(typeof(subcmd))). Valid sub-commands are functions (e.g., Keyboard.type), keys (e.g., Key.ctrl or 'f'), tuples of keys (e.g., (Key.ctrl, 'c') ), commands (e.g. `firefox`) and command dictionaries ") end
                end
            end
        end
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
        if has_recognizer(COMMAND_RECOGNIZER_ID) set_recognizer_persistent(COMMAND_RECOGNIZER_ID, false) end # Mark recognizer as temporary to avoid that it will be reset for no benefit.
        # _recognizers[COMMAND_RECOGNIZER_ID] = Recognizer(Vosk.KaldiRecognizer(model(), SAMPLERATE, grammar), true)
        valid_input = [command_names()..., COMMAND_NAME_SLEEP[default_language()], COMMAND_NAME_AWAKE[default_language()], COUNTS[default_language()]...] # TODO: this is a work around for better recognition of the frequent Generic commands. A proper solution should be found ways voice arguments. The original command here was: valid_input = [command_names()..., COMMAND_NAME_SLEEP[default_language()], COMMAND_NAME_AWAKE[default_language()]]
        r = recognizer(valid_input, noises(modelname_default()); is_persistent=true)
        set_recognizer(COMMAND_RECOGNIZER_ID, r)
        if !all_consumed() force_restart_recognition() end # If the recognizer was swapped within a word group, then force restart of recognition in order to achieve a proper transition to the recognizer.
        return
    end
end


let
    global active_app, execute
    _active_app::String = ""
    active_app() = _active_app
    execute(cmd::Cmd, cmd_name::String)                   = ( if !activate(cmd) run(cmd; wait=false) end; _active_app = cmd.exec[1] )
end

execute(cmd::Function, cmd_name::String)                  = cmd()
execute(cmd::PyKey, cmd_name::String)                     = Keyboard.press_keys(cmd)
execute(cmd::NTuple{N,PyKey} where {N}, cmd_name::String) = Keyboard.press_keys(cmd...)
execute(cmd::String, cmd_name::String)                    = Keyboard.type_string(cmd)
execute(cmd::Array, cmd_name::String)                     = for subcmd in cmd execute(subcmd, cmd_name) end


function execute(cmd::Dict, cmd_name::String)
    @info "Activating commands: $cmd_name"
    update_commands(commands=cmd, cmd_name=cmd_name)
    Help.help(Help.COMMANDS_KEYWORDS[default_language()]; debugonly=true)
end

function activate(cmd::Cmd)
    app = cmd.exec[1]    
    open_apps = Pywinctl.getAllAppsNames()
    open_app = (app in open_apps) ? app : ""
    if open_app == ""
        for a in open_apps
            if     occursin(Regex("^" * app * "[^a-zA-Z]" ), a  ) open_app = a; break
            elseif occursin(Regex("^" * a   * "[^a-zA-Z]" ), app) open_app = a; break # E.g. app=google-chrome; a=chrome
            elseif occursin(Regex("[^a-zA-Z]" * app * "\$"), a  ) open_app = a; break
            elseif occursin(Regex("[^a-zA-Z]" * a   * "\$"), app) open_app = a; break
            end
        end
    end
    is_open = (open_app != "")
    if is_open
        windowtitle = Pywinctl.getAllAppsWindowsTitles()[open_app][1] # If there are multiple open windows for the given application take the first window.
        window = Pywinctl.getWindowsWithTitle(windowtitle)[1]
        window.activate()
    end
    return is_open
end
