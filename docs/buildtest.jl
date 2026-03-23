ENV["JSI_USE_PYTHON"] = "0"

using Documenter: DocMeta, doctest
using JustSayIt

const DOCSRC = joinpath(@__DIR__, "src")

include("cleanup_generated_markdown.jl")

try
    DocMeta.setdocmeta!(JustSayIt, :DocTestSetup, :(using JustSayIt); recursive=true)
    doctest(JustSayIt)
finally
    cleanup_generated_markdown(DOCSRC)
end