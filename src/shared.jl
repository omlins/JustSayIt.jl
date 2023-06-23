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
const Pywinctl    = PyNULL()
const Tkinter     = PyNULL()


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
        copy!(Pywinctl,    pyimport_pip("pywinctl"))
        copy!(Tkinter,     pyimport_pip("tkinter")) # NOTE: a persistent controller could be created as follows: set_controller("Tk", Tkinter.Tk()); controller("Tk").withdraw()
    end
end


## CONSTANTS

const DEFAULT_MODEL_REPO      = "https://alphacephei.com/vosk/models"
const SAMPLERATE              = 44100       #[Hz]
const AUDIO_READ_MAX          = 512         #[bytes]
const AUDIO_ALLOC_GRANULARITY = 1024^2      #[bytes]
const AUDIO_HISTORY_MIN       = 1024^2      #[bytes]
const AUDIO_ELTYPE            = Int16
const AUDIO_IN_CHANNELS       = 1
const COMMAND_ABORT           = "abortus"
const VARARG_END              = "terminus"
const COMMAND_RECOGNIZER_ID   = ""          # NOTE: This is a safe ID as it cannot be taken by any model (raises error).
const DEFAULT_RECORDER_ID     = "default"
const DEFAULT_READER_ID       = "default"
const MODELTYPE_DEFAULT       = "default"
const MODELTYPE_TYPE          = "type"
const UNKNOWN_TOKEN           = "[unk]"
const PyKey                   = Union{Char, PyObject}
const VALID_VOICEARGS_KWARGS  = Dict(:model=>String, :valid_input=>Union{AbstractArray{String}, NTuple{N,Pair{String,<:AbstractArray{String}}} where {N}}, :valid_input_auto=>Bool, :interpret_function=>Function, :use_max_speed=>Bool, :vararg_end=>String, :vararg_max=>Integer, :vararg_timeout=>AbstractFloat, :ignore_unknown=>Bool)
const LATIN_ALPHABET          = Dict("a"=>"a", "b"=>"b", "c"=>"c", "d"=>"d", "e"=>"e", "f"=>"f", "g"=>"g", "h"=>"h", "i"=>"i", "j"=>"j", "k"=>"k", "l"=>"l", "m"=>"m", "n"=>"n", "o"=>"o", "p"=>"p", "q"=>"q", "r"=>"r", "s"=>"s", "t"=>"t", "u"=>"u", "v"=>"v", "w"=>"w", "x"=>"x", "y"=>"y", "z"=>"z")

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


# (FUNCTIONS USED IN CONSTANT DEFINITIONS)

lang_str(code::String)                         = LANG_STR[code]
modelname(modeltype::String, language::String) = modeltype * "-" * language
function modeltype(modelname::String)
    if     startswith(modelname, MODELTYPE_DEFAULT) return MODELTYPE_DEFAULT
    elseif startswith(modelname, MODELTYPE_TYPE)    return MODELTYPE_TYPE
    else                                            @APIUsageError("invalid modelname (obtained: \"$modelname\").")
    end
end


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
const LANG_CODES_SHORT = Dict(
    LANG.DE    => Dict("deutsch"     => "de",
                       "englisch"    => "en",
                       "spanisch"    => "es",
                       "französisch" => "fr",
                      ),
    LANG.EN_US => Dict("german"  => "de",
                       "english" => "en",
                       "spanish" => "es",
                       "french"  => "fr",
                      ),
    LANG.ES    => Dict("alemán"  => "de",
                       "inglés"  => "en",
                       "español" => "es",
                       "francés" => "fr",
                      ),
    LANG.FR    => Dict("allemand" => "de",
                       "anglais"  => "en",
                       "espagnol" => "es",
                       "français" => "fr",
                      ),
)
const NOISES = (DE    = String[],
                EN_US = String["huh"],
                ES    = String[],
                FR    = String["hum"],
               )
"Constant named tuple containing modelnames for available languages."
const MODELNAME = (DEFAULT = (; zip(keys(LANG), modelname.(MODELTYPE_DEFAULT, values(LANG)))...),
                   TYPE    = (; zip(keys(LANG), modelname.(MODELTYPE_TYPE,    values(LANG)))...),
                  )
const DEFAULT_MODELDIRS = Dict(MODELNAME.DEFAULT.DE    => joinpath(MODELDIR_PREFIX, "vosk-model-small-de-0.15"),
                               MODELNAME.DEFAULT.EN_US => joinpath(MODELDIR_PREFIX, "vosk-model-small-en-us-0.15"),
                               MODELNAME.DEFAULT.ES    => joinpath(MODELDIR_PREFIX, "vosk-model-small-es-0.22"),
                               MODELNAME.DEFAULT.FR    => joinpath(MODELDIR_PREFIX, "vosk-model-small-fr-0.22"),
                               MODELNAME.TYPE.DE       => joinpath(MODELDIR_PREFIX, "vosk-model-de-0.21"),
                               MODELNAME.TYPE.EN_US    => joinpath(MODELDIR_PREFIX, "vosk-model-en-us-daanzu-20200905"),
                               MODELNAME.TYPE.ES       => "",                   # NOTE: Currently no large model for ES available.
                               MODELNAME.TYPE.FR       => joinpath(MODELDIR_PREFIX, "vosk-model-fr-0.22"),
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
const ALPHABET = Dict(
    LANG.DE    => merge(LATIN_ALPHABET, Dict("leerzeichen"=>" ", "ä"=>"ä", "ö"=>"ö", "ü"=>"ü")),
    LANG.EN_US => merge(LATIN_ALPHABET, Dict("space"=>" ")),
    LANG.ES    => merge(LATIN_ALPHABET, Dict("espacio"=>" ", "ñ"=>"ñ")),
    LANG.FR    => merge(LATIN_ALPHABET, Dict("espace"=>" ")),
)
const DIGITS = Dict(
    LANG.DE    => Dict("null"=>"0", "eins"=>"1", "zwei"=>"2", "drei"=>"3",  "vier"=>"4",   "fünf"=>"5",   "sechs"=>"6", "sieben"=>"7", "acht"=>"8",  "neun"=>"9",  "punkt"=>".", "komma"=>",",   "leerzeichen"=>" "),
    LANG.EN_US => Dict("zero"=>"0", "one"=>"1",  "two"=>"2",  "three"=>"3", "four"=>"4",   "five"=>"5",   "six"=>"6",   "seven"=>"7",  "eight"=>"8", "nine"=>"9",  "dot"=>".",   "comma"=>",",   "space"=>" "),
    LANG.ES    => Dict("cero"=>"0", "uno"=>"1",  "duo"=>"2",  "tres"=>"3",  "quatro"=>"4", "cinco"=>"5",  "seis"=>"6",  "siete"=>"7",  "ocho"=>"8",  "nueve"=>"9", "punto"=>".", "coma"=>",",    "espacio"=>" "),
    LANG.FR    => Dict("zéro"=>"0", "un"=>"1",   "deux"=>"2", "trois"=>"3", "quatre"=>"4", "cinque"=>"5", "six"=>"6",   "sept"=>"7",   "huit"=>"8",  "neuf"=>"9",  "point"=>".", "virgule"=>",", "espace"=>" "),
)
const DIRECTIONS = Dict(
    LANG.DE    => Dict("rechts"=>"right", "links"=>"left", "oben"=>"up", "unten"=>"down", "vorwärts"=>"forward", "rückwärts"=>"backward", "aufwärts"=>"upward", "abwärts"=>"downward"),
    LANG.EN_US => Dict("right"=>"right", "left"=>"left", "up"=>"up",   "down"=>"down", "forward"=>"forward", "backward"=>"backward", "upward"=>"upward", "downward"=>"downward"),
    LANG.ES    => Dict("derecha"=>"right", "izquierda"=>"left", "arriba"=>"up", "abajo"=>"down", "adelante"=>"forward", "atrás"=>"backward", "subiendo"=>"upward", "bajando"=>"downward"),
    LANG.FR    => Dict("droite"=>"right", "gauche"=>"left", "haut"=>"up", "bas"=>"down", "avant"=>"forward", "arrière"=>"backward", "montant"=>"upward", "descendant"=>"downward"),
)
const REGIONS = Dict(
    LANG.DE    => Dict("hier"=>"here", "rechts"=>"right", "links"=>"left", "oben"=>"above", "unten"=>"below", "höher"=>"higher", "tiefer"=>"lower"),
    LANG.EN_US => Dict("here"=>"here", "right"=>"right", "left"=>"left", "above"=>"above", "below"=>"below", "higher"=>"higher", "lower"=>"lower"),
    LANG.ES    => Dict("aquí"=>"here", "derecha"=>"right", "izquierda"=>"left", "arriba"=>"above", "abajo"=>"below", "arribissima"=>"higher", "abajissima"=>"lower"),
    LANG.FR    => Dict("ici"=>"here", "droite"=>"right", "gauche"=>"left", "dessus"=>"above", "dessous"=>"below", "haut"=>"higher", "bas"=>"lower"),
)
const FRAGMENTS = Dict(
    LANG.DE    => Dict("wort"=>"word", "zeile" => "line", "bis ende"=>"remainder", "bis anfang"=>"preceding", "alles"=>"all"),
    LANG.EN_US => Dict("word"=>"word", "line" => "line", "remainder"=>"remainder", "preceding"=>"preceding", "all"=>"all"),
    LANG.ES    => Dict("palabra"=>"word", "línea" => "line", "hasta fin"=>"remainder", "hasta inicio"=>"preceding", "todo"=>"all"),
    LANG.FR    => Dict("mot"=>"word", "ligne" => "line", "jusqu'à la fin"=>"remainder", "jusqu'au début"=>"preceding", "tout"=>"all"),
)
const SIDES = Dict(
    LANG.DE    => Dict("vor"=>"before", "nach"=>"after"),
    LANG.EN_US => Dict("before"=>"before", "after"=>"after"),
    LANG.ES    => Dict("antes"=>"before", "después"=>"after"),
    LANG.FR    => Dict("avant"=>"before", "après"=>"after"),
)
const COUNTS = Dict(
    LANG.DE    => Dict("eins"=>"1", "zwei"=>"2", "drei"=>"3", "vier"=>"4", "fünf"=>"5", "sechs"=>"6", "sieben"=>"7", "acht"=>"8", "neun"=>"9", "zehn"=>"10", "fünfzig"=>"50", "hundert"=>"100", "tausend"=>"1000"),
    LANG.EN_US => Dict("one"=>"1", "two"=>"2", "three"=>"3", "four"=>"4", "five"=>"5", "six"=>"6", "seven"=>"7", "eight"=>"8", "nine"=>"9", "ten"=>"10", "fifty"=>"50", "hundred"=>"100", "thousand"=>"1000"),
    LANG.ES    => Dict("uno"=>"1", "dos"=>"2", "tres"=>"3", "cuatro"=>"4", "cinco"=>"5", "seis"=>"6", "siete"=>"7", "ocho"=>"8", "nueve"=>"9", "diez"=>"10", "cincuenta"=>"50", "cien"=>"100", "mil"=>"1000"),
    LANG.FR    => Dict("un"=>"1", "deux"=>"2", "trois"=>"3", "quatre"=>"4", "cinq"=>"5", "six"=>"6", "sept"=>"7", "huit"=>"8", "neuf"=>"9", "dix"=>"10", "cinquante"=>"50", "cent"=>"100", "mille"=>"1000"),
)


# Sign commands.

PUNCTUATION_SYMBOLS = Dict(
    LANG.DE    => Dict("punkt"                       => ".",
                       "komma"                       => ",",
                       "doppelpunkt"                 => ":",
                       "semikolon"                   => ";",
                       "ausrufezeichen"              => "!",
                       "fragezeichen"                => "?",
                       "anführungszeichen"           => "\"",
                       "einfaches anführungszeichen" => "'",
                      ),
    LANG.EN_US => Dict("point"         => ".",
                       "comma"         => ",",
                       "colon"         => ":",
                       "semicolon"     => ";",
                       "exclamation"   => "!",
                       "interrogation" => "?",
                       "quote"         => "\"",
                       "single quote"  => "'",
                      ),
    LANG.ES    => Dict("punto"            => ".",
                       "coma"             => ",",
                       "dos puntos"       => ":",
                       "punto y coma"     => ";",
                       "exclamación"      => "!",
                       "interrogación"    => "?",
                       "comillas"         => "\"",
                       "comillas simples" => "'",
                      ),
    LANG.FR    => Dict("point"              => ".",
                       "virgule"            => ",",
                       "deux points"        => ":",
                       "point virgule"      => ";",
                       "exclamation"        => "!",
                       "interrogation"      => "?",
                       "guillemets"         => "\"",
                       "guillemets simples" => "'",
                      ),
);

MATH_SYMBOLS = Dict(
    LANG.DE    => Dict(
        "gleich"  => "=",
        "plus"    => "+",
        "minus"   => "-",
        "mal"     => "*",
        "geteilt" => "/",
        "hoch"    => "^",
        "modulo"  => "%",
    ),
    LANG.EN_US => Dict(
        "equal"    => "=",
        "plus"     => "+",
        "minus"    => "-",
        "multiply" => "*",
        "divide"   => "/",
        "power"    => "^",
        "modulo"   => "%",
    ),
    LANG.ES    => Dict(
        "igual"    => "=",
        "más"      => "+",
        "menos"    => "-",
        "por"      => "*",
        "dividido" => "/",
        "potencia" => "^",
        "módulo"   => "%",
    ),
    LANG.FR    => Dict(
        "égal"          => "=",
        "plus"          => "+",
        "moins"         => "-",
        "multiplié par" => "*",
        "divisé par"    => "/",
        "puissance"     => "^",
        "modulo"        => "%",
    ),
);

LOGICAL_SYMBOLS = Dict(
    LANG.DE    => Dict(
        "ampersand"       => "&",
        "vertikal strich" => "|",
        "kleiner"         => "<",
        "größer"          => ">",
        "ungefähr"        => "~",
    ),
    LANG.EN_US => Dict(
        "ampersand"       => "&",
        "vertical bar"    => "|",
        "less than"       => "<",
        "greater than"    => ">",
        "approximately"   => "~",
    ),
    LANG.ES    => Dict(
        "ampersand"       => "&",
        "barra vertical"  => "|",
        "menor que"       => "<",
        "mayor que"       => ">",
        "aproximadamente" => "~",
    ),
    LANG.FR    => Dict(
        "esperluette"     => "&",
        "barre verticale" => "|",
        "inférieur à"     => "<",
        "supérieur à"     => ">",
        "environ"         => "~",
    ),
);

PARENTHESES_SYMBOLS = Dict(
    LANG.DE    => Dict(
        "klammer"                         => "(",
        "schließende klammer"             => ")",
        "eckige klammer"                  => "[",
        "schließende eckige klammer"      => "]",
        "geschweifte klammer"             => "{",
        "schließende geschweifte klammer" => "}",
    ),
    LANG.EN_US => Dict(
        "parentheses"         => "(",
        "closing parentheses" => ")",
        "bracket"             => "[",
        "closing bracket"     => "]",
        "curly"               => "{",
        "closing curly"       => "}",
    ),
    LANG.ES    => Dict(
        "paréntesis"            => "(",
        "paréntesis que cierra" => ")",
        "corchete"              => "[",
        "corchete que cierra"   => "]",
        "llave"                 => "{",
        "llave que cierra"      => "}",
    ),
    LANG.FR    => Dict(
        "parenthèse"          => "(",
        "parenthèse fermante" => ")",
        "crochet"             => "[",
        "crochet fermant"     => "]",
        "accolade"            => "{",
        "accolade fermante"   => "}",
    ),
);

SPECIAL_SYMBOLS = Dict(
    LANG.DE    => Dict(
        "at"         => "@",
        "hashtag"    => "#",
        "dollar"     => "\$",
        "slash"      => "/",
        "underscore" => "_",
        "back tick"  => "`",
        "backslash"  => "\\",
    ),
    LANG.EN_US => Dict(
        "at"         => "@",
        "hashtag"    => "#",
        "dollar"     => "\$",
        "slash"      => "/",
        "underscore" => "_",
        "back tick"  => "`",
        "backslash"  => "\\",
    ),
    LANG.ES    => Dict(
        "arroba"          => "@",
        "almohadilla"     => "#",
        "dólar"           => "\$",
        "barra"           => "/",
        "guión bajo"      => "_",
        "acento grave"    => "`",
        "barra invertida" => "\\",
    ),
    LANG.FR    => Dict(
        "arobase"    => "@",
        "hashtag"    => "#",
        "dollar"     => "\$",
        "slash"      => "/",
        "underscore" => "_",
        "back tick"  => "`",
        "backslash"  => "\\",
    ),
);

ALTERNATIVE_SYMBOLS = Dict(
    LANG.DE    => Dict(
        "punkt"   => ".",
        "strich"  => "-",
        "stern"   => "*",
        "prozent" => "%",
    ),
    LANG.EN_US => Dict(
        "dot"     => ".",
        "dash"    => "-",
        "star"    => "*",
        "percent" => "%",
    ),
    LANG.ES    => Dict(
        "punto"      => ".",
        "guion"      => "-",
        "asterisco"  => "*",
        "por ciento" => "%",
    ),
    LANG.FR    => Dict(
        "point"      => ".",
        "tiret"      => "-",
        "astérisque" => "*",
        "pour cent"  => "%",
    ),
);

merge_recursively(x::AbstractDict...) = merge(merge_recursively, x...) # NOTE: this function needs to be defined before it's usage below.
merge_recursively(x...) = x[end]

SYMBOLS = merge_recursively(
    PUNCTUATION_SYMBOLS,
    MATH_SYMBOLS,
    LOGICAL_SYMBOLS,
    PARENTHESES_SYMBOLS,
    SPECIAL_SYMBOLS,
    ALTERNATIVE_SYMBOLS
)


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


execute(cmd::Function, cmd_name::String)                  = cmd()
execute(cmd::PyKey, cmd_name::String)                     = Keyboard.press_keys(cmd)
execute(cmd::NTuple{N,PyKey} where {N}, cmd_name::String) = Keyboard.press_keys(cmd...)
execute(cmd::String, cmd_name::String)                    = Keyboard.type_string(cmd)
execute(cmd::Cmd, cmd_name::String)                       = if !activate(cmd) run(cmd; wait=false) end
execute(cmd::Array, cmd_name::String)                     = for subcmd in cmd execute(subcmd, cmd_name) end

function execute(cmd::Dict, cmd_name::String)
    @info "Activating commands: $cmd_name"
    update_commands(commands=cmd, cmd_name=cmd_name)
    Help.help(Help.COMMANDS_KEYWORDS[default_language()])
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
    pyobject::PyObject
    is_persistent::Bool
    valid_input::AbstractArray{String}
    valid_tokens::AbstractArray{String}

    function Recognizer(pyobject::PyObject, is_persistent::Bool, valid_input::AbstractArray{String})
        valid_tokens = isempty(valid_input) ? String[] : [token for input in split.(valid_input) for token in input] |> unique |> collect
        new(pyobject, is_persistent, valid_input, valid_tokens)
    end

    function Recognizer(pyobject::PyObject, is_persistent::Bool)
        valid_input = String[]
        Recognizer(pyobject, is_persistent, valid_input)
    end
end