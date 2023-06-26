"""
    @edit(path::AbstractString)

Prefix `path` with the JustSayIt application config path and then call `edit(path)`. If `path` is an absolut path, then call `edit` with `path` unmodified.

!!! note "NOTE: JustSayIt application config"
    The content of the JustSayIt application config folder is not evaluated within JustSayIt. The folder's single purpose is to provide an easily accessible storage for scripts to start JustSayIt and/or for custom command functions: `@edit` permits to conveniently `edit` files from this folder (for details about the Julia built-in `edit` type `?edit`).
    Your JustSayIt application config path on this system is: `$CONFIG_PREFIX`
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
