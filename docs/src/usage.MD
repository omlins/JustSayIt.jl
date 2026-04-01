# Usage

## Fully automatic installation
After installing [Julia] - if not yet installed - JustSayIt can be installed directly with the [Julia package manager] from the [Julia REPL]:
```julia-repl
julia>]
  pkg> add JustSayIt
```
All dependencies are automatically installed. Python dependencies are automatically installed in a local Miniconda environment, set up by [Conda.jl]. Default language models are automatically downloaded at first usage of JustSayIt.


## Simple basic software usage
The basic usage of JustSayIt is as simple as launching the [Julia REPL] and calling the commands `using JustSayIt` followed by `start()`:
```julia-repl
$> julia
julia> using JustSayIt
julia> start()
```
More information on customization keywords of [`start`](@ref) is given in the following subsections and in the [Software reference](@ref).


## User definable mapping of command names to functions or keyboard shortcuts
The keyword `commands` of [`start`](@ref) enables to freely define a mapping of command names to functions or keyboard shortcuts or sequences of those, e.g.:
```julia
# Define custom commands
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
                "take"      => [Mouse.click_double, (Key.ctrl, 'c')],
                "replace"   => [Mouse.click_double, (Key.ctrl, 'v')],
                );
start(commands=commands, max_speed_subset=["ma", "select", "okay", "middle", "right", "double", "triple", "copy", "upwards", "downwards", "take"])
```

Note that keyboard shortcuts are given as either single keys (e.g., `Key.page_up`) or tuples of keys (e.g., `(Key.ctrl, 'c')`). Special keys are selected from those available in `Key`: type `Key.`+ `tab` in the [Julia REPL] to see the available keys (the full documentation on the available keys is available [here](https://pynput.readthedocs.io/en/latest/keyboard.html#pynput.keyboard.Key)). Character keys are simply given in single quotes (e.g., `'c'`).

A mapping of a command name to a sequence of commands can be defined by using as mapping target an array whose elements are functions or keyboard shortcuts (e.g., `[Mouse.click_double, (Key.ctrl, 'c')]`). This enables to express new complex actions without programming. In the above example, "take" double clicks the word below the mouse curser to select it and then copies it; "replace" double clicks the word below the mouse curser to select it and then replaces it.

A command entry can also activate a nested command dictionary. This is useful for application-specific command contexts that should become active only after a higher-level command has been recognized, e.g.:
```julia
using JustSayIt
vsc_commands = Dict("comment" => (Key.ctrl, '/'),
                    "save"    => (Key.ctrl, 's'))
commands = Dict("coding" => [`code`, vsc_commands],
                "help"   => Help.help)
start(commands=commands)
```
In this style, saying `coding` activates the corresponding nested command set for that context while keeping the top-level command dictionary concise.
 
The keyword `subset` of [`start`](@ref) enables to activate only a subset of the default or user-defined commands. The following example selects a subset of the default commands:
```julia
# Listen only to the commands "help" and "type".
using JustSayIt
start(subset=["help", "type"])
```


## Per command choice between maximum speed or accuracy

The keyword `max_speed_subset` of [`start`](@ref) enables to define a subset of the `commands` for which the command names are to be recognized with maximum speed rather than with maximum accuracy, e.g.:
```julia
# Define custom commands
using JustSayIt
commands = Dict("copy"      => (Key.ctrl, 'c'),
                "cut"       => (Key.ctrl, 'x'),
                "paste"     => (Key.ctrl, 'v'),
                "undo"      => (Key.ctrl, 'z'),
                "redo"      => (Key.ctrl, Key.shift, 'z'),
                "upwards"   => Key.page_up,
                "downwards" => Key.page_down,
                );
start(commands=commands, max_speed_subset=["upwards", "downwards", "copy"])
```
Forcing maximum speed is usually desired for single word commands that map to functions or keyboard shortcuts that should trigger immediate actions as, e.g., mouse clicks or, as in the above example page up/down or copy (in general, actions that do not modify content and can therefore safely be triggered at maximum speed). However, it is typically not desired for "dangerous" actions, like "cut", "paste", "undo" and "redo" in this example. Note that forcing maximum speed means not to wait for a certain amount of silence after the end of a command as normally done for the full confirmation of a recognition. As a result, it enables a minimal latency between the saying of a command name and its execution. Note that it is usually possible to define very distinctive command names, which allow for a safe command name to shortcut mapping at maximum speed (to be tested case by case).

Note furthermore that a good recording quality is important in order to achieve a good recognition accuracy. In particular, background noise might reduce recognition accuracy. Thus, a microphone integrated in a notebook or a webcam might potentially lead to unsatisfying accuracy, while a headset or an external microphone that is well set up should lead to good accuracy. JustSayIt relying on the [Vosk Speech Recognition Toolkit], it is the latter that dictates the requirements on recording quality for good recognition accuracy (for more information, have a look at the subsection [accuracy](https://alphacephei.com/vosk/accuracy) on their website).


## Help on commands callable by voice
Saying "help commands" lists your available commands in the [Julia REPL] leading to, e.g., the following output:
```julia-repl
┌ Info:
│ Your commands:
│ copy      => ctrl + c
│ cut       => ctrl + x
│ double    => click_double
│ downwards => page_down
│ help      => help
│ ma        => click_left
│ middle    => click_middle
│ okay      => release_left
│ paste     => ctrl + v
│ redo      => ctrl + shift + z
│ right     => click_right
│ select    => press_left
│ triple    => click_triple
│ type      => type
│ undo      => ctrl + z
└ upwards   => page_up
```
Saying "help <command name>", where `<command name>` is to be replaced with one of the available commands, shows the help for the corresponding command. Here is, e.g., the output produced when saying "help help":
```julia-repl
[ Info: Starting command: help (latency: 6 ms)
┌ Info: Command help
│    =
│      help()
│    
└      Show help for your commands or a spoken command or module.
```
The [Software reference](@ref) lists the current built-in command modules and root-level entry points. For custom workflows, you can also define your own command mappings to Julia functions, keyboard shortcuts, or command sequences.


## Sleep and wake up by voice
Saying "sleep JustSayIt" puts JustSayIt to sleep. It will not execute any commands until it is awoken with the words "awake JustSayIt".


## Fast command programming with voice argument functions
JustSayIt commands map to regular Julia functions. Function arguments can be easily passed by voice thanks to the [`@voiceargs`](@ref) macro. It allows to declare arguments in standard function definitions to be directly obtainable by voice. It, furthermore, allows to define speech recognition parameters for each voice argument as, e.g., the valid speech input. The following shows some examples:

```julia
  @voiceargs (b, c) function f(a, b::String, c::String, d)
      #(...)
      return
  end
```
```julia
    @voiceargs (b=>(use_max_speed=true), c) function f(a, b::String, c::String, d)
        #(...)
        return
    end
```
```julia
    @enum TypeMode words formula
    @voiceargs (mode=>(valid_input_auto=true), token=>(model=MODELNAME.TYPE.EN_US, vararg_timeout=2.0)) function type_tokens(mode::TypeMode, tokens::String...)
        #(...)
        return
    end
```
Detailed information on [`@voiceargs`](@ref) is found in the [High-level API reference](@ref).

While contributions to the JustSayIt command modules are very much encouraged, it is possible to quickly define and use custom [`@voiceargs`](@ref) functions thanks to the API of JustSayIt ([`JustSayIt.API`](@ref)). It is illustrated in [this example](@ref Quick-definition-and-usage-of-custom-function). More information on the JustSayIt API is given in the [High-level API reference](@ref).

Note that the JustSayIt application config folder (e.g., `~/.config/JustSayIt` on Unix systems) is an easily accessible storage for scripts to start JustSayIt and/or for custom command functions: [`JustSayIt.@include`](@ref) and [`JustSayIt.@edit`](@ref) permit to conveniently `include` and `edit` files from this folder.


## Recorder setup and microphone choice
JustSayIt uses the default microphone unless you choose a different one explicitly. At startup it prints the selected input device together with the available devices, which makes it practical to switch to a better headset or external microphone when recognition quality is not good enough.

You can select a recorder by microphone name or by microphone id:
```julia
using JustSayIt
start(microphone_name="USB")
```

For stable setups, `microphone_name` is often more convenient than `microphone_id`, because ids can change between sessions. Advanced setups can also replace the live microphone with an external audio-input command through the `audio_input_cmd` keyword when the command outputs a compatible audio stream.


## Speech models and free-speech capture
On first use, JustSayIt automatically acquires the default speech models it needs for the selected command and typing languages. If you configure additional `type_languages`, the corresponding typing models are prepared as needed as part of the same setup workflow.

Command recognition and most [`@voiceargs`](@ref) interactions stay constrained to the current command set or to the declared valid input of the active voice argument. By contrast, [`listen`](@ref) is the auxiliary workflow for open-ended free-speech capture and returns the next spoken word group as plain text:
```julia
using JustSayIt
start(default_language="en-us", type_languages=["en-us", "fr"])
spoken_text = listen()
```

When your machine supports it, `use_gpu=true` enables the higher-performance local path used by the speech, TTS, and LLM stack. For lower-level speech-token helpers such as `next_wordgroup`, `next_letter`, or `next_digits`, use the [High-level API reference](@ref).


## Text-to-speech setup and control
Text-to-speech is enabled by default and can be configured at startup together with the audio output device. The `tts_async_default` keyword controls whether spoken output is asynchronous by default; synchronous playback is often the safer choice when you are not using headphones.

```julia
using JustSayIt
start(use_tts=true, tts_async_default=false, audiooutput_name="Speakers")

say("JustSayIt is ready.")
TTS.read()
TTS.pause()
TTS.resume()
TTS.stop()
```

`TTS.read()` reads the selected text, or falls back to the clipboard when nothing is selected. The root-level `say` helper is convenient for directly speaking strings, while `TTS.pause`, `TTS.resume`, `TTS.stop`, and `TTS.set_async_default` cover the user-facing playback controls.


## LLM-assisted workflows
LLM functionality is enabled with `use_llm=true`. Summary, translation, and text-aware answer workflows use the currently selected text first and otherwise fall back to the clipboard, which makes them fit naturally into normal desktop usage.

If no OpenAI API key preference is configured, JustSayIt uses a local runtime path and can prompt you to install Ollama or download a local model. If an API key preference is configured, the active remote model path is used instead.

```julia
using JustSayIt
start(use_llm=true, use_tts=true)

LLM.read_summary()
LLM.type_translation()
LLM.read_text_answer()
LLM.read_followup()
```

Use the `LLM.type_*` commands when the generated result should be inserted into the active application, and the `LLM.read_*` commands when it should be spoken aloud. `LLM.read_answer()` answers a spoken prompt directly, `LLM.read_text_answer()` answers with the current text selection or clipboard as context, and `LLM.read_followup()` or `LLM.chat_followup()` continue an earlier interaction.

For programming-facing direct queries and follow-up queries, see [`ask`](@ref), [`ask!`](@ref), and the corresponding entries in the [High-level API reference](@ref).
