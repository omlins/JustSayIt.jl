# JustSayIt

JustSayIt enables offline, low latency, highly accurate speech to command translation and is usable as software or API. It implements a **novel algorithm for high performance context dependent recognition of spoken commands** which leverages the [Vosk Speech Recognition Toolkit]. Single word commands' latency (referring to the time elapsed between a command is spoken and executed) can be little as 5 miliseconds and does usually not exceed 30 miliseconds (measured on a regular notebook).

Furthermore, JustSayIt provides an **unprecedented highly generic extension to the Julia programming language which allows to declare arguments in standard function definitions to be obtainable by voice**. For such functions, JustSayIt automatically generates a wrapper method that takes care of the complexity of retrieving the arguments from the speakers voice, including interpretation and conversion of the voice arguments to potentially any data type. JustSayIt commands are implemented with such *voice argument functions*, triggered by a user definable mapping of command names to functions. As a result, it empowers programmers without any knowledge of speech recognition to quickly write new commands that take their arguments from the speakers voice. **JustSayIt is ideally suited for development by the world-wide open source community**.

**JustSayIt unites the advantages of Julia and Python**: it leverages Julia's performance and metaprogramming capabilities and Python's large ecosystem where no suitable Julia package is found - PyCall.jl makes calling Python packages from Julia trivial. JustSayIt embraces the vision "Why choose between Julia or Python? - Use both!".

Finally, JustSayIt puts a small load on the CPU, using only one core, and can therefore run continuously without harming the computer usage experience.

## Contents
* [Voice argument functions](#voice-argument-functions)
* [Module documentation callable from the Julia REPL / IJulia](#module-documentation-callable-from-the-julia-repl--ijulia)
* [Help on commands callable by voice](#help-on-commands-callable-by-voice)
* [Sleep and wake up by voice](#sleep-and-wake-up-by-voice)
* [Dependencies](#dependencies)
* [Installation](#installation)
* [Your contributions](#your-contributions)

## Voice argument functions
The `@voiceargs` macro allows to declare arguments in standard function definitions to be obtainable by voice. It, furthermore, allows to define speech recognition parameters for each voice argument as, e.g., the valid speech input. The following shows some examples:
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

  General overview and examples
  ≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡

  https://github.com/omlins/JustSayIt.jl

  Software usage
  ≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡

  > julia
  julia> using JustSayIt
  julia> just_say_it()

  Type ?just_say_it to learn about customization keywords.

  Application Programming Interface (API)
  ≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡

  Macros
  --------

    •  @voiceargs

  Functions
  -----------

    •  just_say_it

    •  init_jsi

    •  finalize_jsi

    •  is_next

    •  pause_recording

    •  restart_recording

  Submodules
  ------------

    •  Help

    •  Keyboard

    •  Mouse

    •  Email

    •  Internet

  To see a description of a function, macro or module type ?<functionname>, ?<macroname> (including the @) or ?<modulename>, respectively.
```

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
Saying "help <command name>" shows the help of one of the available commands. Here is, e.g., the output produced when saying "help double":
```
┌ Info: Command double
└    =   Doubleclick left mouse button.
```

## Sleep and wake up by voice
Saying "sleep JustSayIt" puts JustSayIt to sleep. It will not execute any commands until it is awoken with the words "awake JustSayIt".

## Dependencies
JustSayIt's primary dependencies are [Vosk], [Pynput], [PyCall.jl], [Conda.jl] and [MacroTools.jl].

## Installation
JustSayIt can be installed directly with the [Julia package manager](https://docs.julialang.org/en/v1/stdlib/Pkg/index.html) from the REPL:
```julia-repl
julia>]
  pkg> add https://github.com/omlins/JustSayIt
```

## Your contributions
This project needs your contribution! There are a lot of commands for all different kind of operations to be programmed! Note that pull request should always address a significant issue in its completeness and new commands should be generic enough to be of interest for others. Please open an issue to discuss the addition of new features beforehand.



[Conda.jl]: https://github.com/JuliaPy/Conda.jl
[IJulia]: https://github.com/JuliaLang/IJulia.jl
[Julia REPL]: https://docs.julialang.org/en/v1/stdlib/REPL/
[MacroTools.jl]: https://github.com/FluxML/MacroTools.jl
[PyCall.jl]: https://github.com/JuliaPy/PyCall.jl
[Pynput]: https://github.com/moses-palmer/pynput
[Vosk]: https://github.com/alphacep/vosk-api
[Vosk Speech Recognition Toolkit]: https://alphacephei.com/vosk/
