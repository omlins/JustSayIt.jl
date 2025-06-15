## API FUNCTIONS

# - [`STT.next_wordgroup`](@ref)
# - [`STT.next_letter`](@ref)
# - [`STT.next_letters`](@ref)
# - [`STT.next_digit`](@ref)
# - [`STT.next_digits`](@ref)
# - [`STT.get_language`](@ref)

# (Get words)

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
