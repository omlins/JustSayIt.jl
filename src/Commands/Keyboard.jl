"""
Module Keyboard

Provides functions for controlling the keyboard by voice.

# Functions

###### Text typing
- [`Keyboard.type_sentence`](@ref)
- [`Keyboard.type_sentence_lowercase`](@ref)

###### Word typing
- [`Keyboard.type_first_lowercase`](@ref)
- [`Keyboard.type_first_uppercase`](@ref)
- [`Keyboard.type_lowercase`](@ref)
- [`Keyboard.type_uppercase`](@ref)
- [`Keyboard.type_flatcase`](@ref)
- [`Keyboard.type_snakecase`](@ref)
- [`Keyboard.type_camelcase`](@ref)
- [`Keyboard.type_constantcase`](@ref)

###### Letter and digit typing
- [`Keyboard.type_letter`](@ref)
- [`Keyboard.type_majuscule`](@ref)
- [`Keyboard.type_letters`](@ref)
- [`Keyboard.type_capitals`](@ref)
- [`Keyboard.type_digits`](@ref)

###### Key pressing
- [`Keyboard.press_keys`](@ref)
- [`Keyboard.press_delete`](@ref)
- [`Keyboard.press_backspace`](@ref)

###### String typing
- [`Keyboard.type`](@ref)

To see a description of a function type `?<functionname>`.

See also: [`Mouse`](@ref)
"""
module Keyboard

using ..JustSayIt.API
import ..JustSayIt: Key, PyKey
using PyCall
public press_keys, press_delete, press_backspace, type_sentence, type_sentence_lowercase, type_first_lowercase, type_first_uppercase, type_lowercase, type_uppercase, type_flatcase, type_snakecase, type_camelcase, type_constantcase, type_letter, type_majuscule, type_letters, type_capitals, type_digits


## HELPER FUNCTIONS

function type_string(str::AbstractString; do_keystrokes::Bool=true, press_duration=0.001, inter_key_delay=0.001, single_line::Bool=false)
    if do_keystrokes
        keyboard = controller("keyboard")
        str = replace(str, "\\t" => "")  # NOTE: tabs are removed as editors add them automatically; keeping them would lead to pyramid-like indentation.
        if (single_line) str = replace(str, "\\n" => "")
        else             str = replace(str, "\\n" => '\n')
        end
        keys = map(convert_key, [str...])
        for key in keys
            if (!single_line && key == "\n") key = Key.enter end
            keyboard.press(key)
            sleep(press_duration)
            keyboard.release(key)
            sleep(inter_key_delay)
        end
    end
end

function handle_uppercase(token::String, is_uppercase::Bool, active_lang::String)
    if (is_uppercase) token = uppercasefirst(token) end
    if (active_lang == LANG.EN_US)
        if (startswith(token, "i'") || (token == "i")) token = uppercasefirst(token) end
    end
    return token
end

function handle_first_lower!(words::AbstractArray{<:AbstractString}, active_lang::String)
    words[begin] = handle_uppercase(lowercase(words[begin]), false, active_lang)
    return words
end

remove_end_punctuation(words_str::AbstractString, lang::String) = (lang != LANG_AUTO) ? replace(words_str, r"\p{P}+$" => "") : words_str

@voiceargs words=>(modeltype=MODELTYPE_DEFAULT, ignore_unknown=true) _next_short_wordgroup(words::String...) = return collect(words)

@enum Case first_lower first_upper lower upper flat snake camel constant
function type_fixedcase(case::Case; lang::String=default_language())
    words = @voiceconfig language=lang _next_short_wordgroup()
    words_mixed_case = handle_uppercase.(words, false, lang)
    if     (case == first_lower) words_str = join(handle_first_lower!(words_mixed_case, lang), " ")
    elseif (case == first_upper) words_str = uppercasefirst(join(words_mixed_case, " "))
    elseif (case == lower      ) words_str = join(lowercase.(words), " ")
    elseif (case == upper      ) words_str = join(uppercasefirst.(words), " ")
    elseif (case == flat       ) words_str = join(lowercase.(words))
    elseif (case == snake      ) words_str = join(lowercase.(words), "_")
    elseif (case == camel      ) words_str = join(uppercasefirst.(words))
    elseif (case == constant   ) words_str = join(uppercase.(words), "_")
    end
    type_string(remove_end_punctuation(words_str, lang))
end

convert_key(key::Char)     = string(key)
convert_key(key::PyObject) = key


## COMMAND FUNCTIONS

# (Press keys)

let     
    global press_keys, prefix, set_prefix, reset_prefix
    _prefix                    = []
    prefix()                   = _prefix
    set_prefix(keys::PyKey...) = (_prefix = keys)
    reset_prefix()             = (_prefix = [])

    "Press keys on the keyboard."
    function press_keys(keys::PyKey...; count::Integer=1)
        for i = 1:count
            keyboard  = controller("keyboard")
            keys      = map(convert_key, [prefix()..., keys...])
            @pywith keyboard.pressed(keys[1:end-1]...) begin
                keyboard.press(keys[end])
                keyboard.release(keys[end])
            end
        end
    end
end

"Press delete key."
press_delete(; count::Integer=1) = press_keys(Key.delete; count=count)

"Press backspace key."
press_backspace(; count::Integer=1) = press_keys(Key.backspace; count=count)


# (Type words)

"Type a sentence (starting uppercase)."
type_sentence(; lang::String=default_language()) = type_string(remove_end_punctuation(uppercasefirst(join(next_wordgroup(lang=lang), " ")), lang))

"Type a sentence (starting lowercase)."
type_sentence_lowercase(; lang::String=default_language()) = type_string(remove_end_punctuation(join(handle_first_lower!(next_wordgroup(lang=lang), lang), " "), lang))

"Type words, starting with the first in lowercase (separated with space)."
type_first_lowercase(; lang::String=default_language()) = type_fixedcase(first_lower; lang=lang)

"Type first words, starting with the first in uppercase (separated with space)."
type_first_uppercase(; lang::String=default_language()) = type_fixedcase(first_upper; lang=lang)

"Type words in all lowercase (separated with space)."
type_lowercase(; lang::String=default_language()) = type_fixedcase(lower; lang=lang)

"Type words in all uppercase (separated with space)."
type_uppercase(; lang::String=default_language()) = type_fixedcase(upper; lang=lang)

"Type words in flatcase (lowercase, squashed together without separator)."
type_flatcase(; lang::String=default_language()) = type_fixedcase(flat; lang=lang)

"Type words in snakecase (lowercase, separated with underscore)."
type_snakecase(; lang::String=default_language()) = type_fixedcase(snake; lang=lang)

"Type words in camelcase (each word's first letter uppercase and squashed together without separator)."
type_camelcase(; lang::String=default_language()) = type_fixedcase(camel; lang=lang)

"Type words in constantcase (uppercase, separated with underscore)."
type_constantcase(; lang::String=default_language()) = type_fixedcase(constant; lang=lang)


# (Type letters and digits)

"Type one letter."
type_letter(; lang::String=default_language()) = type_string(next_letter(lang=lang))

"Type one majuscule letter."
type_majuscule(; lang::String=default_language()) = type_string(uppercase(next_letter(lang=lang)))

"Type letters (exit on unknown)."
type_letters(; lang::String=default_language()) = type_string(join((next_letters(lang=lang)), ""))

"Type capitals (exit on unknown)."
type_capitals(; lang::String=default_language()) = type_string(join(uppercase.(next_letters(lang=lang)), ""))

"Type digits (exit on unknown)."
type_digits(; lang::String=default_language()) = type_string(join((next_digits(lang=lang)), ""))


# (Type text)

"""
    type(text::AbstractString)

Type `text` with the keyboard.
"""
type(text::AbstractString) = type_string(text)

end # module Keyboard
