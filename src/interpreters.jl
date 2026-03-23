"""
    interpret_enum(input, valid_input)

Map the localized spoken `input` found in `valid_input` to the corresponding English enum label.
"""
function interpret_enum(input::AbstractString, valid_input::Dict{String, <:AbstractArray{String}})
    index = findfirst(x -> x==input, valid_input[default_language()])
    if isnothing(index) @APIUsageError("interpretation not possible: the string $input is not present in the obtained valid_input dictionary ($valid_input).") end
    return valid_input[LANG.EN_US][index]
end

"Get the digit symbol corresponding to the spoken `input` in the current default language."
interpret_digit(input::AbstractString) = (return DIGITS_MAPPING[default_language()][input])

"Get the count symbol corresponding to the spoken `input` in the current default language."
interpret_count(input::AbstractString) = (return COUNTS_MAPPING[default_language()][input])

"Get the IETF language tag corresponding to the spoken `input` in the current default language."
interpret_language(input::AbstractString) = (return LANGUAGES_MAPPING[default_language()][input])