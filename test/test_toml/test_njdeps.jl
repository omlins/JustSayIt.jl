# Unit tests for src/njdeps.jl (Phase 4 of the installation-improvement PSTP).
#
# PURE tests: everything runs against temporary directories with synthetic TOML
# fixtures. No pip, no conda, no environment access, no network. The working
# JustSayIt installation on Julia 1.11 is never touched.
#
# Run (sandbox only, per the plan's safety rules — e.g.):
#   julia --project=test/test_toml test/test_toml/test_njdeps.jl

using Test
using TOML

# include the module directly (standalone; no `using JustSayIt` needed).
# this file: test/test_toml/test_njdeps.jl -> repo src/njdeps.jl
include(joinpath(dirname(@__DIR__), "..", "src", "njdeps.jl"))
using .njdeps

import .njdeps: _SEARCH_OVERRIDE, _PKGROOT_OVERRIDE, reset_cache!

# ------------------------------------------------------------------ fixtures ----
const T = mktempdir()      # "environment dir" fixture carrying BOTH files
const PR = mktempdir()     # "package root" fixture (shipped Project only)

const PROJ = Dict(
    "python" => Dict("version" => ">=3.11, <3.13"),
    "pip" => Dict(
        "numpy"       => ">=1.26.4, <2.0",
        "realtimestt" => ">=0.3.98, <0.4",
        "realtimetts" => Dict("version" => ">=0.4.55, <0.5", "extras" => "[system, kokoro]"),
        "torch"       => Dict("torch" => "==2.3.0", "torchvision" => "==0.18.0",
                              "torchaudio" => "==2.3.0",
                              "index" => "https://download.pytorch.org/whl/cu118"),
        "constraints" => Dict("ctranslate2" => "==3.24.0"),
    ),
    "conda" => Dict("portaudio" => ">=19.7, <20", "ffmpeg" => ">=7.1, <8"),
)
const MAN = Dict(
    "manifest_format" => "1.0",
    "pip" => Dict(
        "numpy"       => "1.26.4",
        "realtimestt" => "0.3.100",
        "realtimetts" => Dict("version" => "0.4.55", "extras" => "[system, kokoro]"),
        "torch"       => Dict("torch" => "2.3.0+cu118", "torchvision" => "0.18.0+cu118",
                              "torchaudio" => "2.3.0+cu118",
                              "index" => "https://download.pytorch.org/whl/cu118"),
        "nvidia"      => Dict("nvidia-cudnn-cu11" => "8.7.0.84"),
        "transitives" => Dict("ctranslate2" => "3.24.0", "ruamel.yaml" => "0.18.10"),
    ),
    "conda" => Dict("portaudio" => "19.7.0", "ffmpeg" => "7.1.1"),
    "env"   => Dict("python" => "3.12.9"),
)

open(joinpath(T, "Project.nj.toml"), "w")  do io; TOML.print(io, PROJ); end
open(joinpath(T, "Manifest.nj.toml"), "w") do io; TOML.print(io, MAN);  end
open(joinpath(PR, "Project.nj.toml"), "w") do io; TOML.print(io, PROJ); end   # shipped project only
const NOFILES = mktempdir()

# Hermetic search: overrides BOTH the search dirs and the pkgroot. Defaults emulate
# "env dir carries both files; package root ships only the Project".
function with_search(f; dirs::Vector{String}=[T], pkgroot::String=PR)
    olddirs, oldroot = _SEARCH_OVERRIDE[], _PKGROOT_OVERRIDE[]
    _SEARCH_OVERRIDE[] = dirs
    _PKGROOT_OVERRIDE[] = pkgroot
    reset_cache!()
    try
        return f()
    finally
        _SEARCH_OVERRIDE[] = olddirs
        _PKGROOT_OVERRIDE[] = oldroot
        reset_cache!()
    end
end

# ------------------------------------------------------------- mode selection --
@testset "mode selection (USE_NJ_MANIFEST / file presence)" begin
    # automatic rule: manifest presence wins
    with_search() do
        @test nj_mode() == (:manifest, joinpath(T, "Manifest.nj.toml"))
    end
    # only a project file (env dir) -> project mode
    d = mktempdir(); cp(joinpath(T, "Project.nj.toml"), joinpath(d, "Project.nj.toml"))
    with_search(dirs=[d]) do
        @test nj_mode() == (:project, joinpath(d, "Project.nj.toml"))
    end
    # nothing anywhere (env + pkgroot) -> unconstrained (today's bare-name behavior)
    with_search(dirs=[NOFILES], pkgroot=NOFILES) do
        @test nj_mode() == (:unconstrained, nothing)
    end
    # env empty, pkgroot ships Project -> project mode via the package root
    with_search(dirs=[NOFILES]) do
        @test nj_mode() == (:project, joinpath(PR, "Project.nj.toml"))
    end
    # the package root is NEVER consulted for manifests
    with_search(dirs=[NOFILES], pkgroot=T) do     # T carries a Manifest, visible as pkgroot only
        @test nj_mode() == (:project, joinpath(T, "Project.nj.toml"))
    end
    # USE_NJ_MANIFEST semantics
    with_search() do
        withenv("USE_NJ_MANIFEST" => "true")  do; @test nj_mode()[1] === :manifest; end
        withenv("USE_NJ_MANIFEST" => "TRUE")  do; @test nj_mode()[1] === :manifest; end  # case-insensitive
        withenv("USE_NJ_MANIFEST" => "false") do; @test nj_mode()[1] === :project;  end
        withenv("USE_NJ_MANIFEST" => "0")     do; @test nj_mode()[1] === :project;  end  # 0/1 synonyms
        withenv("USE_NJ_MANIFEST" => "1")     do; @test nj_mode()[1] === :manifest; end
    end
    # hard error: true but no manifest anywhere (never silently fall back)
    with_search(dirs=[NOFILES], pkgroot=NOFILES) do
        withenv("USE_NJ_MANIFEST" => "true") do
            err = try nj_mode(); nothing catch e; e end
            @test err isa SpecResolutionError
            @test occursin("refusing to silently fall back", err.msg)
        end
    end
    # search order: a manifest in a LATER dir still beats project-only earlier dirs
    dA, dB = mktempdir(), mktempdir()
    cp(joinpath(T, "Project.nj.toml"), joinpath(dA, "Project.nj.toml"))
    cp(joinpath(T, "Project.nj.toml"), joinpath(dB, "Project.nj.toml"))
    cp(joinpath(T, "Manifest.nj.toml"), joinpath(dB, "Manifest.nj.toml"))
    with_search(dirs=[dA, dB]) do
        @test nj_mode() == (:manifest, joinpath(dB, "Manifest.nj.toml"))
    end
end

# ------------------------------------------------------------------ spec_for ---
@testset "spec_for (module→pip mapping, constraints, torch family)" begin
    with_search() do
        withenv("USE_NJ_MANIFEST" => nothing) do          # automatic = manifest mode here
            @test spec_for("numpy")       == "numpy==1.26.4"
            @test spec_for("RealtimeSTT") == "realtimestt==0.3.100"
            @test spec_for("RealtimeTTS") == "realtimetts[system, kokoro]==0.4.55"
            @test spec_for("torch")       == "torch==2.3.0+cu118"
            @test spec_for("torchvision") == "torchvision==0.18.0+cu118"
            @test spec_for("unidecode") == "Unidecode"               # mapped→pip name; no fixture entry -> bare
            @test spec_for("PyAudio") == "PyAudio"                    # mapped; no fixture entry -> bare
        end
        withenv("USE_NJ_MANIFEST" => "false") do
            @test spec_for("numpy")       == "numpy>=1.26.4,<2.0"     # space-normalized (pip requirement syntax)
            @test spec_for("RealtimeTTS") == "realtimetts[system, kokoro]>=0.4.55,<0.5"
            @test spec_for("torch")       == "torch==2.3.0"
            @test spec_for("unidecode") == "Unidecode"               # mapped→pip name; no Project entry -> bare
            @test spec_for("notamodule") == "notamodule"             # unmapped -> module name verbatim
        end
        # explicit kwarg wins over everything
        @test spec_for("numpy"; explicit="numpy==9.9.9") == "numpy==9.9.9"
        # unconstrained mode: bare names always
        with_search(dirs=[NOFILES], pkgroot=NOFILES) do
            @test spec_for("numpy") == "numpy"
            @test spec_for("torch") == "torch"
        end
    end
end

# ----------------------------------------------------------------- spec_conda --
@testset "spec_conda" begin
    with_search() do
        withenv("USE_NJ_MANIFEST" => nothing) do
            @test spec_conda("portaudio") == "portaudio==19.7.0"        # exact in manifest mode
            @test spec_conda("pyaudio")   == "pyaudio"                  # not in fixture -> bare
        end
        withenv("USE_NJ_MANIFEST" => "false") do
            @test spec_conda("portaudio") == "portaudio>=19.7,<20"      # constraint MatchSpec
            @test spec_conda("ffmpeg")    == "ffmpeg>=7.1,<8"
        end
        with_search(dirs=[NOFILES], pkgroot=NOFILES) do
            @test spec_conda("portaudio") == "portaudio"
        end
    end
end

# ----------------------------------------------------------------- bare_name ---
@testset "bare_name (uninstall path)" begin
    @test bare_name("realtimetts[system, kokoro]>=0.4.55, <0.5") == "realtimetts"
    @test bare_name("numpy==1.26.4")            == "numpy"
    @test bare_name("ruamel.yaml")              == "ruamel.yaml"        # dotted name preserved
    @test bare_name("numpy")                    == "numpy"
    @test bare_name("torch==2.3.0+cu118")       == "torch"
    @test bare_name("nvidia-cudnn-cu11>=8.7, <9") == "nvidia-cudnn-cu11"
end

# -------------------------------------------------------------- constraints ---
@testset "pip_constraint_file (both modes; plan §8.1)" begin
    with_search() do
        withenv("USE_NJ_MANIFEST" => "false") do
            p = pip_constraint_file(nj_mode())
            @test p !== nothing && isfile(p)
            lines = readlines(p)
            @test lines == ["ctranslate2==3.24.0"]                       # project constraints only
            rm(p)
        end
        withenv("USE_NJ_MANIFEST" => nothing) do
            p = pip_constraint_file(nj_mode())                           # manifest mode: full graph
            @test p !== nothing && isfile(p)
            lines = readlines(p)
            @test "numpy==1.26.4"            in lines
            @test "torch==2.3.0+cu118"       in lines
            @test "nvidia-cudnn-cu11==8.7.0.84" in lines
            @test "ruamel.yaml==0.18.10"     in lines
            @test "ctranslate2==3.24.0"      in lines                    # project constraint = manifest value
            @test length(lines) == 9                                      # 3 direct + 3 torch(+index skipped) + 1 nvidia + 2 transitives, deduped
            rm(p)
        end
        # unconstrained mode: no constraints file
        with_search(dirs=[NOFILES], pkgroot=NOFILES) do
            @test pip_constraint_file(nj_mode()) === nothing
        end
    end
end

# ----------------------------------------------------------------- satisfies ---
@testset "satisfies (version-spec evaluation)" begin
    @test  njdeps.satisfies("1.26.4",  ">=1.26.4, <2.0")
    @test !njdeps.satisfies("2.0.0",   ">=1.26.4, <2.0")
    @test  njdeps.satisfies("2.3.0+cu118", "==2.3.0")                    # local part ignored for ==
    @test !njdeps.satisfies("2.3.1",   "==2.3.0")
    @test  njdeps.satisfies("0.3.100", ">=0.3.98, <0.4")
    @test  njdeps.satisfies("19.7.0",  ">=19.7, <20")
    @test !njdeps.satisfies("3.10.0",  ">=3.11, <3.13")
    @test  njdeps.satisfies("3.12.9",  ">=3.11, <3.13")
    @test_throws SpecResolutionError njdeps.satisfies("1.0", "=1.0")    # unsupported clause
end

# ------------------------------------------------------ containment / sync ----
@testset "manifest_satisfies_project" begin
    with_search() do
        @test isempty(manifest_satisfies_project())                      # fixture is in sync
    end
    d = mktempdir()
    bad = deepcopy(MAN); bad["pip"]["numpy"] = "99.0.0"
    open(joinpath(d, "Manifest.nj.toml"), "w") do io; TOML.print(io, bad); end
    cp(joinpath(T, "Project.nj.toml"), joinpath(d, "Project.nj.toml"))
    with_search(dirs=[d]) do
        v = manifest_satisfies_project()
        @test any(x -> x.first == "numpy" && occursin("99.0.0", x.second), v)
    end
end

# --------------------------------------------------------- schema validation --
@testset "schema validation (R1/R3 format rules)" begin
    # R1: `torch` as a plain KEY in [pip] must be rejected
    d = mktempdir()
    bad = deepcopy(PROJ); bad["pip"]["torch"] = "==2.3.0"
    open(joinpath(d, "Project.nj.toml"), "w") do io; TOML.print(io, bad); end
    with_search(dirs=[d], pkgroot=NOFILES) do
        @test_throws SpecResolutionError nj_mode()
    end
    # R1: [pip.torch] missing torchvision
    d = mktempdir()
    bad = deepcopy(PROJ); delete!(bad["pip"]["torch"], "torchvision")
    open(joinpath(d, "Project.nj.toml"), "w") do io; TOML.print(io, bad); end
    with_search(dirs=[d], pkgroot=NOFILES) do
        @test_throws SpecResolutionError nj_mode()
    end
    # manifest without [pip.transitives]
    d = mktempdir()
    bad = deepcopy(MAN); delete!(bad["pip"], "transitives")
    open(joinpath(d, "Manifest.nj.toml"), "w") do io; TOML.print(io, bad); end
    cp(joinpath(T, "Project.nj.toml"), joinpath(d, "Project.nj.toml"))
    with_search(dirs=[d], pkgroot=NOFILES) do
        @test_throws SpecResolutionError nj_mode()
    end
end

# --------------------------------------------------------------- python adv. --
@testset "python advisory (§8.4: warn only)" begin
    with_search() do
        @test python_advisory("3.12.9") === nothing                      # in range: silent
        @test (python_advisory("3.10.0"); true)                          # out of range: warns, no error
    end
end

println("\nnjdeps unit tests: all testsets completed.")
