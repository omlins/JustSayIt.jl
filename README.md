# JustSayIt

JustSayIt enables offline, low latency, highly accurate and secure speech to command translation on Linux, MacOS and Windows and is usable as software or API. It implements a **novel algorithm for high performance context dependent recognition of spoken commands** which leverages the [Vosk Speech Recognition Toolkit]. Single word commands' latency (referring to the time elapsed between a command is spoken and executed) can be little as 5 miliseconds and does usually not exceed 30 miliseconds (measured on a regular notebook).

Furthermore, JustSayIt provides an **unprecedented highly generic extension to the Julia programming language which allows to declare arguments in standard function definitions to be obtainable by voice**. For such functions, JustSayIt automatically generates a wrapper method that takes care of the complexity of retrieving the arguments from the speakers voice, including interpretation and conversion of the voice arguments to potentially any data type. JustSayIt commands are implemented with such *voice argument functions*, triggered by a user definable mapping of command names to functions. As a result, it empowers programmers without any knowledge of speech recognition to quickly write new commands that take their arguments from the speakers voice. **JustSayIt is ideally suited for development by the world-wide open source community**.

**JustSayIt unites the advantages of Julia and Python**: it leverages Julia's performance and metaprogramming capabilities and Python's larger ecosystem where no suitable Julia package is found - PyCall.jl makes calling Python packages from Julia trivial. JustSayIt embraces the vision "Why choose between Julia or Python? - Use both!".

Finally, JustSayIt puts a small load on the CPU, using only one core, and can therefore run continuously without harming the computer usage experience.

## Contents
* [Quick start](#quick-start)
* [User definable mapping of command names to functions or keyboard shortcuts](#user-definable-mapping-of-command-names-to-functions-or-keyboard-shortcuts)
* [Help on commands callable by voice](#help-on-commands-callable-by-voice)
* [Sleep and wake up by voice](#sleep-and-wake-up-by-voice)
* [Fast command programming with voice argument functions](#fast-command-programming-with-voice-argument-functions)
* [Module documentation callable from the Julia REPL / IJulia](#module-documentation-callable-from-the-julia-repl--ijulia)
* [Fully automatic installation](#fully-automatic-installation)
* [Support for Linux, MacOS and Windows](#support-for-linux-macos-and-windows)
* [Dependencies](#dependencies)
* [Your contributions](#your-contributions)

## Quick start
1. Install [Julia] if you do not have it yet.
2. Connect your best microphone (a good recording quality is key to a great voice control experience!)
3. Execute the following in your shell to install and run JustSayIt:
```julia-repl
$> julia
julia> ]
  pkg> add https://github.com/omlins/JustSayIt
  pkg> <backspace button>
julia> using JustSayIt
julia> start()
```
4. Say "help commands" and then, e.g., "help type".
5. Try some commands and then look through the documentation!

## User definable mapping of command names to functions or keyboard shortcuts
The keyword `commands` of `start` enables to freely define a mapping of command names to functions or keyboard shortcuts, e.g.:
```julia-repl
# Define custom commands
using JustSayIt
commands = Dict("help"      => Help.help,
                "type"      => Keyboard.type,
                "email"     => Email.email,
                "internet"  => Internet.internet,
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
start(commands=commands)
```
Note that keyboard shortcuts are given as either single keys (e.g., `Key.page_up`) or tuples of keys (e.g., `(Key.ctrl, 'c')`). Special keys are selected from those available in `Key`: type `Key.`+ `tab` to see the available keys (the full documentation on the available keys is available [here](https://pynput.readthedocs.io/en/latest/keyboard.html#pynput.keyboard.Key)). Character keys are simply given in single quotes (e.g., `'c'`).

The keyword `subset` of `start` enables to activate only a subset of the default or user-defined commands. The following example selects a subset of the default commands:
```julia-repl
# Listen to all default commands with exception of the mouse button commands.
using JustSayIt
start(subset=["help", "type", "email", "internet"])
```

More information on customization keywords is obtainable by typing `?start`.

## Per command choice between maximum speed or accuracy

The keyword `max_speed_subset` of `start` enables to define a subset of the `commands` for which the command names are to be recognised with maxium speed rather than with maximum accuracy, e.g.:
```julia-repl
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
Saying "help commands" lists your available commands in the Julia REPL leading to, e.g., the following output:
```julia-repl
┌ Info:
│ Your commands:
│ double   => click_double
│ email    => email
│ help     => help
│ internet => internet
│ ma       => click_left
│ middle   => click_middle
│ okay     => release_left
│ right    => click_right
│ select   => press_left
│ triple   => click_triple
└ type     => type
```
Saying "help <command name>" shows the help of one of the available commands. Here is, e.g., the output produced when saying "help email":
```
[ Info: Starting command: help (latency: 6 ms)
┌ Info: Command email
│    =
│      email `inbox` | `outbox`
│    
│      Manage e-mails, performing one of the following actions:
│    
│        •  open inbox
│    
└        •  open outbox
```
Note that the submodules `Email` and `Internet` contain still very little functionality. Yet, they illustrate how submodules for all kind of operations can be programmed.

## Sleep and wake up by voice
Saying "sleep JustSayIt" puts JustSayIt to sleep. It will not execute any commands until it is awoken with the words "awake JustSayIt".

## Fast command programming with voice argument functions
JustSayIt commands map to regular Julia functions. Function arguments can be easily passed by voice thanks to the `@voiceargs` macro. It allows to declare arguments in standard function definitions to be directly obtainable by voice. It, furthermore, allows to define speech recognition parameters for each voice argument as, e.g., the valid speech input. The following shows some examples:

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
    @voiceargs (mode=>(valid_input_auto=true), token=>(model=TYPE_MODEL_NAME, vararg_timeout=2.0)) function type_tokens(mode::TypeMode, tokens::String...)
        #(...)
        return
    end
```
Detailed information on `@voiceargs` is obtainable by typing `?@voiceargs`.

While contributions to the JustSayIt command modules are very much encouraged, it is possible to quickly define and use custom `@voiceargs` functions thanks to the API of JustSayIt (`JustSayIt.API`). The following example shows how 1) a weather forecast search function (`weather`) can be programmed, 2) a command name to function mapping defined, and then 3) JustSayIt started using these customly defined commands. The command `weather` programmed here allows to find out how the weather is `today` or `tomorrow` - just say "weather today" or "weather tomorrow". Furthermore, if you say "help weather", it will show in the Julia REPL the function documentation written here. To run this example, type in the Julia REPL `include("path-to-file")` or simply copy-paste the code below inside (the corresponding file can be found [here](config_examples/config_custom_function.jl)).

```julia
using JustSayIt
using JustSayIt.API       # Import JustSayIt API to write @voicearg functions
using DefaultApplication  # To install type: `]` and then `add DefaultApplication`

# 1) Define a custom weather forecast search function.
@doc """
    weather `today` | `tomorrow`

Find out how the weather is `today` or `tomorrow`.
"""
weather
@enum Day today tomorrow
@voiceargs day=>(valid_input_auto=true, use_max_accuracy=true) function weather(day::Day)
    DefaultApplication.open("https://www.google.com/search?q=weather+$day")
end

# 2) Define command name to function mapping, calling custom function
commands = Dict("help"      => Help.help,
                "weather"   => weather,
                );

# 3) Start JustSayIt with the custom commands.
start(commands=commands)
```
More information on the JustSayIt API is obtainable by typing `?JustSayIt.API`.

Note that the JustSayIt application config folder (e.g., `~/.config/JustSayIt` on Unix systems) is an easily accessible storage for scripts to start JustSayIt and/or for custom command functions: `@include_config` permits to conveniently `include` files from this folder. More information is obtainable by typing `?@include_config`.

## Module documentation callable from the Julia REPL / IJulia
The module documentation can be called from the [Julia REPL] or in [IJulia]:
```julia-repl
julia> using JustSayIt
julia>?
help?> JustSayIt
search: JustSayIt start

  Module JustSayIt

  Enables offline, low latency, highly accurate speech to command translation and is usable as software or API.

  (...)
```

## Fully automatic installation
After installing [Julia] - if not yet installed - JustSayIt can be installed directly with the [Julia package manager](https://docs.julialang.org/en/v1/stdlib/Pkg/index.html) from the [Julia REPL]:
```julia-repl
julia>]
  pkg> add https://github.com/omlins/JustSayIt
```
All dependencies are automatically installed. Python dependencies are automatically installed in a local mini-conda environment, set up by [Conda.jl]. Default language models are automatically downloaded at first usage of JustSayIt.

## Support for Linux, MacOS and Windows
JustSayIt is programmed in a highly portable manner relying exclusively on portable Julia and Python modules (see [Dependencies](#dependencies)).

## Dependencies
JustSayIt's primary dependencies are [vosk], [sounddevice], [pynput], [PyCall.jl], [Conda.jl] and [MacroTools.jl].

## Your contributions
This project needs your contribution! There are a lot of commands for all different kind of operations to be programmed! Note that pull request should always address a significant issue in its completeness and new commands should be generic enough to be of interest for others. Please open an issue to discuss the addition of new features beforehand.



[Conda.jl]: https://github.com/JuliaPy/Conda.jl
[IJulia]: https://github.com/JuliaLang/IJulia.jl
[Julia]: https://julialang.org
[Julia REPL]: https://docs.julialang.org/en/v1/stdlib/REPL/
[MacroTools.jl]: https://github.com/FluxML/MacroTools.jl
[PyCall.jl]: https://github.com/JuliaPy/PyCall.jl
[pynput]: https://github.com/moses-palmer/pynput
[sounddevice]: https://github.com/spatialaudio/python-sounddevice
[vosk]: https://github.com/alphacep/vosk-api
[Vosk Speech Recognition Toolkit]: https://alphacephei.com/vosk/
