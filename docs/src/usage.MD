# Usage

## Fully automatic installation
After installing [Julia] - if not yet installed - JustSayIt can be installed directly with the [Julia package manager] from the [Julia REPL]:
```julia-repl
julia>]
  pkg> add JustSayIt
```
All dependencies are automatically installed (on some systems, the fully automatic installation might not work, and some manual installations are required). Python dependencies are automatically installed in a local Miniconda environment, set up by [Conda.jl]. Default speech-to-text, text-to-speech and large language models are acquired automatically at first use.


## Fast microphone and recorder setup
At startup, JustSayIt prints the available audio devices. In many setups the defaults are good enough, but you can also select devices explicitly:

```julia
using JustSayIt

start(microphone_name="USB", audiooutput_name="Headphones")
```

In practice, a headset or a well-positioned external microphone usually gives much better command recognition than a notebook microphone. Headphones are strongly recommended when you use asynchronous TTS, because spoken output can otherwise trigger commands by accident.


## Easy basic software usage
If you launch JustSayIt without passing a command dictionary, `start()` uses the default command dictionary, which contains only the "help" command. This is a good starting point to confirm that JustSayIt is listening and that spoken help works before moving on to an actual useful command set. To test that, just run:

```julia-repl
$> julia
julia> using JustSayIt
julia> start()
```

If you then say `help commands`, the following is printed in the terminal:

```text
[ Info: Starting command: help
┌ Info: 
│ Your commands:
└ help => help
```

The next step is to define your own top-level command dictionary. If you want spoken help to remain available there as well, add the language-appropriate help command explicitly.

One small flat command dictionary can then serve as a first illustrative example:

```julia
using JustSayIt

commands = Dict(
    "help"      => Help.help,
    "sentence"  => Keyboard.type_sentence,
    "answer"    => LLM.read_answer,
    "read this" => TTS.read,
    "stop"      => TTS.stop,
)

start(commands=commands)
```

This already gives you speech typing, one LLM-assisted workflow, spoken output, and spoken help, without introducing keyboard shortcuts, command sequences, or nested command dictionaries.

It is still only an illustrative example. For actual day-to-day use, start from a recipe as shown in the quick start, run that file, and adapt it to your own applications and workflows.

More information on customization keywords of [`start`](@ref) is given in the following sections and in the [Software reference](@ref).


## Incremental command-dictionary assembly
Command dictionaries are the main way to assemble personalized voice assistants with JustSayIt.

A command name can map to a Julia function, a key or keyboard shortcut, a string to type literally, a command sequence stored as an array, or another command dictionary.

The recommended place to start from is [JustSayItRecipes.jl](https://github.com/omlins/JustSayItRecipes.jl), the official repository of shared command-dictionary recipes.


## Command-name mappings to functions, shortcuts, and sequences
The keyword `commands` of [`start`](@ref) lets you define a mapping of command names to functions, keyboard shortcuts, literal strings, or sequences of those:

```julia
using JustSayIt

commands = Dict(
    "help"      => Help.help,
    "sentence"  => Keyboard.type_sentence,
    "copy"      => (Key.ctrl, 'c'),
    "paste"     => (Key.ctrl, 'v'),
    "take word" => [Mouse.click_double, (Key.ctrl, 'c')],
    "replace"   => [Mouse.click_double, (Key.ctrl, 'v')],
)

start(commands=commands)
```

Note that keyboard shortcuts are given as either single keys (e.g., `Key.page_up`) or tuples of keys (e.g., `(Key.ctrl, 'c')`). Special keys are selected from those available in `Key`: type `Key.`+ `tab` in the [Julia REPL] to see the available keys (the full documentation on the available keys is available [here](https://pynput.readthedocs.io/en/latest/keyboard.html#pynput.keyboard.Key)). Character keys are simply given in single quotes (e.g., `'c'`).

A mapping target can also be an array whose elements are functions, strings, shell commands, or keyboard shortcuts. This is a practical way to express a small multi-step action without writing a wrapper function.


## Application-specific command assemblies
Once one application needs its own vocabulary, keep a reusable base dictionary and merge it into a nested application-specific dictionary:

```julia
using JustSayIt

base_commands = Dict(
    "sentence"  => Keyboard.type_sentence,
    "summarize" => LLM.read_summary,
    "read this" => TTS.read,
)

coding_commands = merge(
    base_commands,
    Dict(
        "comment"          => (Key.ctrl, '/'),
        "format selection" => [(Key.ctrl, 'k'), (Key.ctrl, 'f')],
        "workspace search" => (Key.ctrl, Key.shift, 'f'),
    ),
)

commands = Dict(
    "help"   => Help.help,
    "coding" => [`code`, coding_commands],
)

start(commands=commands)
```

Saying `coding` focuses or starts the application and activates the nested command dictionary. This pattern scales well for browser, editor, chat, or terminal specific vocabularies. See the [larger application-specific example](examples/application_specific_commands.MD) for a fuller version and consult JustSayItRecipes.jl for larger maintained assemblies.


## Maximum-speed command selection
The keyword `max_speed_subset` of [`start`](@ref) lets you define a subset of command names that should be recognized with maximum speed rather than maximum confirmation latency:

```julia
using JustSayIt

commands = Dict(
    "help"      => Help.help,
    "copy"      => (Key.ctrl, 'c'),
    "cut"       => (Key.ctrl, 'x'),
    "paste"     => (Key.ctrl, 'v'),
    "undo"      => (Key.ctrl, 'z'),
    "redo"      => (Key.ctrl, Key.shift, 'z'),
    "upwards"   => Key.page_up,
    "downwards" => Key.page_down,
)

start(commands=commands, max_speed_subset=["copy", "upwards", "downwards"])
```

This is best reserved for short, distinctive, low-risk commands that should trigger immediately. Leave destructive or easy-to-confuse commands such as `cut`, `paste`, `undo`, or `redo` out of the maximum-speed subset.

Note furthermore that a good recording quality is important in order to achieve a good recognition accuracy. In particular, background noise might reduce recognition accuracy. Thus, a microphone integrated in a notebook or a webcam might potentially lead to unsatisfying accuracy, while a headset or an external microphone that is well set up should lead to good accuracy. JustSayIt relying on the [Vosk Speech Recognition Toolkit], it is the latter that dictates the requirements on recording quality for good recognition accuracy (for more information, have a look at the subsection [accuracy](https://alphacephei.com/vosk/accuracy) on their website).


## Spoken help
The `Help.help` function is a built-in command that is recommended to be included in the top-level command dictionary in order to have spoken help available. Assuming that is mapped with `"help" => Help.help`, then saying `help commands` lists the currently active commands in the [Julia REPL]. Saying `help <command name>` shows the help for the corresponding command. 


## Sleep and wake control by voice
Saying `sleep JustSayIt` puts JustSayIt to sleep. It will not execute commands until you wake it up again with `awake JustSayIt`.


## Speech typing
Use the `Keyboard.type_*` family when the command itself should capture text from speech.

Typical mappings are for example:

```julia
using JustSayIt

commands = Dict(
    "help"         => Help.help,
    "sentence"     => Keyboard.type_sentence,
    "continuation" => Keyboard.type_sentence_lowercase,
    "spell"        => Keyboard.type_letters,
    "digits"       => Keyboard.type_digits,
    "camel case"   => Keyboard.type_camelcase,
)

start(commands=commands)
```

Use the root `type` primitive when you already have text and simply want to type it into the active application. Use the `Keyboard.type_*` family when speech itself should provide the text.


## Free-speech capture
The default speech models are acquired automatically when needed.

For most practical workflows, the predefined typing commands such as `Keyboard.type_sentence`, `Keyboard.type_letters`, or `Keyboard.type_digits` are the most convenient speech-input entry points.

When you need dictated text outside those fixed command patterns, the root `listen` primitive is the software-facing entry point for free-speech capture. For lower-level programming-facing capture helpers such as `next_wordgroup`, `next_letter`, or `next_digits`, see the [High-level API reference](@ref).


## TTS output and control
Text-to-speech is enabled by default. You can select a specific output device with `audiooutput_id` or `audiooutput_name`, and you can decide whether speech should normally be synchronous or asynchronous.

The software-facing TTS commands stay simple:

```julia
using JustSayIt

commands = Dict(
    "help"      => Help.help,
    "read this" => TTS.read,
    "pause"     => TTS.pause,
    "resume"    => TTS.resume,
    "stop"      => TTS.stop,
    "talk mode" => TTS.set_async_default,
)

start(commands=commands)
```

`TTS.read` reads the selected text or, if there is no selection, the clipboard text. The root `say` primitive is the natural spoken-output end of a composed command once you already have text that should be read aloud.


## Deterministic voice control with LLM-assisted commands
LLM integration is best treated as help for text transformation or question answering, while system operations themselves stay under deterministic command control.

At first use, JustSayIt prepares the local runtime it needs and automatically downloads the models it uses.

A few representative top-level mappings are for example:

- `"summarize" => LLM.read_summary`
- `"type summary" => LLM.type_summary`
- `"answer" => LLM.read_text_answer`
- `"direct answer" => LLM.read_answer`
- `"followup" => LLM.read_followup`

These are only examples of predefined generic LLM commands, not a complete overview of the available functionality.

The more important pattern in practice is the definition of application-specific LLM-assisted commands. The JuliaCon 2025 talk used the following Jupyter notebook example:

```julia
jupyter_llm_commands = Dict(
    "generate magic" => () -> LLM.type_answer(
        instruction_prefix="Generate the appropriate IPython magic command for the following task using proper syntax (%line magic or %%cell magic) with necessary options:"
    ),
    "explain cell" => () -> LLM.type_text_answer_to(
        "Explain what the selected cell code does in simple terms. Include key functions, algorithms, and data transformations. Format as markdown with clear section headings."
    ),
    "parallelize code" => () -> LLM.type_text_answer_to(
        "Convert the selected code to use parallel processing. Use appropriate IPython magic commands (%%px, %%parallel) and add necessary setup. Return only the parallelized code with essential comments."
    ),
    "visualize data" => () -> LLM.type_text_answer_to(
        "Generate visualization code for the selected data/variables. Choose appropriate plotting libraries and create informative visualizations. Use %matplotlib inline for display. Return only executable code."
    ),
)
```

Here `LLM.type_answer` takes the spoken task after the command name and prepends a fixed instruction prefix, while `LLM.type_text_answer_to` works on selected text or clipboard text directly. That is the pattern to put in the center: define application-specific LLM-assisted commands that match the way you actually work. See [Jupyter notebook LLM-assisted commands](examples/jupyter_llm_commands.MD) for a runnable version of the same slide-based example.


## Custom voice functions with @voiceargs
JustSayIt commands map to regular Julia functions. Function arguments can be obtained by voice with [`@voiceargs`](@ref), so custom functions can join the same command dictionaries as the predefined commands.

Here are some representative patterns:

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
@enum Day today tomorrow

@voiceargs day=>(valid_input_auto=true) function weather(day::Day)
    #(...)
    return
end
```

Detailed information on [`@voiceargs`](@ref) is found in the [High-level API reference](@ref).

[`@voiceconfig`](@ref) complements `@voiceargs` when you want to apply shared recognition settings to a call or to a function symbol without rewriting the function declaration itself.

The smallest complete end-to-end example is shown in [Quick definition and usage of custom function](examples/config_custom_function.MD). For larger assemblies built around command dictionaries, see [Application-specific command dictionaries](examples/application_specific_commands.MD), [Jupyter notebook LLM-assisted commands](examples/jupyter_llm_commands.MD), and then continue with JustSayItRecipes.jl.

Note that the JustSayIt application config folder (e.g., `~/.config/JustSayIt` on Unix systems) is an easily accessible storage for scripts to start JustSayIt and/or for custom command functions: [`JustSayIt.@include`](@ref) and [`JustSayIt.@edit`](@ref) permit to conveniently `include` and `edit` files from this folder.
