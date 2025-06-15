let
    global is_initialized, set_initialized, default_language, set_default_language, type_languages, set_type_languages, use_gpu, set_use_gpu, use_tts, set_use_tts, use_llm, set_use_llm, do_perf_debug, set_perf_debug
    _is_initialized::Bool                            = false
    _default_language::String                        = ""
    _type_languages::AbstractArray{String}           = String[]
    _use_gpu::Bool                                   = false
    _use_tts::Bool                                   = false
    _use_llm::Bool                                   = false
    _do_perf_debug::Bool                             = false
    is_initialized()::Bool                           = _is_initialized
    set_initialized(val::Bool)                       = _is_initialized = val
    default_language()                               = _default_language
    set_default_language(lang::AbstractString)       = if (lang in LANG) _default_language = lang; else @ArgumentError("The language $lang is not supported. Supported languages are: $(LANG)."); end
    type_languages()                                 = _type_languages
    set_type_languages(langs::AbstractArray{String}) = if all(l in LANG for l in langs) _type_languages = langs; else @ArgumentError("The languages $(langs) are not supported. Supported languages are: $(LANG)."); end
    use_gpu()::Bool                                  = _use_gpu
    set_use_gpu(val::Bool)                           = _use_gpu = val
    use_tts()::Bool                                  = _use_tts
    set_use_tts(val::Bool)                           = _use_tts = val
    use_llm()::Bool                                  = _use_llm
    set_use_llm(val::Bool)                           = _use_llm = val
    do_perf_debug()::Bool                            = _do_perf_debug
    set_perf_debug()                                 = if haskey(ENV,"JSI_PERF_DEBUG") _do_perf_debug = (parse(Int64,ENV["JSI_PERF_DEBUG"]) > 0); end
end