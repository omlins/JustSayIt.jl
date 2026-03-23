"""
# Module API

Application Programming Interface (API) of JustSayIt.

#### Macros
- [`@voiceargs`](@ref)
- [`@voiceconfig`](@ref)
- [`@voiceinfo`](@ref)

#### Functions
- Lifecycle and device access: [`controller`](@ref), [`init_jsi`](@ref), [`finalize_jsi`](@ref), [`default_language`](@ref), [`type_languages`](@ref)
- Interpreters and STT helpers: [`interpret_enum`](@ref), [`interpret_digit`](@ref), [`interpret_count`](@ref), [`interpret_language`](@ref), [`next_wordgroup`](@ref), [`next_letter`](@ref), [`next_letters`](@ref), [`next_digit`](@ref), [`next_digits`](@ref), [`get_language`](@ref)
- Text access: [`get_selection_content`](@ref), [`get_clipboard_content`](@ref)
- TTS helpers: [`is_playing_tts`](@ref), [`pause_tts`](@ref), [`resume_tts`](@ref), [`stop_tts`](@ref), [`set_tts_async_default`](@ref), [`tts_async_default`](@ref)
- LLM helpers: [`ask_llm`](@ref), [`ask_llm!`](@ref)

#### Constants
- [`LANG`](@ref)
- [`LANG_AUTO`](@ref)
- [`MODELTYPE_DEFAULT`](@ref)
- [`MODELTYPE_SPEECH`](@ref)
- [`ALPHABET`](@ref)
- [`DIGITS`](@ref)
- [`COUNTS`](@ref)

To see a description of a function, macro or module type `?<functionname>`, `?<macroname>` (including the `@`) or `?<modulename>`, respectively.
"""
module API
    import ..JustSayIt: MODELTYPE_DEFAULT, MODELTYPE_SPEECH, LANG, LANG_AUTO, ALPHABET, DIGITS, COUNTS # from constants.jl
    export MODELTYPE_DEFAULT, MODELTYPE_SPEECH, LANG, LANG_AUTO, ALPHABET, DIGITS, COUNTS

    import ..JustSayIt: controller                                                   # from controller.jl
    export controller

    import ..JustSayIt: finalize_jsi                                                 # from finalize_jsi.jl
    export finalize_jsi

    import ..JustSayIt: init_jsi                                                     # from init_jsi.jl
    export init_jsi

    import ..JustSayIt: interpret_enum, interpret_digit, interpret_count, interpret_language # from interpreters.jl
    export interpret_enum, interpret_digit, interpret_count, interpret_language

    import ..JustSayIt: default_language, type_languages                             # from options.jl
    export default_language, type_languages

    import ..JustSayIt.LLMcore: ask_llm, ask_llm!                                    # from llm_api.jl
    export ask_llm, ask_llm!

    import ..JustSayIt: next_wordgroup, next_letter, next_letters, next_digit, next_digits, get_language  # from stt_api.jl
    export next_wordgroup, next_letter, next_letters, next_digit, next_digits, get_language
    
    import ..JustSayIt: get_selection_content, get_clipboard_content                 # from tools.jl
    export get_selection_content, get_clipboard_content
    
    import ..JustSayIt.TTScore: is_playing_tts, pause_tts, resume_tts, stop_tts, @voiceinfo  # from tts_api.jl (say is exported in JustSayIt.jl)
    export is_playing_tts, pause_tts, resume_tts, stop_tts, @voiceinfo

    import ..JustSayIt.TTScore: set_tts_async_default, tts_async_default             # from tts.jl
    export set_tts_async_default, tts_async_default

    import ..JustSayIt: @voiceargs, @voiceconfig                                     # from voiceargs.jl, voiceconfig.jl
    export @voiceargs, @voiceconfig

end
