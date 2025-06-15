function pretty_dict_string(dict::Dict{String,<:Any})
    key_length_max = maximum(length.(keys(dict)))
    return join([map(sort([keys(dict)...])) do x
                    join((x, dict[x]), " "^(key_length_max+1-length(x)) * "=> ")
                end...
                ], "\n")
end

pretty_cmd_string(cmd::Array)                 = join(map(pretty_cmd_string, cmd), "  ->  ")
pretty_cmd_string(cmd::Union{Tuple,NTuple})   = join(map(pretty_cmd_string, cmd), " + ")
pretty_cmd_string(cmd::PyObject)              = cmd.name
pretty_cmd_string(cmd::Dict)                  = "... => ..."
pretty_cmd_string(cmd)                        = string(cmd)
