# [JustSayIt.jl] [![Star on GitHub](https://img.shields.io/github/stars/omlins/JustSayIt.jl.svg)](https://github.com/omlins/JustSayIt.jl/stargazers)
JustSayIt enables secure, offline, low-latency, highly accurate and secure speech to command translation for assembling personalized voice assistants on Linux, MacOS and Windows; it offers composable functionality using speech-to-text (STT), text-to-speech (TTS), large language models (LLMs) and more. It contains in addition an Application Programming Interface (API) for a fast and easy development of custom functions.

A key practical strength of JustSayIt is the possibility to define application-specific commands through command dictionaries, so voice interaction can be tailored precisely to concrete workflows in editors, notebooks, browsers, terminals, and other software. These commands can be LLM-assisted and TTS-enhanced whenever useful, enabling focused voice workflows with intelligent text generation, explanation, or spoken output without losing the structure of a personalized voice assistant.

It implements a **novel algorithm for high performance context dependent recognition of spoken commands** which leverages the [Vosk Speech Recognition Toolkit], while using a dual STT approach overall: [vosk] is used for constrained command recognition and a faster [Whisper]-based backend is used for free-speech recognition. Single word commands' latency on the command-recognition path (referring to the time elapsed between a command is spoken and executed) can be little as 5 miliseconds and does usually not exceed 30 miliseconds (measured on a regular notebook).

Furthermore, JustSayIt provides an **unprecedented highly generic extension to the Julia programming language which allows to declare arguments in standard function definitions to be obtainable by voice**. For such functions, JustSayIt automatically generates a wrapper method that takes care of the complexity of retrieving the arguments from the speakers voice, including interpretation and conversion of the voice arguments to potentially any data type. JustSayIt commands are implemented with such *voice argument functions*, triggered by a user definable mapping of command names to functions. As a result, it empowers programmers without any knowledge of speech recognition to quickly write new commands that take their arguments from the speakers voice. **JustSayIt is ideally suited for development by the world-wide open source community**.

**JustSayIt unites the advantages of Julia and Python**: it leverages Julia's performance and metaprogramming capabilities and Python's larger ecosystem where no suitable Julia package is found - [PyCall.jl] makes calling Python packages from Julia trivial. JustSayIt embraces the vision "Why choose between Julia or Python? - Use both!".

Finally, JustSayIt puts a small load on the CPU, using only one core, and can therefore run continuously without harming the computer usage experience.

## Quick start
1\. Connect your best microphone - a good recording quality is key to a great voice control experience!

2\. Install [Julia] if you do not have it yet.

> [!WARNING]
> The latest Julia version is not yet supported: currently, Julia 1.11 and 1.12 are verified to work with JustSayIt, while the newest release (currently Julia 1.13) is not yet supported - on all operating systems. With `juliaup`, the correct release can be selected using `juliaup add 1.12` and `juliaup default 1.12`.
> If you are on Windows, note that some non-Julia (Python and Conda) dependencies might currently need to be added manually before installing JustSayIt - see the section "Fully automatic installation" on the "Usage" page of this documentation for the corresponding pre-installation command.

3\. Execute the following in your shell to install JustSayIt and JustSayItRecipes (providing maintained command dictionaries) - installing JustSayItRecipes in development mode to enable editing of recipes (and later contributing back to the JustSayItRecipes repository) -, and to start a maintained recipe from JustSayItRecipes:
```julia-repl
$> julia
julia> ]
  pkg> add JustSayIt
  pkg> develop JustSayItRecipes
  pkg> <backspace button>
julia> using JustSayIt, JustSayItRecipes
julia> JustSayItRecipes.@run("en/essential.jl")
```

> [!NOTE]
> JustSayItRecipes is installed in development mode (typically in the `~/.julia/dev/` directory on Linux and macOS, and in the `~\AppData\Local\Julia\dev\` directory on Windows). Type `?Pkg.develop` for details, and set the environment variable `JULIA_PKG_DEVDIR` before starting Julia to use a custom location for the Julia development folder, where JustSayItRecipes will be installed.

4\. Say `help commands` and then, e.g., `help sentence`, and try some commands following the guidance of the help output. Stop the JustSayIt session with `CTRL-C` as indicated in the help output of JustSayIt. To better understand what commands are available and how to modify or extend them, start by looking through the recipe `en/essential.jl`: type simply `JustSayItRecipes.@edit("en/essential.jl")` in the Julia REPL. This is an English ("en") top-level recipe that includes other sub-recipes organized in a tree structure (in sub-folders) - we always start JustSayIt with a top-level recipe like `en/essential.jl`. Sub-recipes are included with statements like `@include("tts/tts_cmds")`, where `tts/tts_cmds` is a sub-recipe in the `tts` sub-folder of the `en` folder, which contains English text-to-speech (TTS) commands. So if you want to understand better what English TTS commands are available or modify or extend them, just open the sub-recipe `en/tts/tts_cmds.jl` with `JustSayItRecipes.@edit("en/tts/tts_cmds.jl")`. 
> [!TIP]
> Type `?edit` to learn how to specify a custom editor to be used for file editing in Julia.

5\. Duplicate the top-level recipe in the local JustSayItRecipes folder and edit it: e.g., add some commands that trigger keyboard shortcuts for common operations by first adding `common_operations_cmds = @include("common/common_operations_cmds")` and then adding `common_operations_cmds` into `commands = merge(...)` (`en/essential_plus_common.jl` shows how to do this, if you have doubts). Then, run it, say `help commands` and, e.g., `help search screen`, and test the new commands (restart Julia first to avoid redefining commands):
```julia-repl
julia> cp(JustSayItRecipes.@path("en/essential.jl"), JustSayItRecipes.@path("my_essential.jl"))
julia> JustSayItRecipes.@edit("my_essential.jl")
julia> <CTRL-D>
$> julia
julia> using JustSayIt, JustSayItRecipes
julia> JustSayItRecipes.@run("my_essential.jl")
```

6\. Include your own sub-recipes in your top-level recipe and/or modify existing sub-recipes and share them with the community by contributing back to the JustSayItRecipes repository! See the [Your contributions](@ref) section for more information.
> [!TIP]
> Contributing your changes to existing recipes back to the JustSayItRecipes repository will also allow you to easily keep your local modifications in sync with updates in the remote JustSayItRecipes repository, i.e., allowing you to straightforwardly benefit from further improvements made by other contributors.

7\. Look through the rest of the documentation!

This recipe-copy-modify workflow is the basic practical way to use JustSayIt properly, and it remains the standard recommended workflow for advanced users too.

## Dependencies
JustSayIt combines Julia metaprogramming with selected Python packages and local AI runtimes. The current stack centers on constrained command recognition via [vosk], free-speech recognition via a faster [Whisper]-based backend, text-to-speech, desktop control via [pynput] and [sounddevice], and local LLM interaction via [PromptingTools.jl] and [Ollama], with [PyCall.jl] and [Conda.jl] bridging the Python side where needed.

## Support for Linux, MacOS and Windows
JustSayIt is programmed in a highly portable manner relying exclusively on portable Julia and Python modules (see [Dependencies](@ref)).

## Your contributions
The only limit to the commands that can be defined with JustSayIt is your imagination! 
The primary contribution path is [JustSayItRecipes.jl](https://github.com/omlins/JustSayItRecipes.jl), the shared collection of command dictionaries for assembling personalized voice assistants with JustSayIt.jl. Useful contributions there are not limited to programming: improved application-specific dictionaries, new command definitions, cross-platform adaptations, better organization of existing command sets, and clearer recipe comments or explanations are all valuable. 
If you want to contribute broader functionality to JustSayIt.jl itself, please open an issue first to discuss the idea and scope. Pull requests should address a meaningful issue in its completeness and blend cleanly into the existing project; common sense is the primary guide in this regard (community guideline documents, e.g. [ColPrac](https://github.com/SciML/ColPrac) can be used for inspiration).
We are looking forward to your contribution!

## Contributors
The principal contributors to [JustSayIt.jl] have been so far (ordered by the significance of the relative contributions):
- Dr. Samuel Omlin ([@omlins](https://github.com/omlins)), Swiss National Supercomputing Centre (CSCS), ETH Zurich
