"""
Module JustSayIt

Enables offline, low latency, highly accurate speech to command translation and is usable as software or API.

# General overview and examples
https://github.com/omlins/JustSayIt.jl

# Software usage
```
> julia
julia> using JustSayIt
julia> start()
```
Type `?start` to learn about customization keywords.

# API usage

```
> julia
julia> import JustSayIt
julia> using JustSayIt.API
```
Type `?JustSayIt.API` to learn about the Application Programming Interface (API) of JustSayIt.
"""
module JustSayIt

## Alphabetical include of submodules, except commmand-submodules (below)
include("Exceptions.jl")
using .Exceptions

## Include of shared constant parameters, types and syntax sugar and voiceargs macro
include("shared.jl")
include("voiceargs.jl")

## Alphabetical include of files
include("finalize_jsi.jl")
include("next_token.jl")
include("init_jsi.jl")
include("recorder.jl")

## Include of command-submodules for peripherics control and help
include("Commands/Keyboard.jl")
include("Commands/Mouse.jl")
include("Commands/Help.jl")

## Alphabetical include of command-submodules (must be at end as needs to import from JustSayIt, .e.g. next_recognition, next_partial_recognition)
include("Commands/Email.jl")
include("Commands/Internet.jl")

## Include of main application and API (must be at end as needs to import potentially anything available in JustSayIt, in particular the Commands submodules).
include("start.jl")
include("API.jl")

## Exports (need to be after include of submodules if re-exports from them)
export start
export Keyboard, Mouse, Help, Email, Internet

end # module JustSayIt
