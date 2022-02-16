import Pkg, Downloads
using PyCall, Conda, JSON, MacroTools
import MacroTools: splitdef, combinedef


## PYTHON MODULES
const Vosk   = PyNULL()
const Pynput = PyNULL()

function __init__()
    ENV["PYTHON"] = ""                                              # FORCE PyCall to use Conda.jl
    if !any(startswith.(PyCall.python, DEPOT_PATH))                 # Rebuild of PyCall if it has not been built with Conda.jl
        @info "Rebuilding PyCall for using Julia Conda.jl..."
        Pkg.build("PyCall")
        @info "...rebuild completed. Restart Julia and JustSayIt."
        exit()
    end
    copy!(Vosk,   pyimport_pip("vosk"))
    copy!(Pynput, pyimport_pip("pynput"))
end


## CONSTANTS

const SAMPLERATE = 44100                #[Hz]
const AUDIO_READ_MAX = 512              #[bytes]
const AUDIO_ALLOC_GRANULARITY = 1024^2  #[bytes]
const AUDIO_HISTORY_MIN = 1024^2        #[bytes]
const AUDIO_ELTYPE = Int16
const AUDIO_IN_CHANNELS = 1
Base.ENDIAN_BOM == 0x04030201 || error("only little-endian is supported")
const RECORDER_BACKEND = "arecord"
const RECORDER_ARGS = ["--rate=$SAMPLERATE", "--channels=$AUDIO_IN_CHANNELS", "--format=S16_LE", "--quiet"] # (S16_LE: signed 16 bit little endian)
const COMMAND_NAME_EXIT  = "terminus"
const COMMAND_NAME_SLEEP = "sleep"
const COMMAND_NAME_AWAKE = "awake"
const COMMAND_ABORT = "abortus"
const VARARG_END = "terminus"
const VALID_VOICEARGS_KWARGS = Dict(:model=>String, :valid_input=>AbstractArray{String}, :valid_input_auto=>Bool, :interpret_function=>Function, :use_max_accuracy=>Bool, :vararg_end=>String, :vararg_max=>Integer, :vararg_timeout=>AbstractFloat)
const DEFAULT_MODEL_NAME = "default"
const DEFAULT_RECORDER_ID = "default"
const TYPE_MODEL_NAME = "type"
const COMMAND_RECOGNIZER_ID = "" # NOTE: This is a safe ID as it cannot be taken by any model (raises error).
const NOISES_ENGLISH = ["huh"]
const DIGITS_ENGLISH = Dict("zero"=>"0", "one"=>"1", "two"=>"2", "three"=>"3", "four"=>"4", "five"=>"5", "six"=>"6", "seven"=>"7", "eight"=>"8", "nine"=>"9", "dot"=>".")
const UNKNOWN_TOKEN = "[unk]"

const DEFAULT_MODELDIRS = Dict(DEFAULT_MODEL_NAME => "$(homedir())/.config/JustSayIt/models/vosk-model-small-en-us-0.15",
                               TYPE_MODEL_NAME    => "$(homedir())/.config/JustSayIt/models/vosk-model-en-us-0.22")
const DEFAULT_NOISES    = Dict(DEFAULT_MODEL_NAME => NOISES_ENGLISH,
                               TYPE_MODEL_NAME    => NOISES_ENGLISH)

DEFAULT_MODEL_REPO                 = "https://alphacephei.com/vosk/models"
DEFAULT_ENGLISH_MODEL_ARCHIVE      = "vosk-model-small-en-us-0.15.zip"
DEFAULT_ENGLISH_TYPE_MODEL_ARCHIVE = "vosk-model-en-us-0.22.zip"



## FUNCTIONS

function pyimport_pip(modulename::AbstractString)
    try
        pyimport(modulename)
    catch e
        if isa(e, PyCall.PyError)
            Conda.pip_interop(true)
            Conda.pip("install", modulename)
            pyimport(modulename)
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
