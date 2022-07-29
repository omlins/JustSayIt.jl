# [JustSayIt.jl] [![Star on GitHub](https://img.shields.io/github/stars/omlins/JustSayIt.jl.svg)](https://github.com/omlins/JustSayIt.jl/stargazers)
JustSayIt enables offline, low latency, highly accurate and secure speech to command translation on Linux, MacOS and Windows and is usable as software or high-level API. It implements a **novel algorithm for high performance context dependent recognition of spoken commands** which leverages the [Vosk Speech Recognition Toolkit]. Single word commands' latency (referring to the time elapsed between a command is spoken and executed) can be little as 5 miliseconds and does usually not exceed 30 miliseconds (measured on a regular notebook).

Furthermore, JustSayIt provides an **unprecedented highly generic extension to the Julia programming language which allows to declare arguments in standard function definitions to be obtainable by voice**. For such functions, JustSayIt automatically generates a wrapper method that takes care of the complexity of retrieving the arguments from the speakers voice, including interpretation and conversion of the voice arguments to potentially any data type. JustSayIt commands are implemented with such *voice argument functions*, triggered by a user definable mapping of command names to functions. As a result, it empowers programmers without any knowledge of speech recognition to quickly write new commands that take their arguments from the speakers voice. **JustSayIt is ideally suited for development by the world-wide open source community**.

**JustSayIt unites the advantages of Julia and Python**: it leverages Julia's performance and metaprogramming capabilities and Python's larger ecosystem where no suitable Julia package is found - [PyCall.jl] makes calling Python packages from Julia trivial. JustSayIt embraces the vision "Why choose between Julia or Python? - Use both!".

Finally, JustSayIt puts a small load on the CPU, using only one core, and can therefore run continuously without harming the computer usage experience.

## Quick start
1\. Connect your best microphone (a good recording quality is key to a great voice control experience!)

2\. Install [Julia] if you do not have it yet.

3\. Execute the following in your shell to install and run JustSayIt:

```julia-repl
$> julia
julia> ]
  pkg> add JustSayIt.jl
  pkg> <backspace button>
julia> using JustSayIt
julia> start()
```

4\. Say "help commands" and then, e.g., "help type".

5\. Try some commands and then look through the rest of the documentation!

## Dependencies
JustSayIt's primary dependencies are [vosk], [sounddevice], [pynput], [PyCall.jl], [Conda.jl] and [MacroTools.jl].

## Support for Linux, MacOS and Windows
JustSayIt is programmed in a highly portable manner relying exclusively on portable Julia and Python modules (see [Dependencies](@ref)).

## Your contributions
This project needs your contribution! There are a lot of commands for all different kind of operations to be programmed! Note that pull request should always address a significant issue in its completeness and new commands should be generic enough to be of interest for others. Please open an issue to discuss the addition of new features beforehand.
[here](./assets/config_examples/config_custom_function.jl))
