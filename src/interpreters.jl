function interpret_enum(input::AbstractString, valid_input::Dict{String, <:AbstractArray{String}})
    index = findfirst(x -> x==input, valid_input[default_language()])
    if isnothing(index) @APIUsageError("interpretation not possible: the string $input is not present in the obtained valid_input dictionary ($valid_input).") end
    return valid_input[LANG.EN_US][index]
end

interpret_digit(input::AbstractString) = (return DIGITS_MAPPING[default_language()][input])
interpret_count(input::AbstractString) = (return COUNTS_MAPPING[default_language()][input])
interpret_language(input::AbstractString) = (return LANGUAGES_MAPPING[default_language()][input])