# [JustSayIt.jl] [![Star on GitHub](https://img.shields.io/github/stars/omlins/JustSayIt.jl.svg)](https://github.com/omlins/JustSayIt.jl/stargazers)
JustSayIt enables secure, offline, low-latency, highly accurate and secure speech to command translation for assembling personalized voice assistants on Linux, MacOS and Windows; it offers composable functionality using speech-to-text (STT), text-to-speech (TTS), large language models (LLMs) and more. It contains in addition an Application Programming Interface (API) for a fast and easy development of custom functions.

A key practical strength of JustSayIt is the possibility to define application-specific commands through command dictionaries, so voice interaction can be tailored precisely to concrete workflows in editors, notebooks, browsers, terminals, and other software. These commands can be LLM-assisted and TTS-enhanced whenever useful, enabling focused voice workflows with intelligent text generation, explanation, or spoken output without losing the structure of a personalized voice assistant.

It implements a **novel algorithm for high performance context dependent recognition of spoken commands** which leverages the [Vosk Speech Recognition Toolkit], while using a dual STT approach overall: [vosk] is used for constrained command recognition and a faster [Whisper]-based backend is used for free-speech recognition. Single word commands' latency on the command-recognition path (referring to the time elapsed between a command is spoken and executed) can be little as 5 miliseconds and does usually not exceed 30 miliseconds (measured on a regular notebook).

Furthermore, JustSayIt provides an **unprecedented highly generic extension to the Julia programming language which allows to declare arguments in standard function definitions to be obtainable by voice**. For such functions, JustSayIt automatically generates a wrapper method that takes care of the complexity of retrieving the arguments from the speakers voice, including interpretation and conversion of the voice arguments to potentially any data type. JustSayIt commands are implemented with such *voice argument functions*, triggered by a user definable mapping of command names to functions. As a result, it empowers programmers without any knowledge of speech recognition to quickly write new commands that take their arguments from the speakers voice. **JustSayIt is ideally suited for development by the world-wide open source community**.

**JustSayIt unites the advantages of Julia and Python**: it leverages Julia's performance and metaprogramming capabilities and Python's larger ecosystem where no suitable Julia package is found - [PyCall.jl] makes calling Python packages from Julia trivial. JustSayIt embraces the vision "Why choose between Julia or Python? - Use both!".

Finally, JustSayIt puts a small load on the CPU, using only one core, and can therefore run continuously without harming the computer usage experience.

## Quick start
1\. Connect your best microphone (a good recording quality is key to a great voice control experience!)

2\. Install [Julia] if you do not have it yet.

3\. Execute the following in your shell to install JustSayIt, copy one maintained recipe into your JustSayIt config folder, edit it, and run it:

```julia-repl
$> julia
julia> ]
  pkg> add JustSayIt, JustSayItRecipes
  pkg> <backspace button>
julia> using JustSayIt, JustSayItRecipes
julia> recipe = normpath(joinpath(dirname(pathof(JustSayItRecipes)), "..", "recipes", "ubuntu_max.jl"))
julia> local_recipe = joinpath(homedir(), ".config", "JustSayIt", "my_commands.jl")
julia> mkpath(dirname(local_recipe))
julia> cp(recipe, local_recipe; force=true)
julia> @edit("my_commands.jl")
julia> @include("my_commands.jl")
```

4\. Say `help commands` and then, e.g., `help sentence`, and try some commands following the guidance of the help output.

5\. Look through `my_commands.jl` itself to understand what commands are available and adjust them as desired.

6\. Look through the rest of the documentation!

This recipe-copy workflow is the basic practical way to use JustSayIt properly, and it remains the standard recommended workflow for advanced users too.

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
