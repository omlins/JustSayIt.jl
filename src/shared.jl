import Pkg, Downloads, ProgressMeter
using PyCall, Conda, JSON, MacroTools
import MacroTools: splitdef, combinedef


## PYTHON MODULES
const Vosk        = PyNULL()
const Sounddevice = PyNULL()
const Wave        = PyNULL()
const Zipfile     = PyNULL()
const Pynput      = PyNULL()
const Key         = PyNULL()


function __init__()
    do_restart = false
    ENV["CONDA_JL_USE_MINIFORGE"] = "1"                             # Force usage of miniforge
    if !Conda.USE_MINIFORGE
        @info "Rebuilding Conda.jl for using Miniforge..."
        Pkg.build("Conda")
        do_restart = true
    end
    ENV["PYTHON"] = ""                                              # Force PyCall to use Conda.jl
    if !any(startswith.(PyCall.python, DEPOT_PATH))                 # Rebuild of PyCall if it has not been built with Conda.jl
        @info "Rebuilding PyCall for using Julia Conda.jl..."
        Pkg.build("PyCall")
        do_restart = true
    end
    if do_restart
        @info "...rebuild completed. Restart Julia and JustSayIt."
        exit()
    end
    copy!(Vosk,        pyimport_pip("vosk"))
    copy!(Sounddevice, pyimport_pip("sounddevice"; dependency="portaudio"))
    copy!(Wave,        pyimport("wave"))
    copy!(Zipfile,     pyimport("zipfile"))
    copy!(Pynput,      pyimport_pip("pynput"))
    copy!(Key,         Pynput.keyboard.Key)
end


## CONSTANTS

const SAMPLERATE = 44100                #[Hz]
const AUDIO_READ_MAX = 512              #[bytes]
const AUDIO_ALLOC_GRANULARITY = 1024^2  #[bytes]
const AUDIO_HISTORY_MIN = 1024^2        #[bytes]
const AUDIO_ELTYPE = Int16
const AUDIO_IN_CHANNELS = 1
const COMMAND_NAME_SLEEP = "sleep"
const COMMAND_NAME_AWAKE = "awake"
const COMMAND_ABORT = "abortus"
const VARARG_END = "terminus"
const VALID_VOICEARGS_KWARGS = Dict(:model=>String, :valid_input=>AbstractArray{String}, :valid_input_auto=>Bool, :interpret_function=>Function, :use_max_speed=>Bool, :vararg_end=>String, :vararg_max=>Integer, :vararg_timeout=>AbstractFloat, :ignore_unknown=>Bool)
const DEFAULT_RECORDER_ID = "default"
const DEFAULT_READER_ID = "default"
const COMMAND_RECOGNIZER_ID = "" # NOTE: This is a safe ID as it cannot be taken by any model (raises error).
const DIGITS_ENGLISH = Dict("zero"=>"0", "one"=>"1", "two"=>"2", "three"=>"3", "four"=>"4", "five"=>"5", "six"=>"6", "seven"=>"7", "eight"=>"8", "nine"=>"9", "dot"=>".", "space"=>" ")
const ALPHABET_ENGLISH = Dict("a"=>"a", "b"=>"b", "c"=>"c", "d"=>"d", "e"=>"e", "f"=>"f", "g"=>"g", "h"=>"h", "i"=>"i", "j"=>"j", "k"=>"k", "l"=>"l", "m"=>"m", "n"=>"n", "o"=>"o", "p"=>"p", "q"=>"q", "r"=>"r", "s"=>"s", "t"=>"t", "u"=>"u", "v"=>"v", "w"=>"w", "x"=>"x", "y"=>"y", "z"=>"z", "space"=>" ")

const UNKNOWN_TOKEN = "[unk]"
const PyKey = Union{Char, PyObject}

const MODELTYPE_DEFAULT = "default"
const MODELTYPE_TYPE    = "type"

const LANG = (; DE    = "de",
                EN_US = "en-us",
                ES    = "es",
                FR    = "fr",
             )

const NOISES = (; DE    = [],
                  EN_US = ["huh"],
                  ES    = [],
                  FR    = [],
               )

modelname(modeltype::String, language::String) = modeltype * "-" * language

const MODELNAME = (; DEFAULT = (; zip(keys(LANG), modelname.(MODELTYPE_DEFAULT, values(LANG)))...),
                     TYPE    = (; zip(keys(LANG), modelname.(MODELTYPE_TYPE,    values(LANG)))...),
                  )

@static if Sys.iswindows()
    const JSI_DATA        = joinpath(ENV["APPDATA"], "JustSayIt")
    const MODELDIR_PREFIX = joinpath(JSI_DATA, "models")
    const CONFIG_PREFIX   = joinpath(JSI_DATA, "config")
elseif Sys.isapple()
    const JSI_DATA        = joinpath(homedir(), "Library", "Application Support", "JustSayIt")
    const MODELDIR_PREFIX = joinpath(JSI_DATA, "models")
    const CONFIG_PREFIX   = joinpath(JSI_DATA, "config")
else
    const MODELDIR_PREFIX = joinpath(homedir(), ".local", "share", "JustSayIt", "models")
    const CONFIG_PREFIX   = joinpath(homedir(), ".config", "JustSayIt")
end

const DEFAULT_MODELDIRS = Dict(MODELNAME.DEFAULT.DE    => joinpath(MODELDIR_PREFIX, "vosk-model-small-de-0.15"),
                               MODELNAME.DEFAULT.EN_US => joinpath(MODELDIR_PREFIX, "vosk-model-small-en-us-0.15"),
                               MODELNAME.DEFAULT.ES    => joinpath(MODELDIR_PREFIX, "vosk-model-small-es-0.22"),
                               MODELNAME.DEFAULT.FR    => joinpath(MODELDIR_PREFIX, "vosk-model-small-fr-0.22"),
                               MODELNAME.TYPE.DE       => joinpath(MODELDIR_PREFIX, "vosk-model-de-0.21"),
                               MODELNAME.TYPE.EN_US    => joinpath(MODELDIR_PREFIX, "vosk-model-en-us-daanzu-20200905"),
                               # NOTE: Currently no large model for ES available.
                               MODELNAME.TYPE.FR       => joinpath(MODELDIR_PREFIX, "vosk-model-fr-0.22"),
                               )
const DEFAULT_NOISES    = Dict(MODELNAME.DEFAULT.EN_US => NOISES.EN_US,
                               MODELNAME.TYPE.EN_US    => NOISES.EN_US)

DEFAULT_MODEL_REPO                 = "https://alphacephei.com/vosk/models"
DEFAULT_ENGLISH_MODEL_ARCHIVE      = "vosk-model-small-en-us-0.15.zip"
DEFAULT_ENGLISH_TYPE_MODEL_ARCHIVE = "vosk-model-en-us-daanzu-20200905.zip"


## FUNCTIONS

function pyimport_pip(modulename::AbstractString; dependency::AbstractString="", channel::AbstractString="conda-forge")
    try
        pyimport(modulename)
    catch e
        if isa(e, PyCall.PyError)
            Conda.pip_interop(true)
            Conda.pip("install", modulename)
            try
                pyimport(modulename)
            catch e
                if isa(e, PyCall.PyError) && (dependency != "") # If the module import still failed after installation, try installing the dependency with Conda first.
                    Conda.pip("uninstall --yes", modulename)
                    Conda.add(dependency; channel=channel)
                    Conda.pip("install", modulename)
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

let
    global tic, toc
    t0::Union{Float64,Nothing} = nothing

    tic()::Float64            = ( t0 = time() )
    toc()::Float64            = ( time() - t0 )
    toc(t1::Float64)::Float64 = ( time() - t1 )
end

function pretty_dict_string(dict::Dict{String,<:Any})
    key_length_max = maximum(length.(keys(dict)))
    return join([map(sort([keys(dict)...])) do x
                    join((x, dict[x]), " "^(key_length_max+1-length(x)) * "=> ")
                end...
                ], "\n")
end

pretty_cmd_string(cmd::Union{Tuple,NTuple})   = join(map(pretty_cmd_string, cmd), " + ")
pretty_cmd_string(cmd::PyObject)              = cmd.name
pretty_cmd_string(cmd)                        = string(cmd)
