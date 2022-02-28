"""
# Module API

Application Programming Interface (API) of JustSayIt.

#### Macros
- [`@voiceargs`](@ref)

#### Functions
- [`init_jsi`](@ref)
- [`finalize_jsi`](@ref)
- [`is_next`](@ref)
- [`are_next`](@ref)
- [`pause_recording`](@ref)
- [`restart_recording`](@ref)

To see a description of a function, macro or module type `?<functionname>`, `?<macroname>` (including the `@`) or `?<modulename>`, respectively.
"""
module API
    import ..JustSayIt: @voiceargs, init_jsi, finalize_jsi, is_next, are_next, pause_recording, restart_recording
    export @voiceargs, init_jsi, finalize_jsi, is_next, are_next, pause_recording, restart_recording
end
