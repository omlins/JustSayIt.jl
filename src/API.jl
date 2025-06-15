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
