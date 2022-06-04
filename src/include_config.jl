"""
    @include_config(path::AbstractString)

Prefix `path` with the JustSayIt application config path and then call `include(path)`. If `path` is an absolut path, then call `include` with `path` unmodified.

!!! note "NOTE: JustSayIt application config"
    The content of the JustSayIt application config folder is not evaluated within JustSayIt. The folder's single purpose is to provide an easily accessible storage for scripts to start JustSayIt and/or for custom command functions: `@include_config` permits to conveniently `include` files from this folder (for details about the Julia built-in `include` type `?include`).
    Your JustSayIt application config path on this system is: `$CONFIG_PREFIX`
"""
macro include_config(args...) checkargs_include(args...); include_config(__module__, args...); end

function include_config(caller::Module, path)
    path = esc(path)
    return quote
        if !isabspath($path)
            Base.include($caller, joinpath(CONFIG_PREFIX, $path))
        else
            Base.include($caller, $path)
        end
    end
end

checkargs_include(args...) = if (length(args) != 1) @ArgumentError("wrong number of arguments.") end
