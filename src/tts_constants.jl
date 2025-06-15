const TTS_SUPPORTED_LOCALENGINES = Dict("system" => PyNULL(), "kokoro" => PyNULL()) # NOTE: this can only be constructed at runtime
const TTS_DEFAULT_ENGINE         = "kokoro"
const TTS_DEFAULT_ENGINE_CPU     = "system"
const TTS_DEFAULT_STREAM         = "__default__"
const TTS_FILE_STREAM            = "__file__"
const TTS_FILE_PLAY_STREAM       = "__file_play__"
