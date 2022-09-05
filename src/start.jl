const DEFAULT_COMMANDS = Dict(
    LANG.DE    => Dict("hilfe"    => Help.help,
                       "schreibe" => Keyboard.type,
                       "email"    => Email.email,
                       "internet" => Internet.internet),
    LANG.EN_US => Dict("help"     => Help.help,
                       "type"     => Keyboard.type,
                       "email"    => Email.email,
                       "internet" => Internet.internet),
    LANG.ES    => Dict("ayuda"    => Help.help,
                       "escribe"  => Keyboard.type,
                       "email"    => Email.email,
                       "internet" => Internet.internet),
    LANG.FR    => Dict("aide"     => Help.help,
                       "écrire"   => Keyboard.type,
                       "email"    => Email.email,
                       "internet" => Internet.internet),
)


"""
    start()
    start(<keyword arguments>)

Start offline, low latency, highly accurate and secure speech to command translation.

!!! note "NOTE: Support for German and Spanish deactivated"
    Support for German and Spanish is deactivated due to an unresolved issue with the underlying Vosk Speech Recognition Toolkit: https://github.com/alphacep/vosk-api/issues/1017

# Keyword arguments
- `default_language::String="$(LANG.EN_US)"`: the default language, which is used for the command names, for the voice arguments and for typing when no other language is specified (noted with its IETF langauge tag https://en.wikipedia.org/wiki/IETF_language_tag). Currently supported are: english-US ("en-us"), German ("de"), French ("fr") and Spanish ("es").
- `type_languages::String|AbstractArray{String}=default_language`: the languages used for typing, where the first is the default type language (noted with its IETF langauge tag https://en.wikipedia.org/wiki/IETF_language_tag). Currently supported are: english-US ("en-us"), German ("de"), French ("fr") and Spanish ("es"). Type `?Keyboard.type` for information about typing or say "help type" after having started JustSayIt.
- `commands::Dict{String, <:Any}=DEFAULT_COMMANDS[default_language]`: the commands to be recognized with their mapping to a function or to a keyboard key or shortcut.
- `subset::AbstractArray{String}=nothing`: a subset of the `commands` to be recognised and executed (instead of the complete `commands` list).
- `max_speed_subset::AbstractArray{String}=nothing`: a subset of the `commands` for which the command names (first word of a command) are to be recognised with maxium speed rather than with maximum accuracy. Forcing maximum speed is usually desired for single word commands that map to functions or keyboard shortcuts that should trigger immediate actions as, e.g., mouse clicks or page up/down (in general, actions that do not modify content and can therefore safely be triggered at maximum speed). Note that forcing maximum speed means not to wait for a certain amount of silence after the end of a command as normally done for the full confirmation of a recognition. As a result, it enables a minimal latency between the saying of a command name and its execution. Note that it is usually possible to define very distinctive command names, which allow for a safe command name to shortcut mapping at maximum speed (to be tested case by case).
!!! note "Advanced"
    - `modeldirs::Dict{String, String}`: the directories where the unziped speech recognition models to be used are located. If `modeldirs` is not set, then it is automatically defined according to the `default_language` and `type_languages` set. Models are downloadable from here: https://alphacephei.com/vosk/models
    - `noises::Dict{String, <:AbstractArray{String}}=DEFAULT_NOISES`: for each model, an array of strings with noises (tokens that are to be ignored in the speech as, e.g., "huh").
    - `audio_input_cmd::Cmd=nothing`: a command that returns an audio stream to replace the default audio recorder. The audio stream must fullfill the following properties: `samplerate=$SAMPLERATE`, `channels=$AUDIO_IN_CHANNELS` and `format=Int16` (signed 16-bit integer).

# Submodules for command name to function mapping
- [`Help`](@ref)
- [`Keyboard`](@ref)
- [`Mouse`](@ref)
- [`Email`](@ref)
- [`Internet`](@ref)

To see a description of a submodule, type `?<modulename>`.


# Examples

#### Define `default_language` (also used for typing if `type_languages` is not set)
```
# Set command and type language to french:
using JustSayIt
start(default_language="$(LANG.FR)")
```

#### Define `default_language` and `type_languages`
```
# Set command language to french and type languages to french and spanish:
using JustSayIt
start(default_language="$(LANG.FR)", type_languages=["$(LANG.FR)","$(LANG.ES)"])
```

#### Define `subset`
```
# Listen only to the commands "help" and "type".
using JustSayIt
start(subset=["help", "type"])
```

#### Define custom `commands` - functions and keyboard shortcuts - and a `max_speed_subset`
```
using JustSayIt
commands = Dict("help"      => Help.help,
                "type"      => Keyboard.type,
                "ma"        => Mouse.click_left,
                "select"    => Mouse.press_left,
                "okay"      => Mouse.release_left,
                "middle"    => Mouse.click_middle,
                "right"     => Mouse.click_right,
                "double"    => Mouse.click_double,
                "triple"    => Mouse.click_triple,
                "copy"      => (Key.ctrl, 'c'),
                "cut"       => (Key.ctrl, 'x'),
                "paste"     => (Key.ctrl, 'v'),
                "undo"      => (Key.ctrl, 'z'),
                "redo"      => (Key.ctrl, Key.shift, 'z'),
                "upwards"   => Key.page_up,
                "downwards" => Key.page_down,
                );
start(commands=commands, max_speed_subset=["ma", "select", "okay", "middle", "right", "double", "triple", "copy", "upwards", "downwards"])
```

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
audio_input_cmd = `arecord --rate=$SAMPLERATE --channels=$AUDIO_IN_CHANNELS --format=S16_LE`
start(audio_input_cmd=audio_input_cmd)
```

# Default `commands`
```
$(pretty_dict_string(DEFAULT_COMMANDS))
```

# Default model directories
```
$(pretty_dict_string(DEFAULT_MODELDIRS))
```

# Default `noises`
```
$(pretty_dict_string(DEFAULT_NOISES))
```
"""
function start(; default_language::String=LANG.EN_US, type_languages::Union{String,AbstractArray{String}}=default_language, commands::Union{Nothing, Dict{String, <:Any}}=nothing, subset::Union{Nothing, AbstractArray{String}}=nothing, max_speed_subset::Union{Nothing, AbstractArray{String}}=nothing, modeldirs::Union{Nothing, Dict{String,String}}=nothing, noises::Dict{String,<:AbstractArray{String}}=DEFAULT_NOISES, audio_input_cmd::Union{Cmd,Nothing}=nothing) where N
    if (default_language in [LANG.DE, LANG.ES]) @KeywordArgumentError("Currently unsupported language: support for German (\"de\") and Spanish (\"es\") is deactivated due to an unresolved issue with the underlying Vosk Speech Recognition Toolkit: https://github.com/alphacep/vosk-api/issues/1017") end
    if (default_language ∉ LANG) @KeywordArgumentError("invalid `default_language` (obtained \"$default_language\"). Valid are: \"$(join(LANG, "\", \"", "\" and \""))\".") end
    if isa(type_languages, String) type_languages = String[type_languages] end
    for l in type_languages
        if (l in [LANG.DE, LANG.ES]) @KeywordArgumentError("Currently unsupported language: support for German (\"de\") and Spanish (\"es\") is deactivated due to an unresolved issue with the underlying Vosk Speech Recognition Toolkit: https://github.com/alphacep/vosk-api/issues/1017") end
        if (l ∉ LANG) @KeywordArgumentError("invalid `type_language` (obtained \"$l\"). Valid are: \"$(join(LANG, "\", \"", "\" and \""))\".") end
    end
    if isnothing(commands) commands = DEFAULT_COMMANDS[default_language] end
    if (!isnothing(subset) && !issubset(subset, keys(commands))) @IncoherentArgumentError("'subset' incoherent: the obtained command name subset ($(subset)) is not a subset of the command names ($(keys(commands))).") end
    if (!isnothing(max_speed_subset) && !issubset(max_speed_subset, keys(commands))) @IncoherentArgumentError("'max_speed_subset' incoherent: the obtained max_speed_subset ($(max_speed_subset)) is not a subset of the command names ($(keys(commands))).") end
    if !isnothing(subset) commands = filter(x -> x[1] in subset, commands) end
    if isnothing(max_speed_subset) max_speed_subset = String[] end
    max_speed_token_subset = map(max_speed_subset) do cmd_name # Only the first tokens are used to decide if max speed is used.
       string(first(split(cmd_name)))
    end
    max_speed_multiword_cmds = [x for x in keys(commands) if any(startswith.(x, [x for x in max_speed_token_subset if x ∉ max_speed_subset]))]
    incoherent_subset = [x for x in max_speed_multiword_cmds if x ∉ max_speed_subset]
    if !isempty(incoherent_subset) @IncoherentArgumentError("'max_speed_subset' incoherent: the following commands are not part of 'max_speed_subset', but start with the same word as a command that is part of it: \"$(join(incoherent_subset,"\", \"", " and "))\". Adjust the 'max_speed_subset' to prevent this.") end
    if isnothing(modeldirs)
        modelnames = [modelname(MODELTYPE_DEFAULT, default_language); modelname.(MODELTYPE_TYPE, type_languages); modelname.(MODELTYPE_DEFAULT, type_languages)]  #NOTE: a small ("default") model is also required for the type languages in order to deal with keywords etc (valid input restricted...).
        modeldirs = Dict(key => DEFAULT_MODELDIRS[key] for key in keys(DEFAULT_MODELDIRS) if key in modelnames)
    end

    # Initializations
    @info "JustSayIt: I am initializing..."
    init_jsi(commands, modeldirs, noises; default_language=default_language, type_languages=type_languages)
    start_recording(; audio_input_cmd=audio_input_cmd)

    # Interprete commands
    modelname_default = modelname(MODELTYPE_DEFAULT, default_language)
    valid_cmd_names   = command_names()
    cmd_name          = ""
    cmd_name_awake    = COMMAND_NAME_AWAKE[default_language]
    cmd_name_sleep    = COMMAND_NAME_SLEEP[default_language]
    cmd_awake_jsi     = (default_language == LANG.EN_US) ? "$cmd_name_awake JustSayIt" : "$cmd_name_awake JSI"
    cmd_sleep_jsi     = (default_language == LANG.EN_US) ? "$cmd_name_sleep JustSayIt" : "$cmd_name_sleep JSI"
    is_sleeping       = false
    use_max_speed     = true
    @info "Listening for commands in $(lang_str(default_language)) (say \"$cmd_sleep_jsi\" to put me to sleep; press CTRL+c to terminate)..."
    try
        while true
            if is_sleeping
                if cmd_name == cmd_name_awake
                    if is_confirmed() is_sleeping = false end
                    if (is_sleeping) @info("I think I heard \"$cmd_name_awake\". If you want to awake me, say \"$cmd_awake_jsi\".")
                    else             @info("... awake again. Listening for commands...")
                    end
                end
            else
                if cmd_name in valid_cmd_names
                    cmd = command(string(cmd_name))
                    if (t0_latency() > 0.0 && do_perf_debug()) @debug "Latency of command `$cmd_name`: $(round(toc(t0_latency()),sigdigits=2))." end
                    try
                        latency_msg = use_max_speed ? " (latency: $(round(Int,toc(t0_latency())*1000)) ms)" : ""
                        @info "Starting command: $(pretty_cmd_string(cmd))"*latency_msg
                        execute(cmd)
                    catch e
                        if isa(e, InsecureRecognitionException)
                            @info("Command `$cmd_name` aborted: insecure command argument recognition.")
                        elseif isa(e, InterruptException)
                            @info "Command `$cmd_name` aborted (with CTRL+C)."
                        else
                            rethrow(e)
                        end
                    end
                elseif cmd_name == cmd_name_sleep
                    if is_confirmed() is_sleeping = true end
                    if (!is_sleeping) @info("I heard \"$cmd_name_sleep\". If you want me to sleep, say \"$cmd_sleep_jsi\".")
                    else              @info("Going to sleep... (To awake me, just say \"$cmd_awake_jsi\".)")
                    end
                elseif cmd_name != ""
                    @debug "Invalid command: $cmd_name."
                end
            end
            try
                force_reset_previous(recognizer(COMMAND_RECOGNIZER_ID))
                use_max_speed = _is_next(max_speed_token_subset, recognizer(COMMAND_RECOGNIZER_ID), _noises(modelname_default); use_partial_recognitions=true, ignore_unknown=false)
                cmd_name = next_token(recognizer(COMMAND_RECOGNIZER_ID), _noises(modelname_default); use_partial_recognitions = use_max_speed, ignore_unknown=false)
                if cmd_name == UNKNOWN_TOKEN # For increased recognition security, ignore the current word group if the unknown token was obtained as command name (achieved by doing a full reset). This will prevent for example "text right" or "text type text" to trigger an action, while "right" or "type text" does so.
                    reset_all()
                    cmd_name = ""
                end
                while (cmd_name != "") && (cmd_name ∉ valid_cmd_names) && any(startswith.(valid_cmd_names, cmd_name))
                    token = next_token(recognizer(COMMAND_RECOGNIZER_ID), _noises(modelname_default); use_partial_recognitions = use_max_speed, ignore_unknown=false)
                    if token == UNKNOWN_TOKEN # For increased recognition security, ignore the current word group if the unknown token was obtained as command name (achieved by doing a full reset). This will prevent for example "text right" or "text type text" to trigger an action, while "right" or "type text" does so.
                        reset_all()
                        cmd_name = ""
                    else
                        cmd_name = cmd_name * " " * token
                    end
                end
            catch e
                if isa(e, InsecureRecognitionException)
                    if !is_sleeping @debug(e.msg) end
                    cmd_name = ""
                else
                    rethrow(e)
                end
            end
        end
    catch e
        if isa(e, InterruptException)
            @info "Terminating JustSayIt..."
        else
            rethrow(e)
        end
    finally
        stop_recording()
        @info "Stopped listening for commands."
    end

    finalize_jsi()
end

function is_confirmed()
    try
        _is_confirmed()
    catch e
        if isa(e, InsecureRecognitionException)
            return false
        else
            rethrow(e)
        end
    end
end


const CONFIRMATION = Dict(LANG.DE=>["j s i"], LANG.EN_US=>["just say it"], LANG.ES=>["j s i"], LANG.FR=>["j s i"])

@voiceargs words=>(valid_input=Tuple(CONFIRMATION), vararg_timeout=2.0, vararg_max=3) function _is_confirmed(words::String...)
    return ([join(words, " ")] == CONFIRMATION[default_language()])
end

execute(cmd::Function)                  = cmd()
execute(cmd::PyKey)                     = Keyboard.press_keys(cmd)
execute(cmd::NTuple{N,PyKey} where {N}) = Keyboard.press_keys(cmd...)
execute(cmd::Array)                     = for subcmd in cmd execute(subcmd) end
