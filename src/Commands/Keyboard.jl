"""
Module Keyboard

Provides functions for controlling the keyboard by voice.

# Functions

###### Typing
- [`type`](@ref)

###### Special keys
- [`page`](@ref)

To see a description of a function type `?<functionname>`.
"""
module Keyboard

using PyCall
import ..JustSayIt: @voiceargs, pyimport_pip, controller, set_controller, PyKey, TYPE_MODEL_NAME, ALPHABET_ENGLISH, DIGITS_ENGLISH, tic, toc, is_next, are_next, all_consumed, was_partial_recognition, InsecureRecognitionException, reset_all, do_delayed_resets


## PYTHON MODULES

const Pynput = PyNULL()

function __init__()
    ENV["PYTHON"] = ""                                              # Force PyCall to use Conda.jl
    copy!(Pynput, pyimport_pip("pynput"))
    set_controller("keyboard", Pynput.keyboard.Controller())
end


## CONSTANTS

const TYPE_MEMORY_ALLOC_GRANULARITY = 32
const TYPE_KEYWORDS_ENGLISH = Dict("end"=>"terminus", "undo"=>"undo", "redo"=>"redo", "uppercase"=>"uppercase", "lowercase"=>"lowercase", "letters"=>"letters", "digits"=>"digits", "point"=>"point", "comma"=>"comma", "colon"=>"colon", "semicolon"=>"semicolon", "exclamation"=>"exclamation", "interrogation"=>"interrogation", "paragraph" => "paragraph")


## FUNCTIONS

@doc """
    type `text` | `words` | `letters` | `digits`

Type in one of the following modes:
- `text`
- `words`
- `letters`
- `digits`

Each of the modes supports a set of keywords which can trigger some immediate action or modify the handling of subsequent speech input. It is important to note that the speech is analysed in word groups which are naturally delimited by longer silences; and keywords are only considered as such if their word group does not contain anything else then keywords. This allows to determine whether a word that is recognised as a keyword should trigger some action or be typed instead.

# Keywords
- "terminus": end typing.
- "undo": undo typing of last word group.
- "redo": redo typing of last word group.
- "uppercase": type the first word of the next word group uppercase (automatic in `text` mode after '.', '!' and '?').
- "lowercase": type the first word of the next word group lowercase (default).
- "letters": interpret the next word group as letters (interprets in addition 'space' as ' ').
- "digits": interpret the next word group as digits (interprets in addition 'dot' as '.' and 'space' as ' ').
- "point": type '.'.
- "comma": type ','.
- "colon": type ':'.
- "semicolon": type ';'.
- "exclamation": type '!'.
- "interrogation": type '?'.
- "paragraph": start a new paragraph.

# Modes

#### `text`
Type any kind of text supported by the keywords, including spelled letters, digits and punctuation marks. All keywords are supported.

#### `words`
Type words only (upper and lower case). Supported keywords are:
- "terminus"
- "undo"
- "redo"
- "uppercase"
- "lowercase"

#### `letters`
Type letters only (including '.'). Supported keywords are:
- "terminus"
- "undo"
- "redo"
- "letters"

#### `digits`
Type digits only (including '.'). Supported keywords are:
- "terminus"
- "undo"
- "redo"
- "digits"
"""
type
@enum TokenGroupKind undefined_kind keyword_kind word_kind letter_kind digit_kind punctuation_kind space_kind
@enum TypeMode text words letters digits
@voiceargs (mode=>(valid_input_auto=true)) function type(mode::TypeMode)
    @info "Typing $(string(mode))..."
    keyboard         = controller("keyboard")
    type_memory      = Vector{String}()
    tokengroup_str   = ""
    tokengroup_kind  = undefined_kind
    is_typing        = true
    was_keyword      = false
    is_new_group     = false
    is_uppercase     = (mode == text) ? true : false
    was_space        = true # We want the first token to be dealt with as if there had been a space character before (new paragraph).
    punctuation      = Vector{String}()
    spaces           = Vector{String}()
    undo_count       = 0
    ig               = 0  # group index
    it               = 0  # token index
    nb_keyword_chars = 0
    if     (mode == text)    type_keywords = [values(TYPE_KEYWORDS_ENGLISH)...]
    elseif (mode == words)   type_keywords = [TYPE_KEYWORDS_ENGLISH["end"], TYPE_KEYWORDS_ENGLISH["undo"], TYPE_KEYWORDS_ENGLISH["redo"], TYPE_KEYWORDS_ENGLISH["uppercase"], TYPE_KEYWORDS_ENGLISH["lowercase"]]
    elseif (mode == letters) type_keywords = [TYPE_KEYWORDS_ENGLISH["end"], TYPE_KEYWORDS_ENGLISH["undo"], TYPE_KEYWORDS_ENGLISH["redo"], TYPE_KEYWORDS_ENGLISH["letters"]]
    elseif (mode == digits)  type_keywords = [TYPE_KEYWORDS_ENGLISH["end"], TYPE_KEYWORDS_ENGLISH["undo"], TYPE_KEYWORDS_ENGLISH["redo"], TYPE_KEYWORDS_ENGLISH["digits"]]
    end
    while is_typing
        is_new_group = (all_consumed() && !was_partial_recognition())
        if ig == 0
            ig = 1
        elseif is_new_group && !was_keyword
            if ig > length(type_memory)
                resize!(type_memory, length(type_memory) + TYPE_MEMORY_ALLOC_GRANULARITY)
            end
            type_memory[ig] = tokengroup_str
            tokengroup_str = ""
            ig += 1
            it = 0
        end
        if is_new_group && (tokengroup_kind == undefined_kind)
            reset_all(; hard=true, exclude_active=true)      # NOTE: a reset is required to avoid that the dynamic recognizers generated in is_next and are_next include the previous recognition as desired for normal command recognition.
            if is_next(type_keywords; use_max_accuracy=false, ignore_unknown=false)
                keywords = String[]
                try
                    are_keywords, keywords = are_next(type_keywords; consume_if_match=true, ignore_unknown=false)
                catch e
                    if isa(e, InsecureRecognitionException)
                        are_keywords = false
                    else
                        rethrow(e)
                    end
                end
            else
                are_keywords = false
            end
            if are_keywords
                tokengroup_kind = keyword_kind
                reset_all(; hard=true)         # Force hard resets for performance reasons.
            else
                do_delayed_resets(; hard=true) # Force delayed resets to be done hard for performance reasons (audio must imperatively not be reset if not consumed!)
            end
        end
        if tokengroup_kind == undefined_kind
            if     (mode == text)    tokengroup_kind = word_kind
            elseif (mode == words)   tokengroup_kind = word_kind
            elseif (mode == letters) tokengroup_kind = letter_kind
            elseif (mode == digits)  tokengroup_kind = digit_kind
            end
        end
        if tokengroup_kind == keyword_kind
            @debug "Keywords found:" keywords
            tokengroup_kind = undefined_kind
            keyword_sign = ""
            for i = 1:length(keywords)
                keyword = keywords[i]
                if tokengroup_kind in (letter_kind, digit_kind)
                    @info "ABORT of keyword interpretation: keyword '$(keywords[i-1])' was followed by another keyword ('$keyword'). However, keyword '$(keywords[i-1])' defines the kind of the next word group and, therefore, no other keyword can follow it."
                    tokengroup_kind = undefined_kind
                    break
                end
                if keyword == TYPE_KEYWORDS_ENGLISH["end"]
                    is_typing = false
                elseif keyword == TYPE_KEYWORDS_ENGLISH["undo"]
                    if ig > 1
                        ig -= 1
                        @info "Undo typing of last word group..."
                        type_backspace(;count=length(type_memory[ig]) + nb_keyword_chars)
                        nb_keyword_chars = 0
                        undo_count += 1
                        if (ig == 1) || (type_memory[ig-1] in (".", "!", "?")) is_uppercase = true
                        else                                                   is_uppercase = false
                        end
                        if (ig == 1) || (type_memory[ig-1] in ("\n",)) was_space = true
                        else                                           was_space = false
                        end
                    else
                        @info "Nothing to undo."
                    end
                elseif keyword == TYPE_KEYWORDS_ENGLISH["redo"]
                    if undo_count > 0 && ig <= length(type_memory)
                        @info "Redo typing of last word group..."
                        if nb_keyword_chars > 0
                            type_backspace(;count=nb_keyword_chars)
                            nb_keyword_chars = 0
                            is_uppercase = false
                            was_space = false
                        end
                        keyboard.type(type_memory[ig])
                        undo_count -= 1
                        ig += 1
                        if (type_memory[ig-1] in (".", "!", "?")) is_uppercase = true
                        else                                      is_uppercase = false
                        end
                        if (type_memory[ig-1] in ("\n",)) was_space = true
                        else                              was_space = false
                        end
                    else
                        @info "Nothing to redo."
                    end
                elseif keyword == TYPE_KEYWORDS_ENGLISH["uppercase"]
                    is_uppercase = true
                    keyword_sign = "[$(TYPE_KEYWORDS_ENGLISH["uppercase"])]"
                elseif keyword == TYPE_KEYWORDS_ENGLISH["lowercase"]
                    is_uppercase = false
                    keyword_sign = "[$(TYPE_KEYWORDS_ENGLISH["lowercase"])]"
                elseif keyword == TYPE_KEYWORDS_ENGLISH["letters"]
                    tokengroup_kind = letter_kind
                elseif keyword == TYPE_KEYWORDS_ENGLISH["digits"]
                    tokengroup_kind = digit_kind
                elseif keyword == TYPE_KEYWORDS_ENGLISH["point"]
                    push!(punctuation, ".")
                    tokengroup_kind = punctuation_kind
                    is_uppercase = true
                elseif keyword == TYPE_KEYWORDS_ENGLISH["comma"]
                    push!(punctuation, ",")
                    tokengroup_kind = punctuation_kind
                elseif keyword == TYPE_KEYWORDS_ENGLISH["colon"]
                    push!(punctuation, ":")
                    tokengroup_kind = punctuation_kind
                elseif keyword == TYPE_KEYWORDS_ENGLISH["semicolon"]
                    push!(punctuation, ";")
                    tokengroup_kind = punctuation_kind
                elseif keyword == TYPE_KEYWORDS_ENGLISH["exclamation"]
                    push!(punctuation, "!")
                    tokengroup_kind = punctuation_kind
                    is_uppercase = true
                elseif keyword == TYPE_KEYWORDS_ENGLISH["interrogation"]
                    push!(punctuation, "?")
                    tokengroup_kind = punctuation_kind
                    is_uppercase = true
                elseif keyword == TYPE_KEYWORDS_ENGLISH["paragraph"]
                    push!(spaces, "\n")
                    tokengroup_kind = space_kind
                    was_space = true
                else
                    @info "Unkown keyword." #NOTE: this should never occur as the are_next should only match known keywords.
                end
            end
            was_keyword = true
            if     (tokengroup_kind == letter_kind) keyword_sign = keyword_sign * "[$(TYPE_KEYWORDS_ENGLISH["letters"])]"
            elseif (tokengroup_kind == digit_kind)  keyword_sign = keyword_sign * "[$(TYPE_KEYWORDS_ENGLISH["digits"])]"
            end
            if keyword_sign != ""
                keyboard.type(keyword_sign)
                nb_keyword_chars += length(keyword_sign)
            end
        else
            if     (tokengroup_kind == word_kind)   token = next_word()
            elseif (tokengroup_kind == letter_kind) token = next_letter()
            elseif (tokengroup_kind == digit_kind)  token = next_digit()
            end
            if nb_keyword_chars > 0
                type_backspace(;count=nb_keyword_chars) # NOTE: the removal of keyword signs must be done after the call to obtain the next token, in order to have it visible until it is spoken.
                nb_keyword_chars = 0
            end
            if (tokengroup_kind == word_kind)
                if (is_uppercase || startswith(token, "i'") || (token == "i")) token = uppercasefirst(token) end
                if (was_space) token_str = token
                else           token_str = " " * token
                end
            elseif (tokengroup_kind == letter_kind)
                if (is_uppercase) token = uppercase(token) end
                token_str = token
            elseif (tokengroup_kind == digit_kind)
                token_str = token
            elseif (tokengroup_kind == punctuation_kind)
                token_str = join(punctuation, "")
                punctuation = Vector{String}()
            elseif (tokengroup_kind == space_kind)
                token_str = join(spaces, "")
                spaces = Vector{String}()
            elseif (tokengroup_kind == word_kind)
                @info "Unkown token group." #NOTE: this should never occur.
            end
            keyboard.type(token_str)
            tokengroup_str *= token_str
            it += 1
            undo_count = 0
            was_keyword = false
            if !(tokengroup_kind in (punctuation_kind, space_kind)) is_uppercase = false end
            if (tokengroup_kind != space_kind) was_space = false end
            if all_consumed() tokengroup_kind = undefined_kind end
            sleep(0.05)
        end
    end
    @info "...stopped typing $(string(mode))."
end

interpret_letters(input::AbstractString) = (return ALPHABET_ENGLISH[input])
interpret_digits(input::AbstractString)  = (return DIGITS_ENGLISH[input])

@doc "Get next word from speech."
next_word
@voiceargs word=>(model=TYPE_MODEL_NAME, use_max_accuracy=true) next_word(word::String) = (return word)

@doc "Get next letter from speech."
next_letter
@voiceargs letter=>(valid_input=[keys(ALPHABET_ENGLISH)...], use_max_accuracy=true, interpret_function=interpret_letters) next_letter(letter::String) = (return letter)

@doc "Get next digit from speech."
next_digit
@voiceargs digit=>(valid_input=[keys(DIGITS_ENGLISH)...], use_max_accuracy=true, interpret_function=interpret_digits) next_digit(digit::String) = (return digit)

function type_backspace(; count::Integer=1)
    keyboard  = controller("keyboard")
    backspace = Pynput.keyboard.Key.backspace
    for i = 1:count
        keyboard.press(backspace); keyboard.release(backspace)
    end
end

function press_keys(keys::PyKey...)
    keyboard  = controller("keyboard")
    keys = map(convert_key, keys)
    @pywith keyboard.pressed(keys[1:end-1]...) begin
        keyboard.press(keys[end])
        keyboard.release(keys[end])
    end
end

convert_key(key::Char)     = string(key)
convert_key(key::PyObject) = key

end # module Keyboard
