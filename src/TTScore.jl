module TTScore

## Imports
using PyCall, Preferences
using ..JustSayIt
import Base.Threads
import ..JustSayIt: tic, toc, use_gpu, use_tts
using ..JustSayIt.Exceptions
import ..JustSayIt: Sounddevice
using ..JustSayIt: RealtimeTTS
using ..JustSayIt: Time
using PromptingTools
const PT = PromptingTools

## Include of global constants and macros
include("tts_constants.jl")

## Alphabetical include of files
include("tts.jl")
include("tts_api.jl")

## Exports (need to be after include of submodules if re-exports from them)
export init_tts, finalize_tts
export say, @voiceinfo, set_tts_async_default, tts_async_default, tts, dump_audio

end # module JustSayIt
