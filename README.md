# JustSayIt

JustSayIt enables offline, low latency, highly accurate and secure speech to command translation on Linux, MacOS and Windows and is usable as software or API. It implements a **novel algorithm for high performance context dependent recognition of spoken commands** which leverages the [Vosk Speech Recognition Toolkit]. Single word commands' latency (referring to the time elapsed between a command is spoken and executed) can be little as 5 miliseconds and does usually not exceed 30 miliseconds (measured on a regular notebook).

Furthermore, JustSayIt provides an **unprecedented highly generic extension to the Julia programming language which allows to declare arguments in standard function definitions to be obtainable by voice**. For such functions, JustSayIt automatically generates a wrapper method that takes care of the complexity of retrieving the arguments from the speakers voice, including interpretation and conversion of the voice arguments to potentially any data type. JustSayIt commands are implemented with such *voice argument functions*, triggered by a user definable mapping of command names to functions. As a result, it empowers programmers without any knowledge of speech recognition to quickly write new commands that take their arguments from the speakers voice. **JustSayIt is ideally suited for development by the world-wide open source community**.

**JustSayIt unites the advantages of Julia and Python**: it leverages Julia's performance and metaprogramming capabilities and Python's larger ecosystem where no suitable Julia package is found - PyCall.jl makes calling Python packages from Julia trivial. JustSayIt embraces the vision "Why choose between Julia or Python? - Use both!".

Finally, JustSayIt puts a small load on the CPU, using only one core, and can therefore run continuously without harming the computer usage experience.

## Contents
* [Quick start](#quick-start)
* [User definable mapping of command names to functions](user-definable-mapping-of-command-names-to-functions)
* [Help on commands callable by voice](#help-on-commands-callable-by-voice)
* [Sleep and wake up by voice](#sleep-and-wake-up-by-voice)
* [Fast command programming with voice argument functions](#fast-command-programming-with-voice-argument-functions)
* [Module documentation callable from the Julia REPL / IJulia](#module-documentation-callable-from-the-julia-repl--ijulia)
* [Fully automatic installation](#fully-automatic-installation)
* [Support for Linux, MacOS and Windows](support-for-linux-macos-and-windows)
* [Dependencies](#Dependencies)
* [Your contributions](#your-contributions)

## Quick start
1. Install [Julia] if you do not have it yet.
2. Execute the following in your shell to install and run JustSayIt:
```julia-repl
$> julia
julia> ]
  pkg> add https://github.com/omlins/JustSayIt
  pkg> <backspace button>
julia> using JustSayIt
julia> just_say_it()
```
3. Say "help commands" and then, e.g., "help type".

## User definable mapping of command names to functions
The keyword `commands` of `just_say_it` enables to freely define a mapping of command names to functions, e.g.:
```julia-repl
# Define custom commands
using JustSayIt
commands = Dict("cat"    => Help.help,
                "dog"    => Keyboard.type,
                "mouse"  => Mouse.click_double,
                "monkey" => Mouse.click_triple,
                "zebra"  => Email.email,
                "snake"  => Internet.internet)
just_say_it(commands=commands)
```

The keyword `subset` of `just_say_it` enables to activate only a subset of the default or user-defined commands. The following example selects a subset of the default commands:
```julia-repl
# Listen to all default commands with exception of the mouse button commands.
using JustSayIt
just_say_it(subset=("help", "type", "email", "internet"))
```

More information on customization keywords is obtainable by typing `?just_say_it`.

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
[ Info: Starting command: help (latency: 83 ms)
┌ Info: Command email
│    =
│      email `inbox` | `outbox`
│    
│      Manage e-mails, performing one of the following actions:
│    
│        •  inbox
│    
└        •  outbox
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
  @voiceargs (b, c=>(use_max_accuracy=true)) function f(a, b::String, c::String, d)
      #(...)
      return
  end
```
```julia
  @enum TypeMode words formula
  @voiceargs (mode=>(valid_input_auto=true), token=>(model=TYPE_MODEL_NAME, use_max_accuracy=true, vararg_timeout=2.0)) function type_tokens(mode::TypeMode, tokens::String...)
      #(...)
      return
  end
```

## Module documentation callable from the Julia REPL / IJulia
The module documentation can be called from the [Julia REPL] or in [IJulia]:
```julia-repl
julia> using JustSayIt
julia>?
help?> JustSayIt
search: JustSayIt just_say_it

  Module JustSayIt

  Enables offline, low latency, highly accurate speech to command translation and is usable as software or API.

  (...)

  To see a description of a function, macro or module type ?<functionname>, ?<macroname> (including the @) or ?<modulename>, respectively.
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
