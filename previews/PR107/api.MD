```@meta
CurrentModule = JustSayIt
```

# High-level API reference

This is the official High-level API reference of `JustSayIt`. Note that it can also be queried interactively from the [Julia REPL] using the [help mode](https://docs.julialang.org/en/v1/stdlib/REPL/#Help-mode):
```julia-repl
julia> using JustSayIt
julia>?
help?> JustSayIt.API
```

## Submodule
```@docs
JustSayIt.API
```

## Macros
#### Index
* [`JustSayIt.API.@voiceargs`](@ref)
* [`JustSayIt.API.@voiceconfig`](@ref)
* [`JustSayIt.API.@voiceinfo`](@ref)

#### Documentation
```@docs
JustSayIt.API.@voiceargs
JustSayIt.API.@voiceconfig
JustSayIt.API.@voiceinfo
```

## Functions
#### Index
* [`JustSayIt.API.finalize_jsi`](@ref)
* [`JustSayIt.API.init_jsi`](@ref)
* [`JustSayIt.API.controller`](@ref)
* [`JustSayIt.API.interpret_enum`](@ref)
* [`JustSayIt.API.interpret_digit`](@ref)
* [`JustSayIt.API.interpret_count`](@ref)
* [`JustSayIt.API.interpret_language`](@ref)
* [`JustSayIt.API.default_language`](@ref)
* [`JustSayIt.API.type_languages`](@ref)
* [`JustSayIt.API.ask_llm`](@ref)
* [`JustSayIt.API.ask_llm!`](@ref)
* [`JustSayIt.API.next_wordgroup`](@ref)
* [`JustSayIt.API.next_letter`](@ref)
* [`JustSayIt.API.next_letters`](@ref)
* [`JustSayIt.API.next_digit`](@ref)
* [`JustSayIt.API.next_digits`](@ref)
* [`JustSayIt.API.get_language`](@ref)
* [`JustSayIt.API.get_selection_content`](@ref)
* [`JustSayIt.API.get_clipboard_content`](@ref)
* [`JustSayIt.API.is_playing_tts`](@ref)
* [`JustSayIt.API.pause_tts`](@ref)
* [`JustSayIt.API.resume_tts`](@ref)
* [`JustSayIt.API.stop_tts`](@ref)
* [`JustSayIt.API.set_tts_async_default`](@ref)
* [`JustSayIt.API.tts_async_default`](@ref)

#### Documentation
```@docs
JustSayIt.API.controller
JustSayIt.API.finalize_jsi
JustSayIt.API.init_jsi
JustSayIt.API.interpret_enum
JustSayIt.API.interpret_digit
JustSayIt.API.interpret_count
JustSayIt.API.interpret_language
JustSayIt.API.default_language
JustSayIt.API.type_languages
JustSayIt.API.ask_llm
JustSayIt.API.ask_llm!
JustSayIt.API.next_wordgroup
JustSayIt.API.next_letter
JustSayIt.API.next_letters
JustSayIt.API.next_digit
JustSayIt.API.next_digits
JustSayIt.API.get_language
JustSayIt.API.get_selection_content
JustSayIt.API.get_clipboard_content
JustSayIt.API.is_playing_tts
JustSayIt.API.pause_tts
JustSayIt.API.resume_tts
JustSayIt.API.stop_tts
JustSayIt.API.set_tts_async_default
JustSayIt.API.tts_async_default
```

## Constants
#### Index
* [`JustSayIt.API.LANG`](@ref)
* [`JustSayIt.API.LANG_AUTO`](@ref)
* [`JustSayIt.API.MODELTYPE_DEFAULT`](@ref)
* [`JustSayIt.API.MODELTYPE_SPEECH`](@ref)
* [`JustSayIt.API.ALPHABET`](@ref)
* [`JustSayIt.API.DIGITS`](@ref)
* [`JustSayIt.API.COUNTS`](@ref)


#### Documentation
```@docs
JustSayIt.API.LANG
JustSayIt.API.LANG_AUTO
JustSayIt.API.MODELTYPE_DEFAULT
JustSayIt.API.MODELTYPE_SPEECH
JustSayIt.API.ALPHABET
JustSayIt.API.DIGITS
JustSayIt.API.COUNTS
```
