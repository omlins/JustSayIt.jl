## FUNCTIONS

is_function(arg)           = isdef(arg)
is_call(arg)               = @capture(arg, f_(xs__))
is_symbol(arg)             = isa(arg, Symbol)
is_pair(arg)               = isa(arg, Expr) && (arg.head==:call) && (arg.args[1]==:(=>))
is_kwarg(arg)              = isa(arg, Expr) && (arg.head==:(=))
is_tuple(arg)              = isa(arg, Expr) && (arg.head==:tuple)
is_kwargexpr(arg)          = is_kwarg(arg) || ( (arg.head==:tuple) && all([is_kwarg(x) for x in arg.args]) )

function eval_arg(caller::Module, arg)
    try
        return @eval(caller, $arg)
    catch e
        @ArgumentEvaluationError("argument $arg could not be evaluated at parse time (in module $caller).")
    end
end


## TEMPORARY FUNCTION DEFINITIONS TO BE MERGED IN MACROTOOLS

isdef(ex)     = isshortdef(ex) || islongdef(ex)
islongdef(ex) = @capture(ex, function (fcall_ | fcall_) body_ end)
isshortdef(ex) = MacroTools.isshortdef(ex)


## FUNCTIONS FOR UNIT TESTING

macro prettyexpand(expr) return QuoteNode(remove_linenumbernodes!(macroexpand(__module__, expr; recursive=true))) end

function remove_linenumbernodes!(expr::Expr)
    expr = Base.remove_linenums!(expr)
    args = expr.args
    for i=1:length(args)
        if isa(args[i], LineNumberNode)
             args[i] = nothing
        elseif typeof(args[i]) == Expr
            args[i] = remove_linenumbernodes!(args[i])
        end
    end
    return expr
end

remove_linenumbernodes!(x::Nothing) = x
