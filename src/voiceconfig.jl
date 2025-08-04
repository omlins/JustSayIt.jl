"""
    @voiceconfig kwargs call
    @voiceconfig kwargs symbol

Define voice recognition keyword arguments for all arguments of a function call or function symbol; recognition keyword arguments defined explicitly in a `@voiceargs` function definition precede those defined with `@voiceconfig`. See the `@voiceargs` macro for the valid keyword arguments.

# Arguments
- `kwargs`: a keyword argument or a named tuple of keyword arguments (e.g., `language="de"` or `(language="de", timeout=10.0)`).
- `call`: a function call expression (e.g., `f(x, y=3)`) or a function symbol (e.g., `f`).
- `symbol`: a function symbol (e.g., `f`).

# Examples
```
@voiceconfig language="de" f(x; y=3)

@voiceconfig language="de" f

@voiceconfig (language="de", timeout=10.0) f(x; y=3)

@voiceconfig (language="de", timeout=10.0) f
```

See also: [`@voiceargs`](@ref)
"""
macro voiceconfig(args...) check_voiceconfig_args(args...); handle_voiceconfig(__module__, args...); end


## ARGUMENT CHECKS

function check_voiceconfig_args(args...)
    if (length(args) != 2) @ArgumentError("wrong number of arguments.") end # NOTE: the first argument is not verified at parse time to allow any expression that gives the right type at runtime. A parse time check could be done as follows # if !(is_tuple(args[1]) || is_kwarg(args[1])) @ArgumentError("the first argument must be a keyword argument or a named tuple consisting of keyword arguments (obtained: $(args[1])).") end
    if !(is_call(args[2]) || is_symbol(args[2]) || (isa(args[2], Expr) && (args[2].head == :.))) @ArgumentError("the second argument must be a function call or a function symbol (obtained: $(args[2])).") end
end


## VOICECONFIG FUNCTIONS

function handle_voiceconfig(caller::Module, kwargs_expr::Union{Symbol,Expr}, call_or_f::Expr)
    if is_call(call_or_f) handle_voiceconfig_call(kwargs_expr, call_or_f)
    else                  handle_voiceconfig_f(caller, kwargs_expr, call_or_f)
    end
end

function handle_voiceconfig_call(kwargs_expr::Union{Symbol,Expr}, call::Expr)
    kwargs_expr = esc(kwarg_to_namedtuple(kwargs_expr))
    if @capture(call, f_(args__; kwargs__))
        f, args, kwargs = esc(f), esc.(args), esc.(kwargs)
        f_call = :($f($(args...); $(kwargs...), validate_voiceconfig($kwargs_expr)...))
    elseif @capture(call, f_(args__))
        f, args = esc(f), esc.(args)
        f_call = :($f($(args...); JustSayIt.validate_voiceconfig($kwargs_expr)...))
    else
        @APIUsageError("the second argument must be a function call or a function symbol.")
    end
    return f_call
end

function handle_voiceconfig_f(caller::Module, kwargs_expr::Union{Symbol,Expr}, f::Union{Symbol,Expr})
    if isa(f, Expr) && !(f.head == :.) @APIUsageError("the second argument must be a function call or a function symbol (obtained: $(f)).") end
    kwargs_expr = kwarg_to_namedtuple(kwargs_expr)
    kwarg_val   = eval_arg(caller, kwargs_expr)
    if !isa(kwarg_val, NamedTuple) @ArgumentError("the first argument must be a keyword argument or a named tuple consisting of keyword arguments (obtained: $(kwarg_val)).") end
    f_gateway = :((args...; kwargs...) -> $f(args...; kwargs..., validate_voiceconfig($kwarg_val)...))
    return f_gateway
end

kwarg_to_namedtuple(kwarg_expr::Expr) = :((; $kwarg_expr)) # Convert single kwarg to a named tuple


# RUNTIME FUNCTIONS

function validate_voiceconfig(kwargs::NamedTuple)
    for (kwarg, value) in pairs(kwargs)
        if !haskey(VALID_VOICECONFIG_KWARGS, kwarg)
            @KeywordArgumentError("keyword $(kwarg) is not a valid voice configuration parameter.")
        end 
        if !isa(value, VALID_VOICECONFIG_KWARGS[kwarg])
            @KeywordArgumentError("keyword argument $(kwarg)=$(value) is of the wrong type (obtained type: $(typeof(value)); expected type: $(VALID_VOICECONFIG_KWARGS[kwarg])).")
        end
    end
    return kwargs
end

validate_voiceconfig(kwargs) = @ArgumentError("validate_voiceconfig requires a NamedTuple argument, got $(typeof(kwargs)). Use (; key1=val1, key2=val2, ...) format.")
