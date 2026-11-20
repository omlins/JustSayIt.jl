"""
    @edit(path::AbstractString)

Prefix `path` with the JustSayIt application config path and then call `edit(path)`. If `path` is an absolute path, then call `edit` with `path` unmodified (for details about the Julia built-in `edit`, including how to specify a custom editor, type `?edit`).
"""
macro edit(args...) checkargs_edit(args...); _edit(__module__, args...); end

function _edit(caller::Module, path)
    path = esc(path)
    return quote
        if !isabspath($path)
            Base.edit($caller, joinpath(CONFIG_PREFIX, $path))
        else
            Base.edit($caller, $path)
        end
    end
end

checkargs_edit(args...) = if (length(args) != 1) @ArgumentError("wrong number of arguments.") end
