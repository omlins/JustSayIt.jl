import Pkg, Downloads, ProgressMeter, Preferences
using PyCall, Conda, JSON, MacroTools, PromptingTools
import MacroTools: splitdef, combinedef
const PT = PromptingTools


## PYTHON MODULES
const Vosk        = PyNULL()
const Sounddevice = PyNULL()
const Wave        = PyNULL()
const Scipy       = PyNULL()
const Numpy       = PyNULL()
const Zipfile     = PyNULL()
const Pynput      = PyNULL()
const Key         = PyNULL()
const Pywinctl    = PyNULL()
const Ollama      = PyNULL()
const Torch       = PyNULL()
const RealtimeTTS = PyNULL()
const RealtimeSTT = PyNULL()
const Transcriber = PyNULL()


function __init__()
    if !haskey(ENV, "JSI_USE_PYTHON") ENV["JSI_USE_PYTHON"] = "1" end
    if ENV["JSI_USE_PYTHON"] == "1"                                     # ENV["JSI_USE_PYTHON"] = "0" enables to deactivate the setup of Python related things at module load time, e.g. for the docs build.
        do_restart = false
        ENV["CONDA_JL_USE_MINIFORGE"] = "1"                             # Force usage of miniforge
        if !Conda.USE_MINIFORGE
            @info "Rebuilding Conda.jl for using Miniforge..."
            Pkg.build("Conda")
            do_restart = true
        end
        ENV["PYTHON"] = ""                                              # Force PyCall to use Conda.jl
        if !any(startswith.(PyCall.python, DEPOT_PATH))                 # Rebuild of PyCall if it has not been built with Conda.jl
            @info "Rebuilding PyCall for using Julia Conda.jl and installing/updating Conda..."
            Conda.update()                                             # Update Conda.jl; ensures also that miniforge gets installed before it is potentially used in a situation where it is expected to be installed (config / pip_interop...?)
            Pkg.build("PyCall")
            do_restart = true
        end
        if do_restart
            @info "...rebuild completed. Restart Julia and JustSayIt."
            exit()
        end
        copy!(Vosk,        pyimport_pip("vosk"))
        copy!(Sounddevice, pyimport_pip("sounddevice"; dependencies=["portaudio"]))
        copy!(Wave,        pyimport("wave"))
        copy!(Scipy,       pyimport_pip("scipy"))
        copy!(Numpy,       pyimport_pip("numpy"))
        copy!(Zipfile,     pyimport("zipfile"))
        copy!(Pynput,      pyimport_pip("pynput"))
        copy!(Key,         Pynput.keyboard.Key)
        copy!(Pywinctl,    pyimport_pip("pywinctl"))
        copy!(Ollama,      pyimport_pip("ollama"))
        # if startswith(get_cuda_version(), "11.")
            # Conda.pip("uninstall --yes", ["ctranslate2", "nvidia-cublas-cu12", "nvidia-cudnn-cu12", "nvidia-cublas-cu11", "nvidia-cudnn-cu11"])
            # pyimport_pip("nvidia.cublas"; modulename_pip="nvidia-cublas-cu11")
            # pyimport_pip("nvidia.cudnn"; modulename_pip="nvidia-cudnn-cu11==8.*")

            # Conda.pip("uninstall --yes", "ctranslate2")
            # pyimport_pip("ctranslate2"; modulename_pip="ctranslate2==3.24.0")
        # end
        # kokoro requires a driver update!
        if get_cuda_version() != ""  # Install Torch with CUDA support if available (for RealtimeTTS)
            try 
                copy!(Torch, pyimport("torch"))
            catch e
            end
            if (Torch==PyNULL()) || !(Torch.cuda.is_available())
                Conda.pip("uninstall --yes", ["torch", "torchvision", "torchaudio"])
            end
            # if startswith(get_cuda_version(), "11.")
                copy!(Torch, pyimport_pip("torch", args_pip="--index-url=https://download.pytorch.org/whl/cu118"; modulename_pip="torch==2.3.0")) #; dependencies=["pytorch-cuda=11.8"]))
                pyimport_pip("torchvision", args_pip="--index-url=https://download.pytorch.org/whl/cu118"; modulename_pip="torchvision==0.18.0")
                pyimport_pip("torchaudio", args_pip="--index-url=https://download.pytorch.org/whl/cu118"; modulename_pip="torchaudio==2.3.0")
            # else
            #    copy!(Torch, pyimport_pip("torch", args_pip="--index-url=https://download.pytorch.org/whl/$(get_torch_cuda_version())"; dependencies=["pytorch-cuda"]))
            #    pyimport_pip("torchvision", args_pip="--index-url=https://download.pytorch.org/whl/$(get_torch_cuda_version())")
            #    pyimport_pip("torchaudio", args_pip="--index-url=https://download.pytorch.org/whl/$(get_torch_cuda_version())")
            # end
        end
        copy!(RealtimeSTT, pyimport_pip("RealtimeSTT"; dependencies=["ffmpeg"], force_dependencies=true))
        copy!(RealtimeTTS, pyimport_pip("RealtimeTTS"; modulename_pip="realtimetts[system, kokoro]", dependencies=["pyaudio"], force_dependencies=true)) # NOTE: PyAudio fails to install with pip; so, it is installed with Conda...
        @pyinclude(joinpath(@__DIR__, "transcriber.py"))
        copy!(Transcriber, py"Transcriber")
    end
end


## CONSTANTS

const DEFAULT_MODEL_REPO      = "https://alphacephei.com/vosk/models"
const SAMPLERATE              = 16000 #44100 #48000 #16000       #[Hz]
const AUDIO_IO_CHANNELS       = 1
const AUDIO_ALLOC_GRANULARITY = 1024^2      #[bytes]
const AUDIO_HISTORY_MIN       = 1024^2      #[bytes]
const AUDIO_READ_MAX          = 512         #[bytes]
const AUDIO_ELTYPE            = Int16       # NOTE: This must be as required by the STT models and must be the same as the chunk type used in TTS wite_to_stdout.
const AUDIO_ELTYPE_STR        = lowercase(string(AUDIO_ELTYPE))
const AUDIO_BLOCKSIZE         = Int(AUDIO_READ_MAX/sizeof(AUDIO_ELTYPE))
const COMMAND_ABORT           = "abortus"
const VARARG_END              = "terminus"
const COMMAND_RECOGNIZER_ID   = ""          # NOTE: This is a safe ID as it cannot be taken by any model (raises error).
const DEFAULT_RECORDER_ID     = "__default__"
const DEFAULT_READER_ID       = "__default__"
const MODELTYPE_DEFAULT       = "__default__"
const MODELTYPE_SPEECH        = "__speech__"
const UNKNOWN_TOKEN           = "[unk]"
const PyKey                   = Union{Char, PyObject}
const VALID_VOICEARGS_KWARGS  = Dict(:model=>String, :modeltype=>String, :language=>String, :valid_input=>Union{AbstractVector{String}, NTuple{N,Pair{String,<:AbstractVector{String}}} where {N}, Dict{String,<:AbstractVector{String}}}, :valid_input_auto=>Bool, :interpreter=>Function, :timeout=>AbstractFloat, :use_max_speed=>Bool, :vararg_end=>String, :vararg_max=>Integer, :ignore_unknown=>Bool)
const VALID_VOICECONFIG_KWARGS = Dict(:modeltype=>String, :language=>String, :timeout=>AbstractFloat, :use_max_speed=>Bool, :ignore_unknown=>Bool)

const STT_DEFAULT_FREESPEECH_ENGINE = "faster-whisper"
const STT_DEFAULT_FREESPEECH_ENGINE_CPU = "vosk"
const LLM_DEFAULT_LOCALMODEL     = "gemma3:1b" #"phi:2.7b" #"phi4-mini:3.8b" #"mistral:7b-instruct"
const LLM_DEFAULT_REMOTEMODEL    = "gpt-4o-mini"
const TTS_SUPPORTED_LOCALENGINES = Dict("system" => PyNULL(), "kokoro" => PyNULL(), "orpheus" => PyNULL()) # NOTE: this can only be constructed at runtime
const TTS_DEFAULT_ENGINE         = "kokoro"
const TTS_DEFAULT_ENGINE_CPU     = "system"
const TTS_DEFAULT_STREAM         = "__default__"
const TTS_FILE_STREAM            = "__file__"
const TTS_FILE_PLAY_STREAM       = "__file_play__"


@static if Sys.iswindows()
    const JSI_DATA            = joinpath(ENV["APPDATA"], "JustSayIt")
    const MODELDIR_PREFIX     = joinpath(JSI_DATA, "models")
    const CONFIG_PREFIX       = joinpath(JSI_DATA, "config")
elseif Sys.isapple()
    const JSI_DATA            = joinpath(homedir(), "Library", "Application Support", "JustSayIt")
    const MODELDIR_PREFIX     = joinpath(JSI_DATA, "models")
    const CONFIG_PREFIX       = joinpath(JSI_DATA, "config")
else
    const MODELDIR_PREFIX     = joinpath(homedir(), ".local", "share", "JustSayIt", "models")
    const CONFIG_PREFIX       = joinpath(homedir(), ".config", "JustSayIt")
end
const VOSK_MODELDIR_PREFIX  = joinpath(MODELDIR_PREFIX, "vosk")
const RSTT_MODELDIR_PREFIX = joinpath(MODELDIR_PREFIX, "realtimestt")


# (FUNCTIONS USED IN CONSTANT DEFINITIONS)

lang_str(code::String)                                = LANG_STR[code]
modelname(modeltype::String, language::String="auto") = modeltype * "-" * language

function modeltype(modelname::String)
    if     startswith(modelname, MODELTYPE_DEFAULT) return MODELTYPE_DEFAULT
    elseif startswith(modelname, MODELTYPE_SPEECH)    return MODELTYPE_SPEECH
    else                                            @APIUsageError("invalid modelname (obtained: \"$modelname\").")
    end
end

modellang(modelname::String) = split(modelname, "-")[2]


# (HIERARCHICAL CONSTANTS)

"Constant named tuple containing names of available languages."
const LANG = (DE    = "de",
              EN_US = "en-us",
              ES    = "es",
              FR    = "fr",
             )
const COMMAND_NAME_SLEEP = Dict(LANG.DE    => "schlaf",
                                LANG.EN_US => "sleep",
                                LANG.ES    => "duerme",
                                LANG.FR    => "dors",
                                )
const COMMAND_NAME_AWAKE = Dict(LANG.DE    => "erwache",
                                LANG.EN_US => "awake",
                                LANG.ES    => "despierta",
                                LANG.FR    => "reveille",
                                )
const LANG_STR = Dict(LANG.DE    => "German",
                      LANG.EN_US => "English (United States)",
                      LANG.ES    => "Spanish",
                      LANG.FR    => "French",
                      )
const NOISES = (DE    = String[],
                EN_US = String["huh"],
                ES    = String[],
                FR    = String["hum"],
               )
"Constant named tuple containing modelnames for available languages."
const MODELNAME = (DEFAULT = (; zip(keys(LANG), modelname.(MODELTYPE_DEFAULT, values(LANG)))...),
                   TYPE    = (; zip(keys(LANG), modelname.(MODELTYPE_SPEECH, values(LANG)))..., 
                                AUTO = modelname(MODELTYPE_SPEECH) 
                             ),
                  )
const DEFAULT_VOSK_MODELDIRS = Dict(MODELNAME.DEFAULT.DE    => joinpath(VOSK_MODELDIR_PREFIX, "vosk-model-small-de-0.15"),
                                    MODELNAME.DEFAULT.EN_US => joinpath(VOSK_MODELDIR_PREFIX, "vosk-model-small-en-us-0.15"),
                                    MODELNAME.DEFAULT.ES    => joinpath(VOSK_MODELDIR_PREFIX, "vosk-model-small-es-0.22"),
                                    MODELNAME.DEFAULT.FR    => joinpath(VOSK_MODELDIR_PREFIX, "vosk-model-small-fr-0.22"),
                                    MODELNAME.TYPE.DE       => joinpath(VOSK_MODELDIR_PREFIX, "vosk-model-de-0.21"),
                                    MODELNAME.TYPE.EN_US    => joinpath(VOSK_MODELDIR_PREFIX, "vosk-model-en-us-daanzu-20200905"),
                                    MODELNAME.TYPE.ES       => "",                   # NOTE: Currently no large model for ES available.
                                    MODELNAME.TYPE.FR       => joinpath(VOSK_MODELDIR_PREFIX, "vosk-model-fr-0.22"),
                                    )
const DEFAULT_WHISPER_MODELDIRS = Dict(MODELNAME.TYPE.DE    => joinpath(RSTT_MODELDIR_PREFIX, "tiny"), #TODO: to be seen how to handle
                                       MODELNAME.TYPE.EN_US => joinpath(RSTT_MODELDIR_PREFIX, "tiny"),
                                       MODELNAME.TYPE.ES    => joinpath(RSTT_MODELDIR_PREFIX, "tiny"),
                                       MODELNAME.TYPE.FR    => joinpath(RSTT_MODELDIR_PREFIX, "tiny"),
                                       MODELNAME.TYPE.AUTO  => joinpath(RSTT_MODELDIR_PREFIX, "tiny"),
                                      )
const DEFAULT_NOISES    = Dict(MODELNAME.DEFAULT.DE    => NOISES.DE,
                               MODELNAME.DEFAULT.EN_US => NOISES.EN_US,
                               MODELNAME.DEFAULT.ES    => NOISES.ES,
                               MODELNAME.DEFAULT.FR    => NOISES.FR,
                               MODELNAME.TYPE.DE       => NOISES.DE,
                               MODELNAME.TYPE.EN_US    => NOISES.EN_US,
                               MODELNAME.TYPE.ES       => NOISES.ES,
                               MODELNAME.TYPE.FR       => NOISES.FR,
                               )
const LATIN_ALPHABET = string.('a':'z')
const LANG_SYMBOLS   = [values(LANG)...]
const DIGITS_SYMBOLS = [string.('0':'9')..., ".", ",", " "]
const COUNTS_SYMBOLS = [string.('1':'9')..., "10", "50", "100", "1000"]

const LANGUAGES = Dict(
    LANG.DE    => ["deutsch", "englisch", "spanisch", "französisch"],
    LANG.EN_US => ["german", "english", "spanish", "french"],
    LANG.ES    => ["alemán", "inglés", "español", "francés"],
    LANG.FR    => ["allemand", "anglais", "espagnol", "français"],
)
const ALPHABET = Dict(
    LANG.DE    => LATIN_ALPHABET,
    LANG.EN_US => LATIN_ALPHABET,
    LANG.ES    => LATIN_ALPHABET,
    LANG.FR    => LATIN_ALPHABET,
)
const DIGITS = Dict(
    LANG.DE    => ["null", "eins", "zwei", "drei", "vier", "fünf", "sechs", "sieben", "acht", "neun", "punkt", "komma", "leerzeichen"],
    LANG.EN_US => ["zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "dot", "comma", "space"],
    LANG.ES    => ["cero", "uno", "dos", "tres", "cuatro", "cinco", "seis", "siete", "ocho", "nueve", "punto", "coma", "espacio"],
    LANG.FR    => ["zéro", "un", "deux", "trois", "quatre", "cinq", "six", "sept", "huit", "neuf", "point", "virgule", "espace"],
)
const COUNTS = Dict(
    LANG.DE    => ["eins", "zwei", "drei", "vier", "fünf", "sechs", "sieben", "acht", "neun", "zehn", "fünfzig", "hundert", "tausend"],
    LANG.EN_US => ["one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten", "fifty", "hundred", "thousand"],
    LANG.ES    => ["uno", "dos", "tres", "cuatro", "cinco", "seis", "siete", "ocho", "nueve", "diez", "cincuenta", "cien", "mil"],
    LANG.FR    => ["un", "deux", "trois", "quatre", "cinq", "six", "sept", "huit", "neuf", "dix", "cinquante", "cent", "mille"],
)

const DIGITS_MAPPING = Dict(
    lang => Dict(word => DIGITS_SYMBOLS[i] for (i, word) in enumerate(words))
    for (lang, words) in DIGITS
)
const COUNTS_MAPPING = Dict(
    lang => Dict(word => COUNTS_SYMBOLS[i] for (i, word) in enumerate(words))
    for (lang, words) in COUNTS
)
const LANGUAGES_MAPPING = Dict(
    lang => Dict(word => LANG_SYMBOLS[i] for (i, word) in enumerate(words))
    for (lang, words) in LANGUAGES
)


merge_recursively(x::AbstractDict...) = merge(merge_recursively, x...) # NOTE: this function needs to be defined before it's usage below.
merge_recursively(x...) = x[end]


## FUNCTIONS

function pyimport_pip(modulename::AbstractString; dependencies::AbstractArray=[], channel::AbstractString="conda-forge", force_dependencies::Bool=false, modulename_pip::AbstractString="", args_pip::AbstractString="")
    modulename_pip = isempty(modulename_pip) ? modulename : modulename_pip
    args_pip = isempty(args_pip) ? "" : " $args_pip"
    try
        pyimport(modulename)
    catch e
        if isa(e, PyCall.PyError)
            if !(force_dependencies && !isempty(dependencies)) # If the dependencies installation has to be forced, we skip trying without dependencies.
                Conda.pip_interop(true)
                Conda.pip("install$args_pip", modulename_pip)
            end
            try
                pyimport(modulename)
            catch e
                if isa(e, PyCall.PyError) && (!isempty(dependencies)) # If the module import still failed after installation, try installing the dependencies with Conda first.
                    Conda.pip("uninstall --yes", modulename_pip)
                    for dependency in dependencies
                        Conda.add(dependency; channel=channel)
                    end
                    Conda.pip("install$args_pip", modulename_pip)
                    pyimport(modulename)
                else
                    rethrow(e)
                end
            end
        else
            rethrow(e)
        end
    end
end

function pyimport_pip(symbol::Symbol, pymodule::PyObject, symbolname_pip::AbstractString; args_pip::AbstractString="")
    args_pip = isempty(args_pip) ? "" : " $args_pip"
    try
        getproperty(pymodule, symbol)
    catch
        Conda.pip_interop(true)
        Conda.pip("install$args_pip", symbolname_pip)
        getproperty(pymodule, symbol)
    end
end


let
    global tic, toc
    t0::Union{Float64,Nothing} = nothing

    tic()::Float64            = ( t0 = time() )
    toc()::Float64            = ( time() - t0 )
    toc(t1::Float64)::Float64 = ( time() - t1 )
end


clean_token(s::AbstractString) = lowercase(replace(s, r"[^\w\s']" => "")) # Remove all non-word characters except whitespace and apostrophes


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


function interpret_enum(input::AbstractString, valid_input::Dict{String, <:AbstractArray{String}})
    index = findfirst(x -> x==input, valid_input[default_language()])
    if isnothing(index) @APIUsageError("interpretation not possible: the string $input is not present in the obtained valid_input dictionary ($valid_input).") end
    return valid_input[LANG.EN_US][index]
end


let
    global active_app, execute
    _active_app::String = ""
    active_app() = _active_app
    execute(cmd::Cmd, cmd_name::String)                   = ( if !activate(cmd) run(cmd; wait=false) end; _active_app = cmd.exec[1] )
end

execute(cmd::Function, cmd_name::String)                  = cmd()
execute(cmd::PyKey, cmd_name::String)                     = Keyboard.press_keys(cmd)
execute(cmd::NTuple{N,PyKey} where {N}, cmd_name::String) = Keyboard.press_keys(cmd...)
execute(cmd::String, cmd_name::String)                    = Keyboard.type_string(cmd)
execute(cmd::Array, cmd_name::String)                     = for subcmd in cmd execute(subcmd, cmd_name) end


function execute(cmd::Dict, cmd_name::String)
    @info "Activating commands: $cmd_name"
    update_commands(commands=cmd, cmd_name=cmd_name)
    Help.help(Help.COMMANDS_KEYWORDS[default_language()]; debugonly=true)
end

function activate(cmd::Cmd)
    app = cmd.exec[1]    
    open_apps = Pywinctl.getAllAppsNames()
    open_app = (app in open_apps) ? app : ""
    if open_app == ""
        for a in open_apps
            if     occursin(Regex("^" * app * "[^a-zA-Z]" ), a  ) open_app = a; break
            elseif occursin(Regex("^" * a   * "[^a-zA-Z]" ), app) open_app = a; break # E.g. app=google-chrome; a=chrome
            elseif occursin(Regex("[^a-zA-Z]" * app * "\$"), a  ) open_app = a; break
            elseif occursin(Regex("[^a-zA-Z]" * a   * "\$"), app) open_app = a; break
            end
        end
    end
    is_open = (open_app != "")
    if is_open
        windowtitle = Pywinctl.getAllAppsWindowsTitles()[open_app][1] # If there are multiple open windows for the given application take the first window.
        window = Pywinctl.getWindowsWithTitle(windowtitle)[1]
        window.activate()
    end
    return is_open
end


# Types

mutable struct Recognizer
    backend::Symbol
    pyobject::PyObject
    transcriber::PyObject
    is_persistent::Bool
    valid_input::AbstractArray{String}
    valid_tokens::AbstractArray{String}

    function Recognizer(backend::Symbol, pyobject::PyObject, transcriber::PyObject, is_persistent::Bool, valid_input::AbstractArray{String})
        valid_tokens = isempty(valid_input) ? String[] : [token for input in split.(valid_input) for token in input] |> unique |> collect
        new(backend, pyobject, transcriber, is_persistent, valid_input, valid_tokens)
    end

    function Recognizer(backend::Symbol, pyobject::PyObject, is_persistent::Bool, valid_input::AbstractArray{String})
        transcriber = PyNULL()
        Recognizer(backend, pyobject, transcriber, is_persistent, valid_input)
    end

    function Recognizer(pyobject::PyObject, is_persistent::Bool, valid_input::AbstractArray{String})
        backend = :Vosk
        Recognizer(backend, pyobject, is_persistent, valid_input)
    end

    function Recognizer(pyobject::PyObject, is_persistent::Bool)
        valid_input = String[]
        Recognizer(pyobject, is_persistent, valid_input)
    end

    function Recognizer(backend::Symbol, pyobject::PyObject, transcriber::PyObject)
        is_persistent = true
        valid_input = String[]
        @show transcriber
        if transcriber !=PyNULL()
            if !(transcriber.is_running()) transcriber.start() end
        end
        Recognizer(backend, pyobject, transcriber, is_persistent, valid_input)
    end

    function Recognizer(backend::Symbol, pyobject::PyObject)
        transcriber = PyNULL()
        Recognizer(backend, pyobject, transcriber)
    end
end

function feed_stt(recognizer::Recognizer, audio::PyObject)
    if recognizer.backend == :Vosk
        exitcode = recognizer.pyobject.AcceptWaveform(audio)
        is_partial_result = (exitcode == 0)
        return is_partial_result
    elseif recognizer.backend == :RealtimeSTT
        recognizer.pyobject.feed_audio(audio)
        return recognizer.transcriber.is_partial_result() # NOTE: This must be in agreement with Vosk's return value (true for partial result).
    else
        @APIUsageError("invalid backend (obtained: $recognizer.backend).")
    end
end

function get_text(recognizer::Recognizer, is_partial_result::Bool)
    if recognizer.backend == :Vosk
        if is_partial_result
            partial_result = recognizer.pyobject.PartialResult()
            return (JSON.parse(partial_result))["partial"]
        else
            result = recognizer.pyobject.Result()
            return (JSON.parse(result))["text"]
        end
    elseif recognizer.backend == :RealtimeSTT
        return recognizer.transcriber.get_text()
    else
        @APIUsageError("invalid backend (obtained: $recognizer.backend).")
    end
end


# Installation helpers

function get_cuda_version()
    # Try to get CUDA version from nvcc
    try
        output = read(`nvcc --version`, String)
        for line in split(output, "\n")
            if occursin("release", line)
                return split(split(line, "release")[2], ",")[1] |> strip
            end
        end
    catch e
        println("nvcc not found. Trying nvidia-smi...")
    end

    # Try to get CUDA version from nvidia-smi
    try
        output = read(`nvidia-smi`, String)
        for line in split(output, "\n")
            if occursin("CUDA Version", line)
                return split(line, "CUDA Version:")[2] |> split |> first |> strip
            end
        end
    catch e
        println("nvidia-smi not found. No CUDA detected.")
    end

    return ""  # Return empty string if no CUDA detected
end

function get_torch_cuda_version()
    cuda_version = get_cuda_version()
    if cuda_version != ""
        major, minor = split(cuda_version, ".")[1:2]
        return "cu$(major)$(minor)"  # Example: CUDA 11.8 → cu118
    else
        return ""
    end
end

# function install_pytorch()
#     cuda_version = get_cuda_version()

#     if cuda_version != ""
#         major, minor = split(cuda_version, ".")[1:2]
#         torch_cuda_version = "cu$(major)$(minor)"  # Example: CUDA 11.8 → cu118
#         println("Installing PyTorch with CUDA $torch_cuda_version support...")
#         Conda.pip_interop(true)
#         Conda.pip("install --index-url=https://download.pytorch.org/whl/$torch_cuda_version", ["torch", "torchaudio"])
#     else
#         println("Installing CPU-only PyTorch...")
#         Conda.pip_interop(true)
#         Conda.pip("install", ["torch", "torchaudio"])
#     end
# end

# install_torch()


## SHARED MACRO FUNCTIONS

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
