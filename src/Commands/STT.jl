"""
Module STT

Provides functions for speech-to-text (STT) operations.

# Functions

###### Speech-to-Text
- [`STT.listen`](@ref)
- [`STT.next_wordgroup`](@ref)
- [`STT.next_letter`](@ref)
- [`STT.next_letters`](@ref)
- [`STT.next_digit`](@ref)
- [`STT.next_digits`](@ref)
- [`STT.get_language`](@ref)

To see a description of a function type `?<functionname>`.

See also: [`Keyboard`](@ref)
"""
module STT

using PyCall
using ..Exceptions
import ..JustSayIt: @voiceargs, @voiceconfig, pyimport_pip, controller, set_controller, PyKey, default_language, type_languages, lang_str, LANG, LANGUAGES, LANGUAGES_MAPPING, LANG_STR, ALPHABET, DIGITS, DIGITS_MAPPING, MODELTYPE_DEFAULT, MODELNAME, modelname, tic, toc, is_next, are_next, next_token, next_tokengroup, all_consumed, was_partial_recognition, InsecureRecognitionException, reset_all, do_delayed_resets, interpret_enum, UNKNOWN_TOKEN, MODELTYPE_SPEECH, MODELTYPE_DEFAULT
export listen, next_wordgroup, next_letter, next_letters, next_digit, next_digits, get_language

## PYTHON MODULES

const Pynput    = PyNULL()
const Tkinter   = PyNULL()

function __init__()
    if !haskey(ENV, "JSI_USE_PYTHON") ENV["JSI_USE_PYTHON"] = "1" end
    if ENV["JSI_USE_PYTHON"] == "1"
        copy!(Pynput, pyimport_pip("pynput"))
        copy!(Tkinter, pyimport_pip("tkinter"))
    end
end


## HELPER FUNCTIONS

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

remove_end_punctuation(words_str::AbstractString) = replace(words_str, r"\p{P}+$" => "")

interpret_digit(input::AbstractString) = (return DIGITS_MAPPING[default_language()][input])
interpret_language(input::AbstractString) = (return LANGUAGES_MAPPING[default_language()][input])


## API FUNCTIONS

# (Get words)

"Listen to speech and return the next word group."
listen(; lang::String=default_language()) = return join(next_wordgroup(lang=lang), " ")

"Get next word group from speech."
next_wordgroup(; lang::String=default_language()) = @voiceconfig language=lang _next_wordgroup()
@voiceargs words=>(modeltype=MODELTYPE_SPEECH, ignore_unknown=true) _next_wordgroup(words::String...) = return collect(words)


# (Get letters and digits)

"Get next letter from speech."
next_letter(; lang::String=default_language()) = @voiceconfig language=lang _next_letter()
@voiceargs letter=>(valid_input=ALPHABET) _next_letter(letter::String) = return letter

"Get next letters from speech."
next_letters(; lang::String=default_language()) = @voiceconfig language=lang _next_letters()
@voiceargs letters=>(valid_input=ALPHABET) _next_letters(letters::String...) = return collect(letters)

"Get next digit from speech."
next_digit(; lang::String=default_language()) = @voiceconfig language=lang _next_digit()
@voiceargs digit=>(valid_input=DIGITS, interpreter=interpret_digit) _next_digit(digit::String) = return digit

"Get next digits from speech."
next_digits(; lang::String=default_language()) = @voiceconfig language=lang _next_digits()
@voiceargs digits=>(valid_input=DIGITS, interpreter=interpret_digit) _next_digits(digits::String...) = return collect(digits)


# (Get other content)

"Get the language (IETF language tag) from speech."
get_language(; lang::String=default_language()) = @voiceconfig language=lang _get_language()
@voiceargs lang=>(valid_input=LANGUAGES, interpreter=interpret_language) _get_language(lang::String) = return lang


end # module STT
