using JustSayIt
using Documenter

DocMeta.setdocmeta!(JustSayIt, :DocTestSetup, :(using JustSayIt); recursive=true)

makedocs(;
    modules=[JustSayIt],
    authors="Samuel Omlin and contributors",
    repo="https://github.com/omlins/JustSayIt.jl/blob/{commit}{path}#{line}",
    sitename="JustSayIt.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://omlins.github.io/JustSayIt.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/omlins/JustSayIt.jl",
    devbranch="main",
)
