ENV["JSI_USE_PYTHON"] = "0"

using JustSayIt
using JustSayIt.API
using Documenter
using DocExtensions
using DocExtensions.DocumenterExtensions

const DOCSRC      = joinpath(@__DIR__, "src")
const DOCASSETS   = joinpath(DOCSRC, "assets")
const EXAMPLEROOT = joinpath(@__DIR__, "..", "config_examples")

include("cleanup_generated_markdown.jl")

DocMeta.setdocmeta!(JustSayIt, :DocTestSetup, :(using JustSayIt); recursive=true)

try
    @info "Copy examples folder to assets..."
    mkpath(DOCASSETS)
    cp(EXAMPLEROOT, joinpath(DOCASSETS, "config_examples"); force=true)


    @info "Preprocessing .MD-files..."
    include("reflinks.jl")
    MarkdownExtensions.expand_reflinks(reflinks; rootdir=DOCSRC)


    @info "Building documentation website using Documenter.jl..."
    makedocs(;
        modules  = [JustSayIt],
        authors  = "Samuel Omlin",
        repo     = "https://github.com/omlins/JustSayIt.jl/blob/{commit}{path}#{line}",
        sitename = "JustSayIt.jl",
        checkdocs = :exports,
        format   = Documenter.HTML(;
            prettyurls       = true, #get(ENV, "CI", "false") == "true",
            canonical        = "https://omlins.github.io/JustSayIt.jl",
            collapselevel    = 1,
            sidebar_sitename = true,
            edit_link        = "main",
        ),
        pages   = [
            "Introduction and Quick Start"  => "index.md",
            "Usage"                         => "usage.md",
            "Examples"                      => [hide("..." => "examples.md"),
                                                "examples/config_custom_function.md",
                                                "examples/application_specific_commands.md",
                                               ],
            "Software reference"            => "software.md",
            "High-level API reference"      => "api.md",
        ],
    )


    @info "Deploying docs..."
    deploydocs(;
        repo         = "github.com/omlins/JustSayIt.jl",
        push_preview = true,
        devbranch    = "main",
    )
finally
    cleanup_generated_markdown(DOCSRC)
end
