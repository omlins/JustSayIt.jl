"""
# Module API

Application Programming Interface (API) of JustSayIt.

#### Macros
- [`@voiceargs`](@ref)

#### Functions
- [`is_next`](@ref)
- [`are_next`](@ref)
- [`pause_recording`](@ref)
- [`restart_recording`](@ref)

#### Constants
- [`LANG`](@ref)
- [`MODELNAME`](@ref)

To see a description of a function, macro or module type `?<functionname>`, `?<macroname>` (including the `@`) or `?<modulename>`, respectively.
"""
module API
    import ..JustSayIt: @voiceargs, is_next, are_next, pause_recording, restart_recording, LANG, MODELNAME
    export @voiceargs, is_next, are_next, pause_recording, restart_recording, LANG, MODELNAME
end
