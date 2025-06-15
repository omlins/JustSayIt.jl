module LLMcore

## Imports
using PyCall, Preferences
import ..JustSayIt: tic, toc
using ..JustSayIt.TTScore
using ..JustSayIt.Exceptions
using ..JustSayIt: Ollama
using PromptingTools
const PT = PromptingTools

## Include of global constants and macros
include("llm_constants.jl")

## Alphabetical include of files
include("llm.jl")
include("llm_api.jl")

## Exports (need to be after include of submodules if re-exports from them)
export init_llm, finalize_llm

end # module LLMcore

