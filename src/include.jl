"""
    @include(path::AbstractString)

Prefix `path` with the JustSayIt application config path and then call `include(path)`. If `path` is an absolute path, then call `include` with `path` unmodified (for details about the Julia built-in `include`, type `?include`).
"""
macro include(args...) checkargs_include(args...); _include(__module__, args...); end

function _include(caller::Module, path)
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
