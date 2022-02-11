"""
Module JustSayIt

Enables offline, low latency, highly accurate speech to command translation and is usable as software or API.

# General overview and examples
https://github.com/omlins/JustSayIt.jl

# Software usage
```
> julia
julia> using JustSayIt
julia> just_say_it()
```
Type `?just_say_it` to learn about customization keywords.

# Application Programming Interface (API)

#### Macros
- [`@voiceargs`](@ref)

#### Functions
- [`just_say_it`](@ref)
- [`init_jsi`](@ref)
- [`finalize_jsi`](@ref)
- [`is_next`](@ref)
- [`are_next`](@ref)
- [`pause_recording`](@ref)
- [`restart_recording`](@ref)

#### Submodules
- [`Help`](@ref)
- [`Keyboard`](@ref)
- [`Mouse`](@ref)
- [`Email`](@ref)
- [`Internet`](@ref)

To see a description of a function, macro or module type `?<functionname>`, `?<macroname>` (including the `@`) or `?<modulename>`, respectively.
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

## Include of main application (must be at end as needs to import potentially anything available in JustSayIt, in particular the Commands submodule).
include("just_say_it.jl")

## Exports (need to be after include of submodules if re-exports from them)
export just_say_it
export @voiceargs
export init_jsi, finalize_jsi, is_next, are_next, pause_recording, restart_recording
export Keyboard, Mouse, Help, Email, Internet

end # module JustSayIt
