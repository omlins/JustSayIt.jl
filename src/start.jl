const DEFAULT_COMMANDS = Dict(
    LANG.DE    => Dict("hilfe"    => Help.help),
    LANG.EN_US => Dict("help"     => Help.help),
    LANG.ES    => Dict("ayuda"    => Help.help),
    LANG.FR    => Dict("aide"     => Help.help),
)


"""
    start()
    start(<keyword arguments>)

Start offline, low latency, highly accurate and secure speech to command translation.

# Keyword arguments
- `commands::Dict{String, <:Any}=DEFAULT_COMMANDS[default_language]`: the commands to be recognized with their mapping to a function or to a keyboard key or shortcut or a sequence of any of those.
- `subset::AbstractArray{String}=nothing`: a subset of the `commands` to be recognised and executed (instead of the complete `commands` list).
- `max_speed_subset::AbstractArray{String}=nothing`: a subset of the `commands` for which the command names (first word of a command) are to be recognised with maxium speed rather than with maximum accuracy. Forcing maximum speed is usually desired for single word commands that map to functions or keyboard shortcuts that should trigger immediate actions as, e.g., mouse clicks or page up/down (in general, actions that do not modify content and can therefore safely be triggered at maximum speed). Note that forcing maximum speed means not to wait for a certain amount of silence after the end of a command as normally done for the full confirmation of a recognition. As a result, it enables a minimal latency between the saying of a command name and its execution. Note that it is usually possible to define very distinctive command names, which allow for a safe command name to shortcut mapping at maximum speed (to be tested case by case).
- `default_language::String="$(LANG.EN_US)"`: the default language, which is used for the command names, for the voice arguments and for typing when no other language is specified (noted with its IETF language tag https://en.wikipedia.org/wiki/IETF_language_tag). Currently supported are: english-US ("en-us"), German ("de"), French ("fr") and Spanish ("es").
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
    - `audio_input_cmd::Cmd=nothing`: a command that returns an audio stream to replace the default audio recorder. The audio stream must fullfill the following properties: `samplerate=$SAMPLERATE`, `channels=$AUDIO_IO_CHANNELS` and `format=$AUDIO_ELTYPE` (signed 16-bit integer).


# Submodules for command name to function mapping (alphabetically ordered)
- [`Clipboard`](@ref)
- [`Generic`](@ref)
- [`Help`](@ref)
- [`Keyboard`](@ref)
- [`LLM`](@ref)
- [`Mouse`](@ref)
- [`Selection`](@ref)
- [`STT`](@ref)
- [`TTS`](@ref)

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

#### Define custom `commands` - functions, keyboard shortcuts and sequences of those - and a `max_speed_subset`
```
using JustSayIt
commands = Dict("help"      => Help.help,
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
                "take"      => [Mouse.click_double, (Key.ctrl, 'c')],
                "replace"   => [Mouse.click_double, (Key.ctrl, 'v')],
                );
start(commands=commands, max_speed_subset=["ma", "select", "okay", "middle", "right", "double", "triple", "copy", "upwards", "downwards", "take"])
```

# Default `commands`
```
$(pretty_dict_string(DEFAULT_COMMANDS))
```

"""
function start(; commands::Union{Nothing, Dict{String, <:Any}}=nothing, subset::Union{Nothing, AbstractArray{String}}=nothing, max_speed_subset::Union{Nothing, AbstractArray{String}}=nothing, default_language::String=LANG.EN_US, type_languages::Union{String,AbstractArray{String}}=default_language, use_llm::Bool=true, use_tts::Bool=true, tts_async_default::Bool=true, use_gpu::Bool=true, microphone_id::Int=-1, microphone_name::String="", audiooutput_id::Int=-1, audiooutput_name::String="", audio_input_cmd::Union{Cmd,Nothing}=nothing)
    _start(; commands=commands, subset=subset, max_speed_subset=max_speed_subset, default_language=default_language, type_languages=type_languages, use_llm=use_llm, use_tts=use_tts, tts_async_default=tts_async_default, use_gpu=use_gpu, microphone_id=microphone_id, microphone_name=microphone_name, audiooutput_id=audiooutput_id, audiooutput_name=audiooutput_name, audio_input_cmd=audio_input_cmd)
end

function _start(; commands::Union{Nothing, Dict{String, <:Any}}=nothing, subset::Union{Nothing, AbstractArray{String}}=nothing, max_speed_subset::Union{Nothing, AbstractArray{String}}=nothing, default_language::String=LANG.EN_US, type_languages::Union{String,AbstractArray{String}}=default_language, use_llm::Bool=true, use_tts::Bool=true, tts_async_default::Bool=true, use_gpu::Bool=true, microphone_id::Int=-1, microphone_name::String="", audiooutput_id::Int=-1, audiooutput_name::String="", audio_input_cmd::Union{Cmd,Nothing}=nothing, nbcommands::Int=-1)
    if isnothing(commands) commands = DEFAULT_COMMANDS[default_language] end
    if (!isnothing(subset) && !issubset(subset, keys(commands))) @IncoherentArgumentError("'subset' incoherent: the obtained command name subset ($(subset)) is not a subset of the command names ($(keys(commands))).") end
    #TODO: temporarily deactivated: if (!isnothing(max_speed_subset) && !issubset(max_speed_subset, keys(commands))) @IncoherentArgumentError("'max_speed_subset' incoherent: the obtained max_speed_subset ($(max_speed_subset)) is not a subset of the command names ($(keys(commands))).") end
    if !isnothing(subset) commands = filter(x -> x[1] in subset, commands) end
    if isnothing(max_speed_subset) max_speed_subset = String[] end
    max_speed_token_subset = map(max_speed_subset) do cmd_name # Only the first tokens are used to decide if max speed is used.
       string(first(split(cmd_name)))
    end
    max_speed_multiword_cmds = [x for x in keys(commands) if any(startswith.(x, [x for x in max_speed_token_subset if x ∉ max_speed_subset]))]
    incoherent_subset = [x for x in max_speed_multiword_cmds if x ∉ max_speed_subset]
    #TODO: temporarily deactivated: if !isempty(incoherent_subset) @IncoherentArgumentError("'max_speed_subset' incoherent: the following commands are not part of 'max_speed_subset', but start with the same word as a command that is part of it: \"$(join(incoherent_subset,"\", \"", " and "))\". Adjust the 'max_speed_subset' to prevent this.") end

    finalize = !is_initialized() # Do not finalize if it is already initialized: then this must be taken care of outside.
    if is_initialized()
        if (nbcommands == -1) @warn "JustSayIt is already initialized; ignoring new initialization parameters." end
    else
        init_jsi(; default_language=default_language, type_languages=type_languages, use_llm=use_llm, use_tts=use_tts, tts_async_default=tts_async_default, use_gpu=use_gpu, microphone_id=microphone_id, microphone_name=microphone_name, audiooutput_id=audiooutput_id, audiooutput_name=audiooutput_name, audio_input_cmd=audio_input_cmd)
    end
    init_commands(commands)
    interpret(max_speed_token_subset; nbcommands=nbcommands, finalize=finalize)
    return
end

    
function interpret(max_speed_token_subset::AbstractArray{String}; nbcommands::Int=-1, finalize::Bool=true)
    do_infinite_loop  = (nbcommands == -1)
    nbcommands_processed = 0
    cmd_recognizer()  = recognizer(COMMAND_RECOGNIZER_ID)
    valid_cmd_names   = command_names()
    cmd_name          = ""
    cmd_name_awake    = COMMAND_NAME_AWAKE[default_language()]
    cmd_name_sleep    = COMMAND_NAME_SLEEP[default_language()]
    cmd_awake_jsi     = (default_language() == LANG.EN_US) ? "$cmd_name_awake JustSayIt" : "$cmd_name_awake JSI"
    cmd_sleep_jsi     = (default_language() == LANG.EN_US) ? "$cmd_name_sleep JustSayIt" : "$cmd_name_sleep JSI"
    is_sleeping       = false
    use_max_speed     = true
    if do_infinite_loop
        @info "I'm ready. Listening for commands in $(lang_str(default_language())) (say \"$cmd_sleep_jsi\" to put me to sleep; press CTRL+c in the terminal to terminate)..."
        say("...and now, whatever you need: \"just say it\"!")
    end
    try
        while true
            try
                if !is_active(cmd_recognizer()) update_commands() end # NOTE: a reset might be beneficial or needed at some point, as previously force_reset_previous(cmd_recognizer())
                use_max_speed = _is_next(max_speed_token_subset, cmd_recognizer(), noises(); use_partial_recognitions=true, ignore_unknown=false)
                cmd_name = next_token(cmd_recognizer(), noises(); use_partial_recognitions = use_max_speed, ignore_unknown=false)
                if cmd_name == UNKNOWN_TOKEN # For increased recognition security, ignore the current word group if the unknown token was obtained as command name (achieved by doing a full reset). This will prevent for example "text right" or "text type text" to trigger an action, while "right" or "type text" does so.
                    reset_all()
                    cmd_name = ""
                    if !is_sleeping @voiceinfo "Command not recognized." end
                end
                while (cmd_name != "") && (cmd_name ∉ valid_cmd_names) && any(startswith.(valid_cmd_names, cmd_name))
                    token = next_token(cmd_recognizer(), noises(); use_partial_recognitions = use_max_speed, ignore_unknown=false)
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
            if is_sleeping
                if cmd_name == cmd_name_awake
                    if is_confirmed() is_sleeping = false end
                    if (is_sleeping) @voiceinfo "I think I heard \"$cmd_name_awake\". If you want to awake me, say \"$cmd_awake_jsi\"."
                    else             @voiceinfo "... awake again. Listening for commands..."
                    end
                end
            else
                if cmd_name in valid_cmd_names
                    cmd = command(string(cmd_name))
                    if (t0_latency() > 0.0 && do_perf_debug()) @debug "Latency of command `$cmd_name`: $(round(toc(t0_latency()),sigdigits=2))." end
                    try
                        if !isa(cmd, Dict)
                            latency_msg = use_max_speed ? " (latency: $(round(Int,toc(t0_latency())*1000)) ms)" : ""
                            @info "Starting command: $(pretty_cmd_string(cmd))"*latency_msg
                        end
                        execute(cmd, string(cmd_name))
                        valid_cmd_names = command_names() # This is needed as new commands have potentially been activated...
                    catch e
                        if isa(e, InsecureRecognitionException)
                            @debug e.msg
                            @info("Command `$cmd_name` aborted: insecure command argument recognition.")
                            say("Command `$cmd_name` aborted.")
                            sleep(2.0) # Give the recognizer time to finalize
                        elseif isa(e, InterruptException)
                            @info "Command `$cmd_name` aborted (with CTRL+C)."
                        else
                            rethrow(e)
                        end
                    end
                elseif cmd_name == cmd_name_sleep
                    if is_confirmed() is_sleeping = true end
                    if (!is_sleeping) @voiceinfo("I heard \"$cmd_name_sleep\". If you want me to sleep, say \"$cmd_sleep_jsi\".")
                    else              @voiceinfo("Going to sleep... (To awake me, just say \"$cmd_awake_jsi\".)")
                    end
                elseif cmd_name != ""
                    @debug "Invalid command: $cmd_name."
                end
            end
            nbcommands_processed+=1
            if !do_infinite_loop && (nbcommands_processed >= nbcommands) break end
        end
    catch e
        if isa(e, InterruptException)
            @info "Terminating JustSayIt..."
            if (finalize) finalize_jsi() end # NOTE: in case of another exception it must not be finalized because then we would not get the stack trace.
        else
            rethrow(e)
        end
    end
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


@voiceargs words=>(valid_input=Tuple(CONFIRMATION), timeout=2.0) function _is_confirmed(words::String...)
    return ([join(words, " ")] == CONFIRMATION[default_language()])
end


## Functions for unit testing

function interpret(text_with_silence::AbstractVector, _start_kwargs::NamedTuple; muted::Bool=true, wavfile::String="", enginename::String=tts())
    generate_audio_input(text_with_silence; muted=muted, wavfile=wavfile, enginename=enginename) do
        _start(; _start_kwargs...)
    end
end
