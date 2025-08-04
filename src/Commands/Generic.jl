"""
Module Generic

Provides generic functions for any kind of operations.

# Functions

###### Command execution
- [`Generic.execute_n_times`](@ref)

To see a description of a function type `?<functionname>`.
"""
module Generic

using ..JustSayIt.API
import ..JustSayIt: execute
using ..Exceptions #TODO: remove this import after reimplementation
import ..JustSayIt: next_token, UNKNOWN_TOKEN #TODO: remove this import after reimplementation
public execute_n_times


## COMMAND FUNCTIONS

@doc """
    execute_n_times `n` `(complement of) cmd`

Execute a command n times.
"""
execute_n_times
@voiceargs n=>(valid_input=COUNTS, interpreter=interpret_count, use_max_speed=true) function execute_n_times(n::Int, commands::Dict{String,<:Any}; cmdname::String="do")
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
