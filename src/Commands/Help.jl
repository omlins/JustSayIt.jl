"""
Module Help

Provides functions for displaying help about the commands during speech recognition.

# Functions
- [`Help.help`](@ref)

To see a description of a function type `?<functionname>`.
"""
module Help

using ..JustSayIt.API
import ..JustSayIt: command, command_names, pretty_cmd_string, PyKey
using ..JustSayIt: next_token #TODO: remove this import after reimplementation
public help


const COMMANDS_KEYWORDS = Dict(LANG.DE    => "kommandos",
                               LANG.EN_US => "commands",
                               LANG.ES    => "comandos",
                               LANG.FR    => "commandes",
                               )

"Show help for your commands or a spoken command or module."
function help()
    valid_input = [COMMANDS_KEYWORDS[default_language()], command_names()...]
    keyword = next_token(valid_input; ignore_unknown=false)
    help(keyword)
end

function help(keyword; debugonly::Bool=false)
    if keyword == COMMANDS_KEYWORDS[default_language()]
        cmd_length_max = maximum(length.(command_names()))
        msg = join(["", "Your commands:",
                    map(sort([command_names()...])) do x
                       join((x, pretty_cmd_string(command(x))), " "^(cmd_length_max+1-length(x)) * "=> ")
                    end...
                    ], "\n")
    elseif keyword in command_names()
        cmd = command(keyword)
        if isa(cmd, Function)
            msg = ""
            if (debugonly) @debug "Command $keyword" ""=Base.Docs.doc(cmd)
            else           @info  "Command $keyword" ""=Base.Docs.doc(cmd)
            end
        elseif isa(cmd, PyKey)
            msg = "Command $keyword\n   =   Keyboard key $(pretty_cmd_string(cmd))"
        elseif isa(cmd, String)
            msg = "Command $keyword\n   =   Type word $(pretty_cmd_string(cmd))"
        elseif isa(cmd, Dict)
            msg = "Command $keyword\n   =   Activate additional commands for $keyword"
        elseif isa(cmd, Array)
            msg = "Command $keyword\n   =   Command sequence $(pretty_cmd_string(cmd))"
        else
            msg = "Command $keyword\n   =   Keyboard shortcut $(pretty_cmd_string(cmd))"
        end
    else
        msg = "Help search keyword not recognized."
    end
    if !isempty(msg)
        if (debugonly) @debug msg
        else           @info msg
        end
    end
    return
end

end # module Help
