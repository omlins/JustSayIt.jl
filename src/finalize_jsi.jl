"""
    finalize_jsi()

Finalize the package JustSayIt.

See also: [`init_jsi`](@ref)
"""
function finalize_jsi()
    if !is_initialized() @warn "JustSayIt is not initialized. Nothing to finalize." return end
    finalize_devices()
    if (use_tts()) finalize_tts() end
    if (use_llm()) finalize_llm() end
    finalize_stt()
    finalize_streamer()
    finalize_recorder()
    finalize_reader()
    set_initialized(false)
    @info "JustSayIt: stopped listening for commands. Bye!"
    return
end
