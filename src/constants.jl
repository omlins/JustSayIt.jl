# FUNCTIONS USED IN CONSTANT DEFINITIONS

lang_str(code::String)                                   = LANG_STR[code]
modelname(modeltype::String, language::String=LANG_AUTO) = modeltype * "-" * language
modellang(modelname::String)                             = split(modelname, "-")[2]

function modeltype(modelname::String)
    if     startswith(modelname, MODELTYPE_DEFAULT) return MODELTYPE_DEFAULT
    elseif startswith(modelname, MODELTYPE_SPEECH)  return MODELTYPE_SPEECH
    else                                            @APIUsageError("invalid modelname (obtained: \"$modelname\").")
    end
end


## GLOBAL CONSTANTS

# (audio)
const SAMPLERATE              = 16000 #44100 #48000 #16000       #[Hz]
const AUDIO_IO_CHANNELS       = 1
const AUDIO_ALLOC_GRANULARITY = 1024^2      #[bytes]
const AUDIO_HISTORY_MIN       = 1024^2      #[bytes]
const AUDIO_READ_MAX          = 512         #[bytes]
const AUDIO_ELTYPE            = Int16       # NOTE: This must be as required by the STT models and must be the same as the chunk type used in TTS wite_to_stdout.
const AUDIO_ELTYPE_STR        = lowercase(string(AUDIO_ELTYPE))
const AUDIO_BLOCKSIZE         = Int(AUDIO_READ_MAX/sizeof(AUDIO_ELTYPE))

# (STT and commands)
const COMMAND_RECOGNIZER_ID   = ""          # NOTE: This is a safe ID as it cannot be taken by any model (raises error).
const DEFAULT_RECORDER_ID     = "__default__"
const DEFAULT_READER_ID       = "__default__"
const MODELTYPE_DEFAULT       = "__default__"
const MODELTYPE_SPEECH        = "__speech__"
const UNKNOWN_TOKEN           = "[unk]"
const COMMAND_ABORT           = "abortus"
const VARARG_END              = "terminus"
const DEFAULT_VOSK_MODEL_REPO      = "https://alphacephei.com/vosk/models"
const STT_DEFAULT_FREESPEECH_ENGINE = "faster-whisper"
const STT_DEFAULT_FREESPEECH_ENGINE_CPU = "vosk"

# (voiceargs/voiceconfig)
const VALID_VOICEARGS_KWARGS  = Dict(:model=>String, :modeltype=>String, :language=>String, :valid_input=>Union{AbstractVector{String}, NTuple{N,Pair{String,<:AbstractVector{String}}} where {N}, Dict{String,<:AbstractVector{String}}}, :valid_input_auto=>Bool, :interpreter=>Function, :timeout=>AbstractFloat, :use_max_speed=>Bool, :vararg_end=>String, :vararg_max=>Integer, :ignore_unknown=>Bool)
const VALID_VOICECONFIG_KWARGS = Dict(:modeltype=>String, :language=>String, :timeout=>AbstractFloat, :use_max_speed=>Bool, :ignore_unknown=>Bool)

# (keyboard)
const PyKey                   = Union{Char, PyObject}

# (paths)
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


# (multi-language)

"Constant named tuple containing names of available languages."
const LANG = (DE    = "de",
              EN_US = "en-us",
              ES    = "es",
              FR    = "fr",
             )
const LANG_AUTO = "auto"
const LANG_STR = Dict(LANG.DE    => "German",
                      LANG.EN_US => "English (United States)",
                      LANG.ES    => "Spanish",
                      LANG.FR    => "French",
                      )
const NOISES = (DE    = String[],
                EN_US = String["huh"],
                ES    = String[],
                FR    = String["hum"],
                AUTO  = String[],
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
const DEFAULT_WHISPER_MODELDIRS = Dict(MODELNAME.TYPE.DE    => joinpath(RSTT_MODELDIR_PREFIX, "dummmy"), #NOTE: currently, this is only created for compatibility with Vosk model handling.
                                       MODELNAME.TYPE.EN_US => joinpath(RSTT_MODELDIR_PREFIX, "dummmy"),
                                       MODELNAME.TYPE.ES    => joinpath(RSTT_MODELDIR_PREFIX, "dummmy"),
                                       MODELNAME.TYPE.FR    => joinpath(RSTT_MODELDIR_PREFIX, "dummmy"),
                                       MODELNAME.TYPE.AUTO  => joinpath(RSTT_MODELDIR_PREFIX, "dummmy"),
                                      )
const DEFAULT_NOISES    = Dict(MODELNAME.DEFAULT.DE    => NOISES.DE,
                               MODELNAME.DEFAULT.EN_US => NOISES.EN_US,
                               MODELNAME.DEFAULT.ES    => NOISES.ES,
                               MODELNAME.DEFAULT.FR    => NOISES.FR,
                               MODELNAME.TYPE.DE       => NOISES.DE,
                               MODELNAME.TYPE.EN_US    => NOISES.EN_US,
                               MODELNAME.TYPE.ES       => NOISES.ES,
                               MODELNAME.TYPE.FR       => NOISES.FR,
                               MODELNAME.TYPE.AUTO     => NOISES.AUTO,
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

const LANGUAGES_MAPPING = Dict(
    lang => Dict(word => LANG_SYMBOLS[i] for (i, word) in enumerate(words))
    for (lang, words) in LANGUAGES
)
const DIGITS_MAPPING = Dict(
    lang => Dict(word => DIGITS_SYMBOLS[i] for (i, word) in enumerate(words))
    for (lang, words) in DIGITS
)
const COUNTS_MAPPING = Dict(
    lang => Dict(word => COUNTS_SYMBOLS[i] for (i, word) in enumerate(words))
    for (lang, words) in COUNTS
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
