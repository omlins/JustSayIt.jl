"""
    @voiceargs args function

Declare some or all arguments of the `function` definition to be arguments that can be obtained by voice.

# Arguments
- `args`: a voicearg, a pair `voicearg=>kwargs` or a tuple with multiple voiceargs, which can each have kwargs or not (see examples below).
- `function`: the function definition.
!!! note "Keyword arguments definable for each voice argument in `args`"
    - `model::String=MODELNAME.DEFAULT.<default_language>`: the name of the model to be used for the function argument (the name must be one of the keys of the modeldirs dictionary passed to `init_jsi`).
    - `modeltype::String=MODELNAME.DEFAULT`: the name of the model type to be used for the function argument (a IETF language tag, elsewhere selected, will be concatenated to the model type to form the model name; the model names constructed in this manner must be keys of the modeldirs dictionary passed to `init_jsi`).
    - `language::String=<default_language>`: the language (IETF language tag) to be used for the function argument (the model name will be constructed by concatenating the model type and the language).
    - `valid_input::AbstractVector{String}|NTuple{N,Pair{String,<:AbstractVector{String}}}|Dict{String,<:AbstractVector{String}`: the valid speech input (e.g. `["up", "down"]` or `("de" => ["rauf", "runter"], "en-us" => ["up", "down"], "fr" => ["haut", "bas"], "es" => ["arriba", "abajo"])`).
    - `valid_input_auto::Bool`: whether the valid speech input can automatically be derived from the type of the function argument.
    - `interpreter::Function`: a function to interpret the token (mapping a String to a different String).
    - `use_max_speed::Bool=false`: whether to use maxium speed for the recognition of the next token (rather than maximum accuracy). It is generally only recommended to set `use_max_speed=true` for single word commands or very specfic use cases that require immediate minimal latency action when a command is said.
    - `ignore_unknown::Bool=false`: whether to ignore unknown tokens in the speech (and consume the next instead). It is generally not recommended to set `ignore_unkown=true` - in particular not in combination with a limited valid input - as then the function will block until it receives a token it recognizes.
    - `timeout::AbstractFloat`: timeout (in seconds) after which to abort argument recognition.
    - `vararg_end::String`: a token to signal the end of a vararg (only valid if the function argument is a vararg).
    - `vararg_max::Integer=∞`: the maximum number of arguments the vararg can contain (only valid if the function argument is a vararg).

# Examples
```
@voiceargs (b, c) function f(a, b::String, c::String, d)
    #(...)
    return
end

@voiceargs (b=>(use_max_speed=true), c) function f(a, b::String, c::String, d)
    #(...)
    return
end

@enum TypeMode words formula
@voiceargs (mode=>(valid_input_auto=true), token=>(model=MODELNAME.TYPE.EN_US, timeout=2.0)) function type_tokens(mode::TypeMode, tokens::String...)
    #(...)
    return
end
```

See also: [`@voiceconfig`](@ref)
"""
macro voiceargs(args...) check_voiceargs_args(args...); handle_voiceargs(__module__, args...); end


## CONSTANTS

const USE_PARTIAL_RECOGNITIONS_DEFAULT = false
const USE_IGNORE_UNKNOWN_DEFAULT       = false
const TIMEOUT_DEFAULT                  = 60.0
const LANGUAGE_DEFAULT                 = :(default_language())


## ARGUMENT CHECKS

function check_voiceargs_args(args...)
    if (length(args) != 2) @ArgumentError("wrong number of arguments.") end
    if !(is_symbol(args[1]) || is_pair(args[1]) || is_tuple(args[1])) @ArgumentError("the first argument must be a voicearg, a pair `voicearg=>kwargs` or a tuple with multiple voiceargs, which can each have kwargs or not (obtained: $(args[1])).") end
    if !is_function(args[end]) @ArgumentError("the last argument must be a function definition (obtained: $(args[end])).") end
end


## VOICEARGS FUNCTIONS

function handle_voiceargs(caller::Module, voiceargs_arg::Union{Symbol,Expr}, f_expr::Expr)
    voiceargs_vect = extract_voiceargs(voiceargs_arg)
    simpleargs, complexargs_expr = split_args(voiceargs_vect)
    complexargs = split_complexargs(complexargs_expr)
    voiceargs = create_voiceargs_dict(simpleargs, complexargs)
    f_name, f_args = parse_signature(f_expr)
    eval_kwargs!(caller, voiceargs)
    validate_voiceargs(voiceargs, f_args)
    handle_valid_inputs!(caller, voiceargs, f_args)
    f_wrapper = wrap_f(f_name, f_args, f_expr, voiceargs)
    set_voiceargs(f_name, voiceargs)
    return quote
        $f_wrapper
        $(esc(f_expr))
    end
end

let
    global voiceargs, voicearg_f_names, recognizer, set_voiceargs, set_recognizer
    _f_voiceargs::Dict{Symbol, Dict{Symbol, Dict{Symbol, Any}}}                            = Dict{Symbol, Dict{Symbol, Dict{Symbol, Any}}}()
    voiceargs(f_name::Symbol)::Dict{Symbol, Dict{Symbol, Any}}                             = _f_voiceargs[f_name]
    voicearg_f_names()::Base.KeySet{Symbol, Dict{Symbol, Dict{Symbol, Dict{Symbol, Any}}}} = keys(_f_voiceargs)
    recognizer(f_name::Symbol, voicearg::Symbol)::Recognizer                               = _f_voiceargs[f_name][voicearg][:recognizer]
    set_voiceargs(f_name::Symbol, v::Dict{Symbol, Dict{Symbol, Any}})                      = (_f_voiceargs[f_name] = v; return)
    set_recognizer(f_name::Symbol, voicearg::Symbol, r::Recognizer)                        = (_f_voiceargs[f_name][voicearg][:recognizer] = r; return)
end


## FUNCTIONS TO DEAL WITH VOICEARGS PARSING

complexarg_key(complexarg)       = complexarg.args[2]
complexarg_kwargexpr(complexarg) = complexarg.args[3]

function extract_voiceargs(arg)
    if (is_symbol(arg) || is_pair(arg)) return [arg]
    elseif is_tuple(arg)                return arg.args
    else                                @ArgumentError("the argument does not contain voiceargs.")
    end
end

function extract_kwargs(arg)
    if is_kwarg(arg)     return Dict{Symbol, Any}(split_kwarg(arg))
    elseif is_tuple(arg) return Dict{Symbol, Any}(split_kwarg(x) for x in arg.args)
    else                 @KeywordArgumentError("the argument does not contain keyword arguments.")
    end
end

function split_kwarg(kwarg)
    if !is_kwarg(kwarg) @KeywordArgumentError("the argument is not a keyword arguments.") end
    @capture(kwarg, key_ = value_)
    return key => value
end

function split_args(args)
    simpleargs  = Symbol[x for x in args if is_symbol(x)]
    complexargs = Expr[x for x in args if is_pair(x)]
    invalidargs = [x for x in args if !is_symbol(x) && !is_pair(x)]
    if !isempty(invalidargs) @ArgumentError("one or multiple arguments are not valid:\nInvalid: $(join(invalidargs, "\nInvalid: "))") end
    return simpleargs, complexargs
end

function split_complexargs(complexargs_expr)
    if !all(is_pair.(complexargs_expr)) @ArgumentError("not all of complexargs_expr are `voicearg=>kwargs` pairs.") end
    if !all([is_kwargexpr(complexarg_kwargexpr(x)) for x in complexargs_expr]) @ArgumentError("not all keyword arguments are parsable") end
    return Dict{Symbol, Dict{Symbol, Any}}(complexarg_key(x) => extract_kwargs(complexarg_kwargexpr(x)) for x in complexargs_expr)
end

function create_voiceargs_dict(simpleargs, complexargs::Dict{Symbol, Dict{Symbol, Any}})
    return merge(complexargs, Dict{Symbol, Dict{Symbol, Any}}(x => Dict{Symbol, Any}() for x in simpleargs))
end

function parse_signature(f_expr)
    f_def  = splitdef(f_expr)
    f_name = f_def[:name]
    f_args = Dict(x[1] => Dict(:arg_type=>x[2], :slurp=>x[3], :default=>x[4]) for x in splitarg.(f_def[:args]))
    if !is_symbol(f_name) @ArgumentError("the function name $f_name in the function definition is not valid.") end
    for arg_name in keys(f_args)
        if !is_symbol(arg_name) @ArgumentError("the argument $arg_name in the function signature is not valid.") end
    end
    return f_name, f_args
end

function eval_kwargs!(caller::Module, voiceargs)
    for voicearg in keys(voiceargs)
        for kwarg in keys(voiceargs[voicearg])
            if isa(voiceargs[voicearg][kwarg], Union{Symbol,Expr})
                voiceargs[voicearg][kwarg] = eval_arg(caller, voiceargs[voicearg][kwarg])
            end
        end
    end
end

function validate_voiceargs(voiceargs, f_args)
    for voicearg in keys(voiceargs)
        if !haskey(f_args, voicearg) @ArgumentError("voicearg $(voicearg) is not part of the (positional) function arguments (keyword arguments cannot be voiceargs).") end
        for kwarg in keys(voiceargs[voicearg])
            if !haskey(VALID_VOICEARGS_KWARGS, kwarg) @KeywordArgumentError("keyword $(kwarg) of voicearg $(voicearg) is not valid.") end
            if !isa(voiceargs[voicearg][kwarg], VALID_VOICEARGS_KWARGS[kwarg]) @KeywordArgumentError("keyword argument $(kwarg)=$(voiceargs[voicearg][kwarg]) of voicearg $(voicearg) is of the wrong type (obtained type: $(typeof(voiceargs[voicearg][kwarg])); expected type: $(VALID_VOICEARGS_KWARGS[kwarg])).") end
        end
        if haskey(voiceargs[voicearg], :valid_input) && haskey(voiceargs[voicearg], :valid_input_auto) @IncoherentArgumentError("the keywords valid_input and valid_input_auto are incompatible. Set can set only one of them, not both.") end
        if (haskey(voiceargs[voicearg], :vararg_end) || haskey(voiceargs[voicearg], :vararg_max)) && !f_args[voicearg][:slurp] @KeywordArgumentError("the keywords vararg_end and vararg_max are only valid for vararg arguments (as, e.g., `args...`)") end
        if !haskey(voiceargs[voicearg], :vararg_end) && haskey(voiceargs[voicearg], :vararg_max) @IncoherentArgumentError("the keywords vararg_max is only valid in combination with vararg_end.") end
        if haskey(voiceargs[voicearg], :model) && (haskey(voiceargs[voicearg], :modeltype) || haskey(voiceargs[voicearg], :language)) @IncoherentArgumentError("the keyword model is incompatible with the keywords modeltype and language.") end
        # TODO: the following is to be removed
        # if !(haskey(voiceargs[voicearg], :vararg_end) || haskey(voiceargs[voicearg], :vararg_max)) &&  f_args[voicearg][:slurp] @ArgumentError("at least one of the keywords vararg_end and vararg_max must be set for vararg arguments (as, e.g., `args...`)") end
    end
end

# NOTE: This function requires that the voiceargs as given by the user have been validated (else it would randomly fail).
function handle_valid_inputs!(caller::Module, voiceargs, f_args)
    for voicearg in keys(voiceargs)
        if haskey(voiceargs[voicearg], :valid_input_auto) && (voiceargs[voicearg][:valid_input_auto] == true)
            type = eval_arg(caller, f_args[voicearg][:arg_type])
            voiceargs[voicearg][:valid_input] = generate_valid_input(type)
            if !isa(voiceargs[voicearg][:valid_input], VALID_VOICEARGS_KWARGS[:valid_input]) @ArgumentError("generation of valid input by type inspection failed for voicearg $voicearg (generated: $(voiceargs[voicearg][:valid_input])).") end
        elseif haskey(voiceargs[voicearg], :valid_input) && isa(voiceargs[voicearg][:valid_input], NTuple{N,Pair{String,<:AbstractVector{String}}} where {N})
            voiceargs[voicearg][:valid_input] = Dict(voiceargs[voicearg][:valid_input])
        end
    end
end

generate_valid_input(type::Type{<:Enum}) = [string.(instances(type))...]
generate_valid_input(type)               = @ArgumentError("type $(esc(type)) is not supported to define the valid input of a voicearg; currently supported are: Enum types. Other types can be supported by overloading `generate_valid_input`. Else, you can define the valid input explicitly witht the `valid_input` keyword argument.")

# Construct the wrapper based on the definition of the original function, as it will only differ in the arguments and body.
function wrap_f(f_name, f_args, f_expr, voiceargs)
    use_dynamic_recognizers = true
    use_static_recognizers  = true
    if haskey(ENV, "JSI_USE_DYNAMIC_RECOGNIZERS") use_dynamic_recognizers = (parse(Int64, ENV["JSI_USE_DYNAMIC_RECOGNIZERS"]) > 0); end
    if haskey(ENV, "JSI_USE_STATIC_RECOGNIZERS") use_static_recognizers = (parse(Int64, ENV["JSI_USE_STATIC_RECOGNIZERS"]) > 0); end

    # Generate the code for the recognition of the voiceargs.
    recognitions = fill(:(begin end), length(voiceargs))
    token        = gensym("token")
    tokengroup   = gensym("tokengroup")
    i = 1
    for voicearg in keys(voiceargs)
        kwargs                   = voiceargs[voicearg]
        language                 = haskey(kwargs,:language) ? kwargs[:language] : esc(:language)                   # NOTE: the runtime keyword argument sets the default (for all voice arguments at once); voice argument keywords override it for the specific voice argument.
        modeltype                = haskey(kwargs,:modeltype) ? kwargs[:modeltype] : esc(:modeltype)                # ...
        modelname                = haskey(kwargs,:model) ? kwargs[:model] : :(modelname($modeltype, $language))    # ...
        ignore_unknown           = haskey(kwargs,:ignore_unknown) ? kwargs[:ignore_unknown] : esc(:ignore_unknown) # ...
        use_partial_recognitions = haskey(kwargs,:use_max_speed) ? kwargs[:use_max_speed] : esc(:use_max_speed)    # ...
        timeout                  = haskey(kwargs,:timeout) ? kwargs[:timeout] : esc(:timeout)                      # ...
        f_arg                    = f_args[voicearg]
        f_name_sym               = :(Symbol($(string(f_name))))
        voicearg_sym             = :(Symbol($(string(voicearg))))
        voicearg_esc             = esc(voicearg)
        is_vararg                = f_args[voicearg][:slurp]
        if haskey(kwargs, :model)
            language  = :(modellang($(kwargs[:model]))) # NOTE: the language is derived from the model name if the model keyword is set.
            modeltype = :(modeltype($(kwargs[:model]))) # NOTE: the modeltype is derived from the model name if the model keyword is set.
        end
        if haskey(kwargs, :valid_input)
            valid_input = isa(kwargs[:valid_input],AbstractVector{String}) ? kwargs[:valid_input] : :($(kwargs[:valid_input])[$language])
            # TODO: the static recognizer cannot support multiple languages: it currently just uses the default language, which could be fine if one would say we just give an error if the wrong language is requested. But it is only fine if this does not happen ever if there are no environment flags set.
            if (use_dynamic_recognizers) recognizer_or_info = :(($f_name_sym, $voicearg_sym, $valid_input, $modelname))
            else                         recognizer_or_info = :(recognizer($f_name_sym, $voicearg_sym))
            end
        else
            if (use_static_recognizers) recognizer_or_info = :(recognizer($modelname))
            #TODO: this is currently hard coded to use vosk and should later be able to use both backends:
            else                        recognizer_or_info = :(Recognizer(Vosk.KaldiRecognizer(model($modelname), SAMPLERATE), false))
            end
        end
        if is_vararg && haskey(kwargs, :vararg_end)
            has_timed_out = gensym("has_timed_out")
            conditions = :(!$has_timed_out) # NOTE: the timeout check shall always remain the first condition in order not to wait e.g. for an end keyword that is never coming...
            if haskey(kwargs, :vararg_max)
                vararg_max = kwargs[:vararg_max]
                reached_max = :(length($voicearg_esc) == $vararg_max)
                conditions = (conditions!=:()) ? :($conditions && !$reached_max) : :(!$reached_max)
            end
            if haskey(kwargs, :vararg_end) # NOTE: the end keyword check shall always remain the last condition in order not to wait for an end keyword that is never coming...
                vararg_end = kwargs[:vararg_end]
                is_end = :(_is_next($vararg_end, $recognizer_or_info, noises($modelname); consume_if_match=true, use_partial_recognitions=$use_partial_recognitions))
                conditions = (conditions!=:()) ? :($conditions && !$is_end) : :(!$is_end)
            end
            recognition = quote
                $voicearg_esc = []
                $has_timed_out = false
                while $conditions
                    $token = next_token($recognizer_or_info, noises($modelname); timeout=$timeout, use_partial_recognitions=$use_partial_recognitions, ignore_unknown=$ignore_unknown)
                    if ($token == UNKNOWN_TOKEN) @InsecureRecognitionException("@voiceargs: argument not recognised.") end
                    push!($voicearg_esc, $(interpret_and_parse_calls(token, kwargs, f_arg)))
                    $has_timed_out = ($token == "")
                end
            end
        elseif is_vararg # default vararg behaviour
            recognition = quote
                $tokengroup = next_tokengroup($recognizer_or_info, noises($modelname); timeout=$timeout, use_partial_recognitions=$use_partial_recognitions, ignore_unknown=$ignore_unknown)
                if any($tokengroup .== UNKNOWN_TOKEN) @InsecureRecognitionException("@voiceargs: argument not recognised.") end
                if any($tokengroup .== "") @InsecureRecognitionException($("time out waiting for voice argument $voicearg in function $f_name.")) end
                $voicearg_esc = map(x -> $(interpret_and_parse_calls(:x, kwargs, f_arg)), $tokengroup)
                if $language != default_language() reset_all() end
            end 
        else
            recognition = quote
                $token = next_token($recognizer_or_info, noises($modelname); timeout=$timeout, use_partial_recognitions=$use_partial_recognitions, ignore_unknown=$ignore_unknown)
                if ($token == UNKNOWN_TOKEN) @InsecureRecognitionException("@voiceargs: argument not recognised.") end
                if ($token == "") @InsecureRecognitionException($("time out waiting for voice argument $voicearg in function $f_name.")) end
                $voicearg_esc = $(interpret_and_parse_calls(token, kwargs, f_arg))
            end
        end
        recognitions[i] = recognition
        i += 1
    end
    voiceargs_recognition = quote $(recognitions...) end

    # Generate the call of the original function.
    f_def = splitdef(f_expr)
    f_call_args = [splitarg(x)[3] ? :($(splitarg(x)[1])...) : splitarg(x)[1] for x in f_def[:args]] # NOTE: the f_args dict is not used here as it does not preserve the argument order.
    f_call_kwargs = [:($(splitarg(x)[1]) = $(splitarg(x)[1])) for x in f_def[:kwargs]]
    f_call = :($(esc(f_name))($(esc.(f_call_args)...); $(esc.(f_call_kwargs)...)))

    # Assign new arguments and body, and escape the other parts of the function definition.
    f_def[:name]        = esc(f_def[:name])
    f_def[:kwargs]      = (esc.(f_def[:kwargs])..., Expr(:kw, :($(esc(:modeltype))::$(VALID_VOICEARGS_KWARGS[:modeltype])), MODELTYPE_DEFAULT), Expr(:kw, :($(esc(:language))::$(VALID_VOICEARGS_KWARGS[:language])), LANGUAGE_DEFAULT), Expr(:kw, :($(esc(:timeout))::$(VALID_VOICEARGS_KWARGS[:timeout])), TIMEOUT_DEFAULT), Expr(:kw, :($(esc(:use_max_speed))::$(VALID_VOICEARGS_KWARGS[:use_max_speed])), USE_PARTIAL_RECOGNITIONS_DEFAULT), Expr(:kw, :($(esc(:ignore_unknown))::$(VALID_VOICEARGS_KWARGS[:ignore_unknown])), USE_IGNORE_UNKNOWN_DEFAULT)) #TODO: give an error if these keyword arguments are set by the user.
    f_def[:whereparams] = esc.(f_def[:whereparams])
    f_def[:args]        = [esc(x) for x in f_def[:args] if !haskey(voiceargs, splitarg(x)[1])] # The voiceargs will not be part of the wrapper function signature.
    f_def[:body]        = quote
        $voiceargs_recognition
        $f_call
    end
    return combinedef(f_def)
end

function interpret_and_parse_calls(input, kwargs, f_arg)
    type = esc(f_arg[:arg_type])
    if haskey(kwargs, :interpreter)
        interpreter = esc(kwargs[:interpreter])
        return :(parse($type, $interpreter($input)))
    else
        return :(parse($type, $input))
    end
end

import Base.parse

parse(type::Type{String}, val::AbstractString) = string(val)

function parse(type::Type{<:Enum}, val::AbstractString)
    parser = Dict(string(x) => x for x in instances(type))
    if !haskey(parser, val)
        reset_all()
        @InsecureRecognitionException("Insecurity in recognition: token '$val' was not expected (it is not parsable to type '$type')")
    end
    return parser[val]
end
