"""
Module Keyboard

Provides functions for controlling the keyboard by voice.

# Functions

###### Typing
- [`Keyboard.type`](@ref)

To see a description of a function type `?<functionname>`.

See also: [`Mouse`](@ref)
"""
module Keyboard

using PyCall
using ..Exceptions
import ..JustSayIt: @voiceargs, pyimport_pip, controller, set_controller, PyKey, default_language, type_languages, lang_str, LANG, LANG_CODES_SHORT, LANG_STR, ALPHABET, DIGITS, DIRECTIONS, SIDES, COUNTS, SYMBOLS, MODELTYPE_DEFAULT, MODELNAME, modelname, tic, toc, is_next, are_next, next_token, next_tokengroup, all_consumed, was_partial_recognition, InsecureRecognitionException, reset_all, do_delayed_resets, interpret_enum, UNKNOWN_TOKEN


## PYTHON MODULES

const Pynput    = PyNULL()
const Tkinter   = PyNULL()
# const Pyperclip = PyNULL()

function __init__()
    if !haskey(ENV, "JSI_USE_PYTHON") ENV["JSI_USE_PYTHON"] = "1" end
    if ENV["JSI_USE_PYTHON"] == "1"
        ENV["PYTHON"] = ""                                              # Force PyCall to use Conda.jl
        copy!(Pynput,    pyimport_pip("pynput"))
        copy!(Tkinter,   pyimport_pip("tkinter"))
        # copy!(Pyperclip, pyimport_pip("pyperclip"))
        set_controller("keyboard", Pynput.keyboard.Controller())
    end
end


## CONSTANTS

const TYPE_MEMORY_ALLOC_GRANULARITY = 32
const TYPE_END_KEYWORD              = "terminus"

const TYPE_MODES = Dict(
    LANG.DE    => ["text",  "wörter",   "buchstaben", "ziffern"],
    LANG.EN_US => ["text",  "words",    "letters",    "digits"],
    LANG.ES    => ["texto", "palabras", "letras",     "cifras"],
    LANG.FR    => ["text",  "mots",     "lettres",    "chiffres"],
)

# TODO: as a workaround for an issue with the dynamic German and Spanish models, the English model is used...
const TYPE_KEYWORDS = Dict(
    # LANG.DE    => Dict("language"      => "sprache",
    #                    "undo"          => "rückgängig",
    #                    "redo"          => "wiederholen",
    #                    "uppercase"     => "gross",
    #                    "lowercase"     => "klein",
    #                    "letters"       => "buchstaben",
    #                    "digits"        => "ziffern",
    #                    "point"         => "punkt",
    #                    "comma"         => "komma",
    #                    "colon"         => "doppelpunkt",
    #                    "semicolon"     => "strichpunkt",
    #                    "exclamation"   => "ausrufezeichen",
    #                    "interrogation" => "fragezeichen",
    #                    "paragraph"     => "paragraf"),
    LANG.DE   => Dict("language"      => "language",
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
    # LANG.ES    => Dict("language"      => "lenguaje",
    #                    "undo"          => "deshacer",
    #                    "redo"          => "rehacer",
    #                    "uppercase"     => "mayúscula",
    #                    "lowercase"     => "minúscula",
    #                    "letters"       => "letras",
    #                    "digits"        => "cifras",
    #                    "point"         => "punto",
    #                    "comma"         => "coma",
    #                    "colon"         => "dos-puntos",
    #                    "semicolon"     => "punto-y-coma",
    #                    "exclamation"   => "exclamación",
    #                    "interrogation" => "interrogación",
    #                    "paragraph"     => "párrafo"),
    LANG.ES    => Dict("language"      => "language",
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
    LANG.FR    => Dict("language"      => "language",
                       "undo"          => "défaire",
                       "redo"          => "refaire",
                       "uppercase"     => "majuscule",
                       "lowercase"     => "minuscule",
                       "letters"       => "lettres",
                       "digits"        => "chiffres",
                       "point"         => "point",
                       "comma"         => "virgule",
                       "colon"         => "deux",
                       "semicolon"     => "point-virgule",
                       "exclamation"   => "exclamation",
                       "interrogation" => "interrogation",
                       "paragraph"     => "paragraphe"),
)

const WHITESPACE_PATTERN = Dict(
    LANG.DE    => Dict("leer"    => r"\s+"),
    LANG.EN_US => Dict("space"   => r"\s+"),
    LANG.ES    => Dict("espacio" => r"\s+"),
    LANG.FR    => Dict("espace"  => r"\s+"),
)


## FUNCTIONS

interpret_typemode(input::AbstractString) = interpret_enum(input, TYPE_MODES)

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
- "language": change typing language.
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
Type letters only (upper and lower case). Supported keywords are:
- "terminus"
- "undo"
- "redo"
- "uppercase"
- "lowercase"
- "space"

#### `digits`
Type digits only. Supported keywords are:
- "terminus"
- "undo"
- "redo"
- "space"
- "dot"
- "comma"
"""
type
@enum TokenGroupKind undefined_kind keyword_kind word_kind letter_kind digit_kind language_kind direct_kind
@enum TypeMode text words letters digits
@voiceargs (mode=>(valid_input=Tuple(TYPE_MODES), interpret_function=interpret_typemode)) function type(mode::TypeMode; end_keyword::String=TYPE_END_KEYWORD, exit_on_unknown=false, max_word_groups=Inf, active_lang=type_languages()[1], do_keystrokes::Bool=true)
    @info "Typing $(string(mode))..."
    type_memory      = Vector{String}()
    tokengroup_str   = ""
    tokengroup_kind  = undefined_kind
    is_typing        = true
    was_keyword      = false
    was_kwarg        = false
    is_new_group     = false
    is_uppercase     = (mode == text) ? true : false
    was_space        = true # We want the first token to be dealt with as if there had been a space character before (new paragraph).
    direct_input     = Vector{String}()
    undo_count       = 0
    ig               = 0  # group index
    it               = 0  # token index
    nb_keyword_chars = 0
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
            if (ig > max_word_groups) break end
        end
        if is_new_group && (tokengroup_kind == undefined_kind)
            reset_all(; hard=true, exclude_active=true)      # NOTE: a reset is required to avoid that the dynamic recognizers generated in is_next and are_next include the previous recognition as desired for normal command recognition.
            if is_next(type_keywords; use_max_speed=true, ignore_unknown=false, modelname=modelname(MODELTYPE_DEFAULT, (active_lang==LANG.FR) ? active_lang : LANG.EN_US ))  # TODO: as a workaround for an issue with the dynamic German and Spanish models, the English model is used; once this issue is fixed, the modelname should be set again as: modelname=modelname(MODELTYPE_DEFAULT, active_lang)
                keywords = String[]
                try
                    are_keywords, keywords = are_next(type_keywords; consume_if_match=true, ignore_unknown=false, modelname=modelname(MODELTYPE_DEFAULT, (active_lang==LANG.FR) ? active_lang : LANG.EN_US))  # TODO: as a workaround for an issue with the dynamic German and Spanish models, the English model is used; once this issue is fixed, the modelname should be set again as: modelname=modelname(MODELTYPE_DEFAULT, active_lang)
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
                    @info "Languages initialized for typing: $(join(lang_str.(type_languages()), ", ", " and "))."
                elseif keyword == TYPE_KEYWORDS[active_lang]["point"]
                    push!(direct_input, ".")
                    tokengroup_kind = direct_kind
                    is_uppercase = true
                elseif keyword == TYPE_KEYWORDS[active_lang]["comma"]
                    push!(direct_input, ",")
                    tokengroup_kind = direct_kind
                elseif keyword == TYPE_KEYWORDS[active_lang]["colon"]
                    push!(direct_input, ":")
                    tokengroup_kind = direct_kind
                elseif keyword == TYPE_KEYWORDS[active_lang]["semicolon"]
                    push!(direct_input, ";")
                    tokengroup_kind = direct_kind
                elseif keyword == TYPE_KEYWORDS[active_lang]["exclamation"]
                    push!(direct_input, "!")
                    tokengroup_kind = direct_kind
                    is_uppercase = true
                elseif keyword == TYPE_KEYWORDS[active_lang]["interrogation"]
                    push!(direct_input, "?")
                    tokengroup_kind = direct_kind
                    is_uppercase = true
                elseif keyword == TYPE_KEYWORDS[active_lang]["paragraph"]
                    push!(direct_input, "\n")
                    tokengroup_kind = direct_kind
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
            token = ""
            if     (tokengroup_kind == word_kind)     token = next_word(active_lang)
            elseif (tokengroup_kind == letter_kind)   token = next_letter(active_lang)
            elseif (tokengroup_kind == digit_kind)    token = next_digit(active_lang)
            elseif (tokengroup_kind == language_kind) lang  = get_language(active_lang)
            end
            if nb_keyword_chars > 0
                type_backspace(;count=nb_keyword_chars, do_keystrokes=do_keystrokes) # NOTE: the removal of keyword signs must be done after the call to obtain the next token, in order to have it visible until it is spoken.
                nb_keyword_chars = 0
            end
            if token == UNKNOWN_TOKEN
                if (exit_on_unknown) is_typing = false end
            else  
                token_str = ""
                if (tokengroup_kind == word_kind)
                    token = handle_uppercase(token, is_uppercase, active_lang)
                    if (was_space) token_str = token
                    else           token_str = " " * token
                    end
                elseif (tokengroup_kind == letter_kind)
                    if (is_uppercase) token = uppercasefirst(token) end
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
                elseif (tokengroup_kind == direct_kind)
                    token_str = join(direct_input, "")
                    direct_input = Vector{String}()
                elseif (tokengroup_kind == word_kind)
                    @info "Unkown token group." #NOTE: this should never occur.
                end
                type_string(token_str; do_keystrokes=do_keystrokes)
                tokengroup_str *= token_str
                was_keyword = false
                it += 1
                undo_count = 0
                if !(tokengroup_kind in (direct_kind, language_kind)) is_uppercase = false end
                if (tokengroup_kind != direct_kind) || (token_str[end] ∉ [" ", "\n", "\t"] )
                    was_space = false
                end
                if all_consumed()
                    tokengroup_kind = undefined_kind
                    was_kwarg       = false
                end
                sleep(0.0001)
            end
        end
    end
    @info "...stopped typing $(string(mode))."
    return join(type_memory[1:ig-1])
end


# function define_type_keywords(mode::TypeMode, end_keyword::String, active_lang::String)
#     if     (mode == text)    type_keywords = [end_keyword, values(TYPE_KEYWORDS[active_lang])...]
#     elseif (mode == words)   type_keywords = [end_keyword, TYPE_KEYWORDS[active_lang]["undo"], TYPE_KEYWORDS[active_lang]["redo"], TYPE_KEYWORDS[active_lang]["uppercase"], TYPE_KEYWORDS[active_lang]["lowercase"]]
#     elseif (mode == letters) type_keywords = [end_keyword, TYPE_KEYWORDS[active_lang]["undo"], TYPE_KEYWORDS[active_lang]["redo"], TYPE_KEYWORDS[active_lang]["letters"]]
#     elseif (mode == digits)  type_keywords = [end_keyword, TYPE_KEYWORDS[active_lang]["undo"], TYPE_KEYWORDS[active_lang]["redo"], TYPE_KEYWORDS[active_lang]["digits"]]
#     end
#     return type_keywords
# end

function define_type_keywords(mode::TypeMode, end_keyword::String, active_lang::String)
    if     (mode == text)    type_keywords = [end_keyword, values(TYPE_KEYWORDS[(active_lang==LANG.FR) ? active_lang : LANG.EN_US])...]  # TODO: as a workaround for an issue with the dynamic German and Spanish models, the English model is used; once this issue is fixed, the line should be: type_keywords = [end_keyword, values(TYPE_KEYWORDS[active_lang])...]
    elseif (mode == words)   type_keywords = [end_keyword, TYPE_KEYWORDS[active_lang]["undo"], TYPE_KEYWORDS[active_lang]["redo"], TYPE_KEYWORDS[active_lang]["uppercase"], TYPE_KEYWORDS[active_lang]["lowercase"]]
    elseif (mode == letters) type_keywords = [end_keyword, TYPE_KEYWORDS[active_lang]["undo"], TYPE_KEYWORDS[active_lang]["redo"], TYPE_KEYWORDS[active_lang]["uppercase"], TYPE_KEYWORDS[active_lang]["lowercase"], TYPE_KEYWORDS[active_lang]["letters"]]
    elseif (mode == digits)  type_keywords = [end_keyword, TYPE_KEYWORDS[active_lang]["undo"], TYPE_KEYWORDS[active_lang]["redo"], TYPE_KEYWORDS[active_lang]["digits"]]
    end
    return type_keywords
end


function handle_uppercase(token::String, is_uppercase::Bool, active_lang::String)
    if (is_uppercase) token = uppercasefirst(token) end
    if (active_lang == LANG.EN_US)
        if (startswith(token, "i'") || (token == "i")) token = uppercasefirst(token) end
    end
    return token
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
function next_letter(lang::String; ignore_unknown=false, use_max_speed=false)
    if !ignore_unknown && is_next(UNKNOWN_TOKEN, [keys(ALPHABET[lang])...]; use_max_speed=use_max_speed, ignore_unknown=false, modelname=modelname(MODELTYPE_DEFAULT, lang))
        return UNKNOWN_TOKEN
    else
        if     (lang == LANG.DE   ) next_letter_DE(; use_max_speed=use_max_speed)
        elseif (lang == LANG.EN_US) next_letter_EN_US(; use_max_speed=use_max_speed)
        elseif (lang == LANG.ES   ) next_letter_ES(; use_max_speed=use_max_speed)
        elseif (lang == LANG.FR   ) next_letter_FR(; use_max_speed=use_max_speed)
        end
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
function next_digit(lang::String; ignore_unknown=false, use_max_speed=false)
    if !ignore_unknown && is_next(UNKNOWN_TOKEN, [keys(DIGITS[lang])...]; use_max_speed=use_max_speed, ignore_unknown=false, modelname=modelname(MODELTYPE_DEFAULT, lang))
        return UNKNOWN_TOKEN
    else
        if     (lang == LANG.DE   ) next_digit_DE(; use_max_speed=use_max_speed)
        elseif (lang == LANG.EN_US) next_digit_EN_US(; use_max_speed=use_max_speed)
        elseif (lang == LANG.ES   ) next_digit_ES(; use_max_speed=use_max_speed)
        elseif (lang == LANG.FR   ) next_digit_FR(; use_max_speed=use_max_speed)
        end
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
    if (length(code) > 1) @APIUsageError("switching language is impossible as ambigous: `type_languages` must not contain multiple region instances of the same language.") end
    return code[1]
end

@voiceargs new_lang=>(model=MODELNAME.DEFAULT.DE,    valid_input=[keys(LANG_CODES_SHORT[LANG.DE   ])...], ignore_unknown=true) get_language_DE(new_lang::String)    = _get_language(new_lang, LANG.DE)
@voiceargs new_lang=>(model=MODELNAME.DEFAULT.EN_US, valid_input=[keys(LANG_CODES_SHORT[LANG.EN_US])...], ignore_unknown=true) get_language_EN_US(new_lang::String) = _get_language(new_lang, LANG.EN_US)
@voiceargs new_lang=>(model=MODELNAME.DEFAULT.ES,    valid_input=[keys(LANG_CODES_SHORT[LANG.ES   ])...], ignore_unknown=true) get_language_ES(new_lang::String)    = _get_language(new_lang, LANG.ES)
@voiceargs new_lang=>(model=MODELNAME.DEFAULT.FR,    valid_input=[keys(LANG_CODES_SHORT[LANG.FR   ])...], ignore_unknown=true) get_language_FR(new_lang::String)    = _get_language(new_lang, LANG.FR)


function type_string(str::String; do_keystrokes::Bool=true)
    if do_keystrokes
        keyboard = controller("keyboard")
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

let     
    global press_keys, prefix, set_prefix, reset_prefix
    _prefix                    = []
    prefix()                   = _prefix
    set_prefix(keys::PyKey...) = (_prefix = keys)
    reset_prefix()             = (_prefix = [])

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

convert_key(key::Char)     = string(key)
convert_key(key::PyObject) = key

"Type one letter."
function type_letter()
    token = next_letter(default_language())
    if (token != UNKNOWN_TOKEN) type_string(token) end
end

"Type one majuscule letter."
function type_majuscule()
    token = next_letter(default_language())
    if (token != UNKNOWN_TOKEN) type_string(uppercase(token)) end
end

"Type letters (exit on unknown)."
type_letters(; do_keystrokes=true) = (text = type(letters; exit_on_unknown=true, max_word_groups=1, active_lang=default_language(), do_keystrokes=do_keystrokes); reset_all(); return text) # NOTE: reset_all() is necessary to avoid that badly recognized letters are interpreted as commands; instead, the remainder of the word group is ignored after an unknown token.

"Type capitals (exit on unknown)."
type_capitals() = type_string(join(uppercase.(split(type_letters(; do_keystrokes=false))), " "))

"Type digits (exit on unknown)."
type_digits() = type(digits; exit_on_unknown=true, max_word_groups=1, active_lang=default_language())

"Type words in lowercase (separated with space)."
type_lowercase() = type_fixedcase(lower)

"Type first words in uppercase, then lowercase (separated with space)."
type_uppercase() = type_fixedcase(upper)

"Type words in flatcase (lowercase, squashed together without separator)."
type_flatcase() = type_fixedcase(flat)

"Type words in snakecase (lowercase, separated with underscore)."
type_snakecase() = type_fixedcase(snake)

"Type words in camelcase (each word's first letter uppercase and squashed together without separator)."
type_camelcase() = type_fixedcase(camel)

"Type words in constantcase (uppercase, separated with underscore)."
type_constantcase() = type_fixedcase(constant)

@enum Case lower upper flat snake camel constant
function type_fixedcase(case::Case)
    words_str = Keyboard.type(Keyboard.words; max_word_groups=1, active_lang=default_language(), do_keystrokes=false)
    words = split(words_str)
    if     (case == lower   ) type_string(join(lowercase.(words), " "))
    elseif (case == upper   ) type_string(uppercasefirst(join(lowercase.(words), " ")))
    elseif (case == flat    ) type_string(join(lowercase.(words)))
    elseif (case == snake   ) type_string(join(lowercase.(words), "_"))
    elseif (case == camel   ) type_string(join(uppercasefirst.(words)))
    elseif (case == constant) type_string(join(uppercase.(words), "_"))
    end
end


function navigate(; up_lines=10, down_lines=10)
    Key        = Pynput.keyboard.Key
    lang       = default_language()
    directions = [keys(DIRECTIONS[lang])...]
    counts     = [keys(COUNTS[lang])...]
    modes      = [directions..., counts...]

    token = next_token(modes; consume=false, use_partial_recognitions=true, ignore_unknown=false) # NOTE: the token is not consumed yet...

    # Case: go <direction> <side> <text>
    if (token in directions)
        direction = next_direction(; use_max_speed=true) #TODO: see if forward backward upward and downward should be included here.
        if (token != UNKNOWN_TOKEN)        
            @info "go $direction <side> <text> ..."
            @show context = get_context(direction, up_lines, down_lines)
            @show valid_input = derive_valid_input(context) # NOTE: pre compute the valid input while the side key word is being spoken.
            token = next_side(; use_max_speed=true)
            if (token != UNKNOWN_TOKEN)
                side = token
                @info "... go $direction $side <text> ..."
                @show text_keys = next_tokengroup(valid_input; use_partial_recognitions=false, ignore_unknown=false)
                if !all(text_keys .== UNKNOWN_TOKEN)
                    @show text_elements = replace(text_keys, SYMBOLS[lang]..., WHITESPACE_PATTERN[lang]..., UNKNOWN_TOKEN => r"[\\p{L}\\p{S}]") # NOTE: \p{L} = letters, \p{N} = numbers, \p{P} = punctuation, \p{S} = symbols, \p{Z} = whitespace, \p{M} = marks, \p{C} = other characters
                    @show text_pattern = prod(regex.(text_elements, "is")) # NOTE: the text elements also include spaces, so we need to join without spaces.
                    @show range = findfirst(text_pattern, context)
                    if isnothing(range) # NOTE: letter recognition is not very secure; thus, as no match had been found, we replace letters with a pattern that matches any letter.
                        @show text_elements = replace(text_elements, r"[a-z]"  => r"[a-z]")
                        @show text_pattern = prod(regex.(text_elements, "is")) # NOTE: the text elements also include spaces, so we need to join without spaces.
                        @show range = findfirst(text_pattern, context)
                    end
                    if !isnothing(range)
                        @info "... go $direction $side $text_pattern"
                        stop_highlighting(direction; to_origin=false)
                        @show displacement_from_origin = move_cursor(side, direction, context, range)
                        token = next_direction(; use_max_speed=true) #TODO: see if other then forward backward should be included here.
                        ranges = [range]
                        was_forward = true
                        while token in ["forward", "backward"]
                            if token == "forward"  
                                @show range = findnext(text_pattern, context, ranges[end].stop+1)
                                if isnothing(range)
                                    @info "... no more match found."
                                else
                                    @info "... forward ..."
                                    push!(ranges, range)
                                end
                                was_forward = true
                            elseif token == "backward"
                                @show range = pop!(ranges)
                                if was_forward && !isempty(ranges)
                                    @show range = pop!(ranges)
                                end
                                if isempty(ranges) 
                                    @info "... reached first match."
                                    ranges = [range]
                                else
                                    @info "... backward ..."
                                end
                                was_forward = false
                            end
                            if !isnothing(range)
                                @show displacement_from_origin += move_cursor(side, direction, context, range, displacement_from_origin)
                            end
                            token = next_direction(; use_max_speed=true) #TODO: see if other then forward backward should be included here.
                        end
                    else
                        @info "... no match found."
                        stop_highlighting(direction)
                        @InsecureRecognitionException("unknown text.")
                    end
                else
                    @info "... no text recognized."
                    stop_highlighting(direction)
                    @InsecureRecognitionException("unknown text.")
                end
            else
                @info "... no side recognized."
                stop_highlighting(direction)
                @InsecureRecognitionException("unknown side.")
            end
        else
            @info "... no direction recognized."
            @InsecureRecognitionException("unknown direction.")
        end

    # Case: go <count> <direction>
    elseif (token in counts)
        token = next_count(; use_max_speed=true)
        if (token != UNKNOWN_TOKEN)
            count = parse(Int, token) # NOTE: this is safe as the count is always an integer.
            @info "go $count <direction> ..."
            token = next_direction()
            if (token != UNKNOWN_TOKEN)
                direction = token
                @info "... go $count $direction."
                if     (direction == "right")    press_keys(Key.right;           count=count)
                elseif (direction == "left")     press_keys(Key.left;            count=count)
                elseif (direction == "up")       press_keys(Key.up;              count=count)
                elseif (direction == "down")     press_keys(Key.down;            count=count)
                elseif (direction == "forward")  press_keys(Key.ctrl, Key.right; count=count)
                elseif (direction == "backward") press_keys(Key.ctrl, Key.left;  count=count)
                elseif (direction == "upward")   press_keys(Key.ctrl, Key.up;    count=count)
                elseif (direction == "downward") press_keys(Key.ctrl, Key.down;  count=count)
                end
            else
                @info "... no direction recognized."
                @InsecureRecognitionException("unknown direction.")
            end
            return
        else
            @info "... no count recognized."
            @InsecureRecognitionException("unknown count.")
        end

    else
        @InsecureRecognitionException("unknown direction or count.") # NOTE: it could return without exception, if the command handler will just continue from there.
    end
end


function regex(pattern::AbstractString, flags::String; as_string=true)
    if as_string
        return Regex("", flags) * pattern
    else
        return Regex(pattern, flags)
    end
end

function regex(pattern::Regex, flags::String; as_string=false)
    return pattern
end

function get_context(direction::String, up_lines::Integer, down_lines::Integer; copy_shortcut=(Pynput.keyboard.Key.ctrl, 'c'))
    Key = Pynput.keyboard.Key
    if     (direction == "right")    press_keys(Key.shift, Key.end)
    elseif (direction == "left")     press_keys(Key.shift, Key.home)
    elseif (direction == "up")       press_keys(Key.shift, Key.up; count=up_lines); press_keys(Key.shift, Key.home)
    elseif (direction == "down")     press_keys(Key.shift, Key.down; count=down_lines); press_keys(Key.shift, Key.end)
    elseif (direction == "upward")   press_keys(Key.shift, Key.page_up)
    elseif (direction == "downward") press_keys(Key.shift, Key.page_down)
    end
    @show clipboard_old = get_clipboard_content()
    press_keys(copy_shortcut...)
    context = get_clipboard_content()
    @show restore_clipboard_content(clipboard_old)
    return context #TODO: handle errors!
end

function restore_clipboard_content(clipboard_old::String)
    root = Tkinter.Tk()
    root.withdraw()
    root.clipboard_clear()
    root.clipboard_append(clipboard_old)
    # Pyperclip.copy(clipboard_old)
    # content = Pyperclip.paste()
    content = get_clipboard_content()
    # root.update_idletasks()
    root.update()
    root.destroy()
    return content
end

function get_clipboard_content()
    # content = Pyperclip.paste()
    root = Tkinter.Tk() # NOTE: it seems to be necessary that the root object is created after the keyboard copy shortcut is executed has otherwise the clipboard does sometimes not contain the new content.
    root.withdraw()
    # root.update_idletasks()
    root.update()
    content = ""
    try
        content = root.clipboard_get()
    catch e
        if isa(e, PyCall.PyError)
            content = ""
        else
            rethrow(e)
        end
    end
    # root.update_idletasks()
    root.update()
    root.destroy()
    return content
end

function stop_highlighting(direction::String; to_origin=true)
    Key = Pynput.keyboard.Key
    if to_origin
        if     (direction == "right" || direction == "down") press_keys(Key.left)  # Stop highlighting moving the cursor back to the origin.
        elseif (direction == "left"  || direction == "up")   press_keys(Key.right) # ...
        end
    else
        press_keys(Key.esc) # Stop highlighting without moving the cursor.
    end
end

function derive_valid_input(context::String)
    lang = default_language()
    @show words           = replace(context, r"[^a-zA-Z]" => " ") |> lowercase |> split
    @show letters         = string.(replace(context, r"[^a-zA-Z]" => "") |> lowercase |> unique)
    @show symbols         = string.(replace(context, r"[a-zA-Z]"  => "") |> unique)
    @show symbol_keys     = [key for (key, symbol) in SYMBOLS[lang] if (symbol in symbols)]
    @show whitespace_keys = keys(WHITESPACE_PATTERN[lang]) # NOTE: we do not distinguish between different kind of whitespaces; so we always need to include the generic.
    @show valid_input     = String[words..., letters..., symbol_keys..., whitespace_keys...]
    return valid_input
end

function move_cursor(side::String, direction::String, context::String, range::UnitRange, displacement_from_origin::Int=0)
    @show length(context)
    Key = Pynput.keyboard.Key
    if     (side == "before") new_position = range.start - 1
    elseif (side == "after")  new_position = range.stop
    end
    if     (direction == "right" || direction == "down" || direction == "downward") displacement = new_position - displacement_from_origin - length(context)
    elseif (direction == "left"  || direction == "up"   || direction == "upward")   displacement = new_position - displacement_from_origin
    end
    press_keys((displacement < 0) ? Key.left : Key.right, count=abs(displacement)) # Go to the new position.
    return displacement
end


"Get next direction from speech."
function next_direction(; ignore_unknown=false, use_max_speed=false)
    if !ignore_unknown && is_next(UNKNOWN_TOKEN, [keys(DIRECTIONS[default_language()])...]; use_max_speed=use_max_speed, ignore_unknown=false)
        return UNKNOWN_TOKEN
    else
        _next_direction(; use_max_speed=use_max_speed)
    end
end

interpret_direction(input::AbstractString) = (return DIRECTIONS[default_language()][input])
@voiceargs direction=>(valid_input=(LANG.DE=>[keys(DIRECTIONS[LANG.DE])...], LANG.EN_US=>[keys(DIRECTIONS[LANG.EN_US])...], LANG.ES=>[keys(DIRECTIONS[LANG.ES])...], LANG.FR=>[keys(DIRECTIONS[LANG.FR])...]), interpret_function=interpret_direction, ignore_unknown=true) _next_direction(direction::String) = (return direction)


"Get next side from speech."
function next_side(; ignore_unknown=false, use_max_speed=false)
    if !ignore_unknown && is_next(UNKNOWN_TOKEN, [keys(SIDES[default_language()])...]; use_max_speed=use_max_speed, ignore_unknown=false)
        return UNKNOWN_TOKEN
    else
        _next_side(; use_max_speed=use_max_speed)
    end
end

interpret_side(input::AbstractString) = (return SIDES[default_language()][input])
@voiceargs side=>(valid_input=(LANG.DE=>[keys(SIDES[LANG.DE])...], LANG.EN_US=>[keys(SIDES[LANG.EN_US])...], LANG.ES=>[keys(SIDES[LANG.ES])...], LANG.FR=>[keys(SIDES[LANG.FR])...]), interpret_function=interpret_side, ignore_unknown=true) _next_side(side::String) = (return side)


"Get next count from speech."
function next_count(; ignore_unknown=false, use_max_speed=false)
    if !ignore_unknown && is_next(UNKNOWN_TOKEN, [keys(COUNTS[default_language()])...]; use_max_speed=use_max_speed, ignore_unknown=false)
        return UNKNOWN_TOKEN
    else
        _next_count(; use_max_speed=use_max_speed)
    end
end

interpret_count(input::AbstractString) = (return COUNTS[default_language()][input])
@voiceargs count=>(valid_input=(LANG.DE=>[keys(COUNTS[LANG.DE])...], LANG.EN_US=>[keys(COUNTS[LANG.EN_US])...], LANG.ES=>[keys(COUNTS[LANG.ES])...], LANG.FR=>[keys(COUNTS[LANG.FR])...]), interpret_function=interpret_count, ignore_unknown=true) _next_count(count::String) = (return count)

# function next_direction(lang::String; ignore_unknown=false, use_max_speed=false)
#     if !ignore_unknown && is_next(UNKNOWN_TOKEN, [keys(DIRECTIONS[lang])...]; use_max_speed=use_max_speed, ignore_unknown=false, modelname=modelname(MODELTYPE_DEFAULT, lang))
#         return UNKNOWN_TOKEN
#     else
#         if     (lang == LANG.DE   ) next_direction_DE(; use_max_speed=use_max_speed)
#         elseif (lang == LANG.EN_US) next_direction_EN_US(; use_max_speed=use_max_speed)
#         elseif (lang == LANG.ES   ) next_direction_ES(; use_max_speed=use_max_speed)
#         elseif (lang == LANG.FR   ) next_direction_FR(; use_max_speed=use_max_speed)
#         end
#     end
# end

# interpret_direction_DE(input::AbstractString)    = (return DIRECTIONS[LANG.DE   ][input])
# interpret_direction_EN_US(input::AbstractString) = (return DIRECTIONS[LANG.EN_US][input])
# interpret_direction_ES(input::AbstractString)    = (return DIRECTIONS[LANG.ES   ][input])
# interpret_direction_FR(input::AbstractString)    = (return DIRECTIONS[LANG.FR   ][input])

# @voiceargs direction=>(model=MODELNAME.DEFAULT.DE,    valid_input=[keys(DIRECTIONS[LANG.DE   ])...], interpret_function=interpret_direction_DE,    ignore_unknown=true) next_direction_DE(direction::String)    = (return direction)
# @voiceargs direction=>(model=MODELNAME.DEFAULT.EN_US, valid_input=[keys(DIRECTIONS[LANG.EN_US])...], interpret_function=interpret_direction_EN_US, ignore_unknown=true) next_direction_EN_US(direction::String) = (return direction)
# @voiceargs direction=>(model=MODELNAME.DEFAULT.ES,    valid_input=[keys(DIRECTIONS[LANG.ES   ])...], interpret_function=interpret_direction_ES,    ignore_unknown=true) next_direction_ES(direction::String)    = (return direction)
# @voiceargs direction=>(model=MODELNAME.DEFAULT.FR,    valid_input=[keys(DIRECTIONS[LANG.FR   ])...], interpret_function=interpret_direction_FR,    ignore_unknown=true) next_direction_FR(direction::String)    = (return direction)


# "Get next side from speech"
# function next_side(lang::String; ignore_unknown=false, use_max_speed=false)
#     if !ignore_unknown && is_next(UNKNOWN_TOKEN, [keys(SIDES[lang])...]; use_max_speed=use_max_speed, ignore_unknown=false, modelname=modelname(MODELTYPE_DEFAULT, lang))
#         return UNKNOWN_TOKEN
#     else
#         if     (lang == LANG.DE   ) next_side_DE(; use_max_speed=use_max_speed)
#         elseif (lang == LANG.EN_US) next_side_EN_US(; use_max_speed=use_max_speed)
#         elseif (lang == LANG.ES   ) next_side_ES(; use_max_speed=use_max_speed)
#         elseif (lang == LANG.FR   ) next_side_FR(; use_max_speed=use_max_speed)
#         end
#     end
# end

# interpret_side_DE(input::AbstractString)    = (return SIDES[LANG.DE   ][input])
# interpret_side_EN_US(input::AbstractString) = (return SIDES[LANG.EN_US][input])
# interpret_side_ES(input::AbstractString)    = (return SIDES[LANG.ES   ][input])
# interpret_side_FR(input::AbstractString)    = (return SIDES[LANG.FR   ][input])

# @voiceargs side=>(model=MODELNAME.DEFAULT.DE,    valid_input=[keys(SIDES[LANG.DE   ])...], interpret_function=interpret_side_DE,    ignore_unknown=true) next_side_DE(side::String)    = (return side)
# @voiceargs side=>(model=MODELNAME.DEFAULT.EN_US, valid_input=[keys(SIDES[LANG.EN_US])...], interpret_function=interpret_side_EN_US, ignore_unknown=true) next_side_EN_US(side::String) = (return side)
# @voiceargs side=>(model=MODELNAME.DEFAULT.ES,    valid_input=[keys(SIDES[LANG.ES   ])...], interpret_function=interpret_side_ES,    ignore_unknown=true) next_side_ES(side::String)    = (return side)
# @voiceargs side=>(model=MODELNAME.DEFAULT.FR,    valid_input=[keys(SIDES[LANG.FR   ])...], interpret_function=interpret_side_FR,    ignore_unknown=true) next_side_FR(side::String)    = (return side)


end # module Keyboard
