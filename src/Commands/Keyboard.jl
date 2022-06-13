"""
Module Keyboard

Provides functions for controlling the keyboard by voice.

# Functions

###### Typing
- [`type`](@ref)

###### Special keys
- [`page`](@ref)

To see a description of a function type `?<functionname>`.

See also: [`Mouse`](@ref)
"""
module Keyboard

using PyCall
using ..Exceptions
import ..JustSayIt: @voiceargs, pyimport_pip, controller, set_controller, PyKey, default_language, type_languages, lang_str, LANG, LANG_CODES_SHORT, LANG_STR, ALPHABET, DIGITS, MODELTYPE_DEFAULT, MODELNAME, modelname, tic, toc, is_next, are_next, all_consumed, was_partial_recognition, InsecureRecognitionException, reset_all, do_delayed_resets


## PYTHON MODULES

const Pynput = PyNULL()

function __init__()
    ENV["PYTHON"] = ""                                              # Force PyCall to use Conda.jl
    copy!(Pynput, pyimport_pip("pynput"))
    set_controller("keyboard", Pynput.keyboard.Controller())
end


## CONSTANTS

const TYPE_MEMORY_ALLOC_GRANULARITY = 32
const TYPE_END_KEYWORD              = "terminus"

const TYPE_KEYWORDS = Dict(
    LANG.DE    => Dict("language"      => "sprache",
                       "undo"          => "rückgängig",
                       "redo"          => "wiederholen",
                       "uppercase"     => "grossschreiben",
                       "lowercase"     => "kleinschreiben",
                       "letters"       => "buchstaben",
                       "digits"        => "zahlen",
                       "point"         => "punkt",
                       "comma"         => "komma",
                       "colon"         => "doppelpunkt",
                       "semicolon"     => "strichpunkt",
                       "exclamation"   => "ausrufezeichen",
                       "interrogation" => "fragezeichen",
                       "paragraph"     => "paragraf"),
    LANG.EN_US => Dict("language"      => "language",
                       "undo"          => "undo",
                       "redo"          => "redo",
                       "uppercase"     => "uppercase",
                       "lowercase"     => "lowercase",
                       "letters"       => "letters",
                       "digits"        => "digits",
                       "point"         => "point",
                       "comma"         => "comma",
                       "colon"         => "colon",
                       "semicolon"     => "semicolon",
                       "exclamation"   => "exclamation",
                       "interrogation" => "interrogation",
                       "paragraph"     => "paragraph"),
    LANG.ES    => Dict("language"      => "lenguaje",
                       "undo"          => "deshacer",
                       "redo"          => "rehacer",
                       "uppercase"     => "mayuscula",
                       "lowercase"     => "minuscula",
                       "letters"       => "letras",
                       "digits"        => "cifras",
                       "point"         => "punto",
                       "comma"         => "coma",
                       "colon"         => "dospuntos",
                       "semicolon"     => "puntoycoma",
                       "exclamation"   => "exclamación",
                       "interrogation" => "interrogación",
                       "paragraph"     => "párrafo"),
    LANG.FR    => Dict("language"      => "language",
                       "undo"          => "arrière",
                       "redo"          => "avant",
                       "uppercase"     => "majuscule",
                       "lowercase"     => "minuscule",
                       "letters"       => "lettres",
                       "digits"        => "chiffres",
                       "point"         => "point",
                       "comma"         => "comma",
                       "colon"         => "doublepoint",
                       "semicolon"     => "point-virgule",
                       "exclamation"   => "exclamation",
                       "interrogation" => "interrogation",
                       "paragraph"     => "paragraphe"),
)


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
Type letters only. Supported keywords are:
- "terminus"
- "undo"
- "redo"
- "space"

#### `digits`
Type digits only. Supported keywords are:
- "terminus"
- "undo"
- "redo"
- "space"
- "dot"
"""
type
@enum TokenGroupKind undefined_kind keyword_kind word_kind letter_kind digit_kind language_kind punctuation_kind space_kind
@enum TypeMode text words letters digits
@voiceargs (mode=>(valid_input_auto=true)) function type(mode::TypeMode; end_keyword::String=TYPE_END_KEYWORD, do_keystrokes::Bool=true)
    @info "Typing $(string(mode))..."
    active_lang      = type_languages()[1]
    type_memory      = Vector{String}()
    tokengroup_str   = ""
    tokengroup_kind  = undefined_kind
    is_typing        = true
    was_keyword      = false
    was_kwarg        = false
    is_new_group     = false
    is_uppercase     = (mode == text) ? true : false
    was_space        = true # We want the first token to be dealt with as if there had been a space character before (new paragraph).
    punctuation      = Vector{String}()
    spaces           = Vector{String}()
    undo_count       = 0
    ig               = 0  # group index
    it               = 0  # token index
    nb_keyword_chars = 0
    # TODO: here I am:
    #       CHANGE LANGUAGE: I need to first add a keyword to `language` to change the language of the type model and the default model and of all keywords, including language.
    #       Then, I need to create a _next_word, etc. function for each lang with default and type models fixed for each arg (voiceargs fixes the recognizers, i.e. languae used to one - even if can be set at init when language choices made!)! Make next_word etc. a gateway!
    #       Then, english specific things as I uppercase must be made lang dependent.
    #       set active lang, change with kw lang and change also other lang dependent things with kw lang as type_keywords, etc. do fs for active_lang dependent things - grouped by what f does, e.g. uppercase...
    #       ADD MULTILANG SUPPORT FOR ALL VOICEARGS: for type, but also Email and internet -> make MODELNAME.TYPE(/MODELNAME.DEFAULT) possible (use default if not model specified...); allow valid_input to be dict with lang codes as keys... (multilang not working for valid_input_auto)
    #       add interpret f for TypeMode to convert to it...
    type_keywords = define_type_keywords(mode, end_keyword, active_lang)
    while is_typing
        is_new_group = (all_consumed() && !was_partial_recognition())
        if ig == 0
            ig = 1
        elseif is_new_group && !was_keyword && !was_kwarg
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
            if is_next(type_keywords; use_max_speed=true, ignore_unknown=false, modelname=modelname(MODELTYPE_DEFAULT, active_lang))
                keywords = String[]
                try
                    are_keywords, keywords = are_next(type_keywords; consume_if_match=true, ignore_unknown=false, modelname=modelname(MODELTYPE_DEFAULT, active_lang))
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
                if tokengroup_kind in (letter_kind, digit_kind, language_kind)
                    @info "ABORT of keyword interpretation: keyword '$(keywords[i-1])' was followed by another keyword ('$keyword'). However, keyword '$(keywords[i-1])' defines the kind of the next word group and, therefore, no other keyword can follow it."
                    tokengroup_kind = undefined_kind
                    break
                end
                if keyword == end_keyword
                    is_typing = false
                elseif keyword == TYPE_KEYWORDS[active_lang]["undo"]
                    if ig > 1
                        ig -= 1
                        @info "Undo typing of last word group..."
                        type_backspace(;count=length(type_memory[ig]) + nb_keyword_chars, do_keystrokes=do_keystrokes)
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
                elseif keyword == TYPE_KEYWORDS[active_lang]["redo"]
                    if undo_count > 0 && ig <= length(type_memory)
                        @info "Redo typing of last word group..."
                        if nb_keyword_chars > 0
                            type_backspace(;count=nb_keyword_chars, do_keystrokes=do_keystrokes)
                            nb_keyword_chars = 0
                            is_uppercase = false
                            was_space = false
                        end
                        type_string(type_memory[ig]; do_keystrokes=do_keystrokes)
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
                elseif keyword == TYPE_KEYWORDS[active_lang]["uppercase"]
                    is_uppercase = true
                    keyword_sign = "[$(TYPE_KEYWORDS[active_lang]["uppercase"])]"
                elseif keyword == TYPE_KEYWORDS[active_lang]["lowercase"]
                    is_uppercase = false
                    keyword_sign = "[$(TYPE_KEYWORDS[active_lang]["lowercase"])]"
                elseif keyword == TYPE_KEYWORDS[active_lang]["letters"]
                    tokengroup_kind = letter_kind
                elseif keyword == TYPE_KEYWORDS[active_lang]["digits"]
                    tokengroup_kind = digit_kind
                elseif keyword == TYPE_KEYWORDS[active_lang]["language"]
                    tokengroup_kind = language_kind
                elseif keyword == TYPE_KEYWORDS[active_lang]["point"]
                    push!(punctuation, ".")
                    tokengroup_kind = punctuation_kind
                    is_uppercase = true
                elseif keyword == TYPE_KEYWORDS[active_lang]["comma"]
                    push!(punctuation, ",")
                    tokengroup_kind = punctuation_kind
                elseif keyword == TYPE_KEYWORDS[active_lang]["colon"]
                    push!(punctuation, ":")
                    tokengroup_kind = punctuation_kind
                elseif keyword == TYPE_KEYWORDS[active_lang]["semicolon"]
                    push!(punctuation, ";")
                    tokengroup_kind = punctuation_kind
                elseif keyword == TYPE_KEYWORDS[active_lang]["exclamation"]
                    push!(punctuation, "!")
                    tokengroup_kind = punctuation_kind
                    is_uppercase = true
                elseif keyword == TYPE_KEYWORDS[active_lang]["interrogation"]
                    push!(punctuation, "?")
                    tokengroup_kind = punctuation_kind
                    is_uppercase = true
                elseif keyword == TYPE_KEYWORDS[active_lang]["paragraph"]
                    push!(spaces, "\n")
                    tokengroup_kind = space_kind
                    was_space = true
                else
                    @info "Unkown keyword." #NOTE: this should never occur as the are_next should only match known keywords.
                end
            end
            was_keyword = true
            if     (tokengroup_kind == letter_kind)   keyword_sign = keyword_sign * "[$(TYPE_KEYWORDS[active_lang]["letters"])]"
            elseif (tokengroup_kind == digit_kind)    keyword_sign = keyword_sign * "[$(TYPE_KEYWORDS[active_lang]["digits"])]"
            elseif (tokengroup_kind == language_kind) keyword_sign = keyword_sign * "[$(TYPE_KEYWORDS[active_lang]["language"])]"
            end
            if keyword_sign != ""
                type_string(keyword_sign; do_keystrokes=do_keystrokes)
                nb_keyword_chars += length(keyword_sign)
            end
        else
            if     (tokengroup_kind == word_kind)     token = next_word(active_lang)
            elseif (tokengroup_kind == letter_kind)   token = next_letter(active_lang)
            elseif (tokengroup_kind == digit_kind)    token = next_digit(active_lang)
            elseif (tokengroup_kind == language_kind) lang  = get_language(active_lang)
            end
            if nb_keyword_chars > 0
                type_backspace(;count=nb_keyword_chars, do_keystrokes=do_keystrokes) # NOTE: the removal of keyword signs must be done after the call to obtain the next token, in order to have it visible until it is spoken.
                nb_keyword_chars = 0
            end
            token_str = ""
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
            elseif (tokengroup_kind == language_kind)
                if (lang in type_languages()) active_lang = lang
                else                          @info "Switch to $(lang_str(lang)) not possible. To type in $(lang_str(lang)), restart JustSayIt with `start(type_languages=[..., \"$lang\"], ...), replacing `...` according to your needs."
                end
                keyword_sign = "[$(lang_str(active_lang))]"
                type_string(keyword_sign; do_keystrokes=do_keystrokes)
                nb_keyword_chars = length(keyword_sign)
                if all_consumed() type_keywords = define_type_keywords(mode, end_keyword, active_lang) end
                was_kwarg = true
                token_str = ""
            elseif (tokengroup_kind == punctuation_kind)
                token_str = join(punctuation, "")
                punctuation = Vector{String}()
            elseif (tokengroup_kind == space_kind)
                token_str = join(spaces, "")
                spaces = Vector{String}()
            elseif (tokengroup_kind == word_kind)
                @info "Unkown token group." #NOTE: this should never occur.
            end
            type_string(token_str; do_keystrokes=do_keystrokes)
            tokengroup_str *= token_str
            was_keyword = false
            it += 1
            undo_count = 0
            if !(tokengroup_kind in (punctuation_kind, space_kind, language_kind)) is_uppercase = false end
            if (tokengroup_kind != space_kind) was_space = false end
            if all_consumed()
                tokengroup_kind = undefined_kind
                was_kwarg       = false
            end
            sleep(0.05)
        end
    end
    @info "...stopped typing $(string(mode))."
    return join(type_memory[1:ig-1])
end


function define_type_keywords(mode::TypeMode, end_keyword::String, active_lang::String)
    if     (mode == text)    type_keywords = [end_keyword, values(TYPE_KEYWORDS[active_lang])...]
    elseif (mode == words)   type_keywords = [end_keyword, TYPE_KEYWORDS[active_lang]["undo"], TYPE_KEYWORDS[active_lang]["redo"], TYPE_KEYWORDS[active_lang]["uppercase"], TYPE_KEYWORDS[active_lang]["lowercase"]]
    elseif (mode == letters) type_keywords = [end_keyword, TYPE_KEYWORDS[active_lang]["undo"], TYPE_KEYWORDS[active_lang]["redo"], TYPE_KEYWORDS[active_lang]["letters"]]
    elseif (mode == digits)  type_keywords = [end_keyword, TYPE_KEYWORDS[active_lang]["undo"], TYPE_KEYWORDS[active_lang]["redo"], TYPE_KEYWORDS[active_lang]["digits"]]
    end
    return type_keywords
end


"Get next word from speech."
function next_word(lang::String)
    if     (lang == LANG.DE   ) next_word_DE()
    elseif (lang == LANG.EN_US) next_word_EN_US()
    elseif (lang == LANG.ES   ) next_word_ES()
    elseif (lang == LANG.FR   ) next_word_FR()
    end
end

@voiceargs word=>(model=MODELNAME.TYPE.DE,    ignore_unknown=true) next_word_DE(word::String)    = (return word)
@voiceargs word=>(model=MODELNAME.TYPE.EN_US, ignore_unknown=true) next_word_EN_US(word::String) = (return word)
@voiceargs word=>(model=MODELNAME.TYPE.ES,    ignore_unknown=true) next_word_ES(word::String)    = (return word)
@voiceargs word=>(model=MODELNAME.TYPE.FR,    ignore_unknown=true) next_word_FR(word::String)    = (return word)


"Get next letter from speech."
function next_letter(lang::String)
    if     (lang == LANG.DE   ) next_letter_DE()
    elseif (lang == LANG.EN_US) next_letter_EN_US()
    elseif (lang == LANG.ES   ) next_letter_ES()
    elseif (lang == LANG.FR   ) next_letter_FR()
    end
end

interpret_letters_DE(input::AbstractString)    = (return ALPHABET[LANG.DE   ][input])
interpret_letters_EN_US(input::AbstractString) = (return ALPHABET[LANG.EN_US][input])
interpret_letters_ES(input::AbstractString)    = (return ALPHABET[LANG.ES   ][input])
interpret_letters_FR(input::AbstractString)    = (return ALPHABET[LANG.FR   ][input])

@voiceargs letter=>(model=MODELNAME.DEFAULT.DE,    valid_input=[keys(ALPHABET[LANG.DE   ])...], interpret_function=interpret_letters_DE,    ignore_unknown=true) next_letter_DE(letter::String)    = (return letter)
@voiceargs letter=>(model=MODELNAME.DEFAULT.EN_US, valid_input=[keys(ALPHABET[LANG.EN_US])...], interpret_function=interpret_letters_EN_US, ignore_unknown=true) next_letter_EN_US(letter::String) = (return letter)
@voiceargs letter=>(model=MODELNAME.DEFAULT.ES,    valid_input=[keys(ALPHABET[LANG.ES   ])...], interpret_function=interpret_letters_ES,    ignore_unknown=true) next_letter_ES(letter::String)    = (return letter)
@voiceargs letter=>(model=MODELNAME.DEFAULT.FR,    valid_input=[keys(ALPHABET[LANG.FR   ])...], interpret_function=interpret_letters_FR,    ignore_unknown=true) next_letter_FR(letter::String)    = (return letter)



"Get next digit from speech."
function next_digit(lang::String)
    if     (lang == LANG.DE   ) next_digit_DE()
    elseif (lang == LANG.EN_US) next_digit_EN_US()
    elseif (lang == LANG.ES   ) next_digit_ES()
    elseif (lang == LANG.FR   ) next_digit_FR()
    end
end

interpret_digits_DE(input::AbstractString)    = (return DIGITS[LANG.DE   ][input])
interpret_digits_EN_US(input::AbstractString) = (return DIGITS[LANG.EN_US][input])
interpret_digits_ES(input::AbstractString)    = (return DIGITS[LANG.ES   ][input])
interpret_digits_FR(input::AbstractString)    = (return DIGITS[LANG.FR   ][input])

@voiceargs digit=>(model=MODELNAME.DEFAULT.DE,    valid_input=[keys(DIGITS[LANG.DE   ])...], interpret_function=interpret_digits_DE,    ignore_unknown=true) next_digit_DE(digit::String)    = (return digit)
@voiceargs digit=>(model=MODELNAME.DEFAULT.EN_US, valid_input=[keys(DIGITS[LANG.EN_US])...], interpret_function=interpret_digits_EN_US, ignore_unknown=true) next_digit_EN_US(digit::String) = (return digit)
@voiceargs digit=>(model=MODELNAME.DEFAULT.ES,    valid_input=[keys(DIGITS[LANG.ES   ])...], interpret_function=interpret_digits_ES,    ignore_unknown=true) next_digit_ES(digit::String)    = (return digit)
@voiceargs digit=>(model=MODELNAME.DEFAULT.FR,    valid_input=[keys(DIGITS[LANG.FR   ])...], interpret_function=interpret_digits_FR,    ignore_unknown=true) next_digit_FR(digit::String)    = (return digit)


"Get the language to start typing in from speech."
function get_language(lang::String)
    if     (lang == LANG.DE   ) get_language_DE()
    elseif (lang == LANG.EN_US) get_language_EN_US()
    elseif (lang == LANG.ES   ) get_language_ES()
    elseif (lang == LANG.FR   ) get_language_FR()
    end
end

function _get_language(new_lang::String, lang::String)
    codes       = [keys(LANG_STR)...]
    codes_short = getindex.(split.(codes,"-"), 1)
    code        = codes[findall(codes_short.== LANG_CODES_SHORT[lang][new_lang])]
    if (length(code) > 1) @APIUsageError("swithing language is impossible as ambigous: `type_languages` must not contain multiple region instances of the same language.") end
    return code[1]
end

@voiceargs new_lang=>(model=MODELNAME.DEFAULT.DE,    valid_input=[keys(LANG_CODES_SHORT[LANG.DE   ])...], ignore_unknown=true) get_language_DE(new_lang::String)    = _get_language(new_lang, LANG.DE)
@voiceargs new_lang=>(model=MODELNAME.DEFAULT.EN_US, valid_input=[keys(LANG_CODES_SHORT[LANG.EN_US])...], ignore_unknown=true) get_language_EN_US(new_lang::String) = _get_language(new_lang, LANG.EN_US)
@voiceargs new_lang=>(model=MODELNAME.DEFAULT.ES,    valid_input=[keys(LANG_CODES_SHORT[LANG.ES   ])...], ignore_unknown=true) get_language_ES(new_lang::String)    = _get_language(new_lang, LANG.ES)
@voiceargs new_lang=>(model=MODELNAME.DEFAULT.FR,    valid_input=[keys(LANG_CODES_SHORT[LANG.FR   ])...], ignore_unknown=true) get_language_FR(new_lang::String)    = _get_language(new_lang, LANG.FR)


function type_string(str::String; do_keystrokes::Bool=true)
    if do_keystrokes
        keyboard  = controller("keyboard")
        keyboard.type(str)
    end
end

function type_backspace(; count::Integer=1, do_keystrokes::Bool=true)
    if do_keystrokes
        keyboard  = controller("keyboard")
        backspace = Pynput.keyboard.Key.backspace
        for i = 1:count
            keyboard.press(backspace); keyboard.release(backspace)
        end
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
