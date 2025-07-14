"""
Module JustSayIt

Enables offline, low latency, highly accurate speech to command translation. It contains in addition an Application Programming Interface (API) for a fast and easy development of functionalities using speech-to-text (STT), text-to-speech (TTS) and large language models (LLMs).

# General overview and examples
https://github.com/omlins/JustSayIt.jl

# Software
```
> julia
julia> using JustSayIt
julia> start()
```
Type `?start` to learn about customization keywords.

# API

```
> julia
julia> import JustSayIt
julia> using JustSayIt.API
```
Type `?JustSayIt.API` to learn about the Application Programming Interface (API) of JustSayIt.
"""
module JustSayIt

## Imports
import Pkg, Downloads, ProgressMeter, Preferences
using PyCall, Conda, JSON, MacroTools
import MacroTools: splitdef, combinedef

## Include of exceptions submodule
include("Exceptions.jl"); using .Exceptions

## Include of global constants and macros
include("constants.jl")
include("types.jl")
include("macro_tools.jl")
include("voiceargs.jl")
include("voiceconfig.jl")

## Include of shared functionality
include("formatting.jl")
include("options.jl")
include("pymodules.jl")
include("tools.jl")

## Include of TTScore submodule (must be before other submodules as it is used there)
include("TTScore.jl"); using .TTScore

## Include of shared functionality using TTScore
include("audio_tools.jl")

## Alphabetical include of submodules, except commmand-submodules (below)
include("LLMcore.jl"); using .LLMcore

## Alphabetical include of files
include("commands.jl")
include("edit.jl")
include("devices.jl")
include("finalize_jsi.jl")
include("init_jsi.jl")
include("include.jl")
include("interpreters.jl")
include("preferences.jl")
include("reader.jl")
include("recorder.jl")
include("streamer.jl")
include("stt_api.jl")
include("stt_core.jl")
include("stt_models.jl")

## Include of API module (must be before Commands submodules as they import from it)
include("API.jl")

## Alphabetical include of command-submodules (must be at end as needs to import from JustSayIt
include("Commands/Clipboard.jl")
include("Commands/Generic.jl")
include("Commands/Help.jl")
include("Commands/LLM.jl")
include("Commands/Mouse.jl")
include("Commands/Selection.jl")
include("Commands/STT.jl")
include("Commands/TTS.jl")

# Include of command-submodules with dependencies on other command-submodules
include("Commands/Keyboard.jl") # (depends on STT.jl)

## Include of main application (must be at end as needs to import potentially anything available in JustSayIt, in particular the Commands submodules).
include("start.jl")

## Exports (need to be after include of submodules if re-exports from them)
export start
export Clipboard, Generic, Help, Keyboard, LLM, Mouse, Selection, STT, TTS
export Key
import .Clipboard.take, .Keyboard.type, .LLM.ask, .LLM.ask!, .Selection.grab, .STT.listen # Import not required: .TTS.say
export take, type, ask, ask!, grab, listen, say # NOTE: low-level 'say' (with kwargs) is exported here instead of TTS.say (cannot be exported here and in API.jl...)

## Public but not exported
public @edit, @include
public set_preferences!, load_preference, has_preference, delete_preferences!

end # module JustSayIt
