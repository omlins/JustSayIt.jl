"""
Module Generic

Provides generic functions for any kind of operations.

# Functions

###### execute n times
- [`Generic.execute_n_times`](@ref)

To see a description of a function type `?<functionname>`.
"""
module Generic

using ..Exceptions
import ..JustSayIt: @voiceargs, default_language, next_token, execute, LANG, COUNTS, UNKNOWN_TOKEN


## CONSTANTS


## FUNCTIONS

interpret_count(input::AbstractString) = (return COUNTS[default_language()][input])

@doc """
    execute_n_times `n` `(complement of) cmd`

Execute a command n times.
"""
execute_n_times
@voiceargs n=>(valid_input=(LANG.DE=>[keys(COUNTS[LANG.DE])...], LANG.EN_US=>[keys(COUNTS[LANG.EN_US])...], LANG.ES=>[keys(COUNTS[LANG.ES])...], LANG.FR=>[keys(COUNTS[LANG.FR])...]), interpret_function=interpret_count, use_max_speed=true) function execute_n_times(n::Int, commands::Dict{String,<:Any}; cmdname::String="do")
    # count = parse(Int, token) # NOTE: this is safe as the count is always an integer.
    cmd_complement = next_token([keys(commands)...]; ignore_unknown=false)
    if (cmd_complement == UNKNOWN_TOKEN) @InsecureRecognitionException("unknown command.") end
    @info "$cmdname $n $cmd_complement."
    cmd = commands[cmd_complement]
    for i in 1:n
        execute(cmd, cmdname)
    end
end


end # module Generic
