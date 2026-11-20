## NJDEPS: version control for non-Julia dependencies (nj-deps)
#
# Analogue of Pkg's Project.toml/Manifest.toml duality for the non-Julia (pip + conda)
# dependencies that `pyimport_pip` installs:
#
#   Project.nj.toml  - compat constraints (the "[compat]" tier; Project mode)
#   Manifest.nj.toml - exact resolved graph   (the "Manifest" tier; Manifest mode)
#
# Design and decisions: JustSayItSpecs/pstps/JustSayIt_installation_improvement.md
# (esp. §2 mode selection, §3 file formats, §8 decisions; USE_NJ_MANIFEST per §8.5).
#
# This module is PURE: it reads the two TOML files and composes spec strings. It never
# calls pip or conda and never touches any environment. The integration into the install
# mechanism happens in pymodules.jl (Phase 5).
#
# FORMAT RULES (established in Phase 2 of the installation-improvement PSTP):
#  R1. torch/torchvision/torchaudio live ONLY in [pip.torch]; a `torch` key inside [pip]
#      would collide with the [pip.torch] table (TOML nesting) — schema-enforced here.
#  R2. Pip package names containing dots (e.g. ruamel.yaml) are legal and compared
#      verbatim as table keys.
#  R3. `torch`, `nvidia`, `transitives` are RESERVED sub-table names within [pip].
#  R4. Pip-name case matters for 5 packages (see name_mapping.md); lookups against the
#      loaded tables are therefore case-SENSITIVE on the pip name, while resolution from
#      a *module* name uses the explicit module→pip mapping below.

module njdeps

using TOML

export nj_mode, SpecResolutionError,
       spec_for, spec_conda, pip_constraint_file, bare_name,
       manifest_satisfies_project, python_advisory

# ---------------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------------

const PROJECT_NJ_NAME   = "Project.nj.toml"
const MANIFEST_NJ_NAME  = "Manifest.nj.toml"
const ENVVAR            = "USE_NJ_MANIFEST"

# module name (as passed to pyimport_pip) → pip package name (Phase-2 name mapping)
const MODULE_TO_PIP = Dict(
    "numpy"       => "numpy",
    "scipy"       => "scipy",
    "vosk"        => "vosk",
    "sounddevice" => "sounddevice",
    "unidecode"   => "Unidecode",
    "pywinctl"    => "PyWinCtl",
    "pynput"      => "pynput",
    "ollama"      => "ollama",
    "RealtimeSTT" => "realtimestt",
    "RealtimeTTS" => "realtimetts",
    "torch"       => "torch",        # resolved via [pip.torch]
    "torchvision" => "torchvision",  # resolved via [pip.torch]
    "torchaudio"  => "torchaudio",   # resolved via [pip.torch]
    "PyAudio"     => "PyAudio",      # conda-installed; pip layer mirrors it
)

# keys of [pip] that are sub-tables, never package names (R3)
const PIP_RESERVED = ("torch", "nvidia", "transitives", "constraints")

# Error thrown for mode-selection / schema violations (never silently ignored — plan §8.5).
struct SpecResolutionError <: Exception
    msg::String
end

Base.showerror(io::IO, e::SpecResolutionError) = print(io, "SpecResolutionError: ", e.msg)

# ---------------------------------------------------------------------------------
# File location & mode selection
# ---------------------------------------------------------------------------------

# Test hook: when set, replaces the automatic search dirs / package root (in-process
# only; tests use temp dirs so they never touch the real depot or environments).
const _SEARCH_OVERRIDE  = Ref{Union{Nothing,Vector{String}}}(nothing)
const _PKGROOT_OVERRIDE = Ref{Union{Nothing,String}}(nothing)

"The JustSayIt package root (where the shipped Project.nj.toml lives)."
function pkgroot()
    _PKGROOT_OVERRIDE[] === nothing || return _PKGROOT_OVERRIDE[]
    return dirname(@__DIR__)
end

"Candidate directories searched for the nj files, in Pkg-analogous precedence order:
the active project dir (if any), then the per-version default environment dir.
NOTE: the package directory of a *dependency* is deliberately NOT searched for the
MANIFEST (plan §2); the shipped Project.nj.toml of the JustSayIt package itself is a
last-resort source for the PROJECT file (a lib ships its [compat], like Project.toml)."
function nj_search_dirs()
    _SEARCH_OVERRIDE[] === nothing || return _SEARCH_OVERRIDE[]
    dirs = String[]
    proj = Base.active_project()                     # nothing when --project not given
    proj === nothing || push!(dirs, dirname(proj))
    vdir = joinpath(Base.DEPOT_PATH[1], "environments", "v$(VERSION.major).$(VERSION.minor)")
    push!(dirs, vdir)
    return dirs
end

"Path of the first existing `Project.nj.toml`: search dirs first, then the package root."
function nj_project_file()
    for d in nj_search_dirs()
        p = joinpath(d, PROJECT_NJ_NAME)
        isfile(p) && return p
    end
    p = joinpath(pkgroot(), PROJECT_NJ_NAME)
    isfile(p) && return p
    return nothing
end

"Path of the first existing `Manifest.nj.toml` in the search dirs ONLY (never the
package root of a dependency, plan §2/§8.2)."
function nj_manifest_file()
    for d in nj_search_dirs()
        p = joinpath(d, MANIFEST_NJ_NAME)
        isfile(p) && return p
    end
    return nothing
end

# nj_mode() -> (:manifest, manifest_path) | (:project, project_path) | (:unconstrained, nothing): Mode selection (plan §2 + §8.5): - `USE_NJ_MANIFEST=true` → force Manifest mode; error if no manifest is found (never silently fall back — an accidental Project-mode install could break an existing installation). - `USE_NJ_MANIFEST=false` → force Project mode (any existing manifest is ignored); errors if no Project.nj.toml can be found at all. - unset → automatic file-presence rule over the search dirs; no manifest and no project file anywhere → `(:unconstrained, nothing)` (= today's bare-name behavior; cannot break existing installs that predate these files).
function nj_mode()
    env = get(ENV, ENVVAR, "")
    mf = nj_manifest_file()
    pf = nj_project_file()
    if !isempty(env)
        force = lowercase(strip(env)) in ("true", "1", "yes")
        if force
            mf === nothing && throw(SpecResolutionError(
                "$ENVVAR=true but no $MANIFEST_NJ_NAME found in [$(join(nj_search_dirs(), ", "))] — refusing to silently fall back to Project mode."))
            nj_manifest()            # validate eagerly (throws SpecResolutionError on schema violation)
            return (:manifest, mf)
        else
            pf === nothing && throw(SpecResolutionError(
                "$ENVVAR=false (Project mode) but no $PROJECT_NJ_NAME found anywhere (search dirs + package root)."))
            nj_project()             # validate eagerly
            return (:project, pf)
        end
    end
    # automatic rule: manifest presence wins; else project; else unconstrained.
    # The selected file is validated eagerly (schema errors surface at mode selection).
    mf === nothing || (nj_manifest(); return (:manifest, mf))
    pf === nothing || (nj_project(); return (:project, pf))
    return (:unconstrained, nothing)
end

# ---------------------------------------------------------------------------------
# Loading + schema validation
# ---------------------------------------------------------------------------------

function load_toml(path)
    try
        return TOML.parsefile(path)
    catch e
        throw(SpecResolutionError("Cannot parse $path: $(sprint(showerror, e))"))
    end
end

function validate_project(tbl, path)
    haskey(tbl, "pip") && tbl["pip"] isa AbstractDict ||
        throw(SpecResolutionError("$path: missing or invalid [pip] section."))
    pip = tbl["pip"]
    for k in PIP_RESERVED
        if haskey(pip, k) && !(pip[k] isa AbstractDict)
            throw(SpecResolutionError(
                "$path: `$k` in [pip] must be a table (R1/R3: package keys and sub-table names are disjoint)."))
        end
    end
    if haskey(pip, "torch")
        t = pip["torch"]
        for pkg in ("torch", "torchvision", "torchaudio")
            haskey(t, pkg) || throw(SpecResolutionError(
                "$path: [pip.torch] must define `$pkg` (the torch family lives ONLY here, R1)."))
        end
        get(t, "index", "") isa AbstractString || throw(SpecResolutionError(
            "$path: [pip.torch] index must be a string."))
    end
    haskey(tbl, "conda") || (tbl["conda"] = Dict{String,Any}())   # optional section
    return tbl
end

function validate_manifest(tbl, path)
    haskey(tbl, "pip") && tbl["pip"] isa AbstractDict ||
        throw(SpecResolutionError("$path: missing or invalid [pip] section."))
    pip = tbl["pip"]
    for k in ("transitives",)
        haskey(pip, k) && pip[k] isa AbstractDict || throw(SpecResolutionError(
            "$path: missing [pip.$k] section (manifest must carry the full resolved graph)."))
    end
    for k in PIP_RESERVED
        if haskey(pip, k) && !(pip[k] isa AbstractDict)
            throw(SpecResolutionError("$path: `$k` in [pip] must be a table (R1/R3)."))
        end
    end
    haskey(tbl, "conda") && tbl["conda"] isa AbstractDict ||
        throw(SpecResolutionError("$path: missing or invalid [conda] section."))
    haskey(tbl, "env")    && tbl["env"] isa AbstractDict ||
        throw(SpecResolutionError("$path: missing or invalid [env] section."))
    return tbl
end

# cached loaders (per process; the files are read once at `using` time semantics)
const _cache = Dict{String,Any}()

function nj_project()
    path = nj_project_file()
    path === nothing && return nothing
    get!(_cache, "project:$path") do
        validate_project(load_toml(path), path)
    end
end

function nj_manifest()
    path = nj_manifest_file()
    path === nothing && return nothing
    get!(_cache, "manifest:$path") do
        validate_manifest(load_toml(path), path)
    end
end

"""
Reset the per-process cache (used by tests; also after a file changed on disk during
a long-running session, e.g. a manual edit during debugging).
"""
function reset_cache!()
    empty!(_cache)
    return nothing
end

# ---------------------------------------------------------------------------------
# Spec composition
# ---------------------------------------------------------------------------------

"pip name + optional extras + constraint → one pip spec string, e.g. `foo[bar]>=1,<2`.
Version clauses are space-normalized (pip requirement lines must not contain spaces)."
function pip_spec(name::AbstractString; version::AbstractString="", extras::AbstractString="")
    spec = name * extras
    if !isempty(version)
        v = replace(version, " " => "")
        spec *= v
    end
    return spec
end

# [pip]-table entry → (version, extras): string entry or {version=..., extras=...} table
function entry_parts(entry)
    entry isa AbstractString && return (String(entry), "")
    entry isa AbstractDict   || throw(SpecResolutionError("invalid pip entry: $entry"))
    version = get(entry, "version", "")
    extras  = get(entry, "extras", "")
    return (String(version), String(extras))
end

# Table of the resolution level: (:manifest|:project|:unconstrained, file_or_nothing).
# In manifest mode, compat constraints for direct deps come from the SHIPPED Project
# file if the env-dir one is absent (a manifest is only meaningful together with its
# project; plan §8.2: the package ships Project.nj.toml).
function _mode_tables()
    filesym, path = nj_mode()
    filesym === :unconstrained && return (nothing, nothing, nothing)
    mantbl = filesym === :manifest ? nj_manifest() : nothing
    projtbl = nj_project()                    # search dirs first, then package root
    return (filesym, mantbl, projtbl)
end

# Resolve the pip spec for `modulename` (a module name as passed to pyimport_pip).
function spec_for(modulename::AbstractString;
                  mode::Union{Nothing,Tuple}=nothing,
                  explicit::Union{Nothing,AbstractString}=nothing)
    explicit !== nothing && return explicit                       # explicit kwarg wins (Phase 5 hook)
    filesym, mantbl, projtbl = mode === nothing ? _mode_tables() : _level_tables(mode)
    pipname = get(MODULE_TO_PIP, modulename, modulename)
    # R1: torch family always resolves through the torch tables
    if pipname in ("torch", "torchvision", "torchaudio")
        tbl = filesym === :manifest ? mantbl : projtbl
        tbl === nothing && return pip_spec(pipname)
        tortbl = get(tbl["pip"], "torch", nothing)
        tortbl === nothing && return pip_spec(pipname)
        haskey(tortbl, pipname) || throw(SpecResolutionError(
            "torch table present but `$pipname` missing [$(nj_project_file()) / $(nj_manifest_file())]."))
        (v, extras) = entry_parts(tortbl[pipname])
        return pip_spec(pipname; version = filesym === :manifest ? "==$v" : v, extras = extras)
    end
    # manifest direct dep?
    if filesym === :manifest && mantbl !== nothing && haskey(mantbl["pip"], pipname)
        (v, extras) = entry_parts(mantbl["pip"][pipname])
        return pip_spec(pipname; version = "==$v", extras = extras)
    end
    # project constraint (env dir or shipped)?
    if projtbl !== nothing && haskey(projtbl["pip"], pipname)
        (v, extras) = entry_parts(projtbl["pip"][pipname])
        return pip_spec(pipname; version = v, extras = extras)
    end
    return pip_spec(pipname)                                       # bare name (today's behavior)
end

# accept the (filesym, path) tuples that nj_mode() returns (tests / Phase 5 pass-through)
function _level_tables(t::Tuple)
    filesym = first(t)
    filesym === :unconstrained && return (nothing, nothing, nothing)
    filesym === :manifest  && return (filesym, nj_manifest(), nj_project())
    return (filesym, nothing, nj_project())
end

# Resolve the conda MatchSpec for `dep` (e.g. `portaudio`); bare name if no entry.
function spec_conda(dep::AbstractString; mode::Union{Nothing,Tuple}=nothing)
    filesym, mantbl, projtbl = mode === nothing ? _mode_tables() : _level_tables(mode)
    if filesym === :manifest && mantbl !== nothing
        haskey(mantbl["conda"], dep) && return "$(dep)==$(mantbl["conda"][dep])"
    end
    if projtbl !== nothing
        c = get(projtbl["conda"], dep, nothing)
        c !== nothing && return "$(dep)$(replace(String(c), " " => ""))"
    end
    return String(dep)
end

# bare_name(spec) -> name: Strip extras `[...]` and any version constraint from a pip spec string — the plain package name for the uninstall path and for lookups.
function bare_name(spec::AbstractString)
    s = String(spec)
    i = findfirst(isequal('['), s)
    j = findfirst(c -> c in ('=', '<', '>', '~', '!'), s)
    k = isempty(s) ? 0 : min(i === nothing ? typemax(Int) : i,
                             j === nothing ? typemax(Int) : j)
    return k == typemax(Int) ? s : (k == 0 ? s : s[1:prevind(s, k)])
end

# ---------------------------------------------------------------------------------
# Constraints rendering (both modes; plan §8.1)
# ---------------------------------------------------------------------------------

# pip_constraint_file(mode) -> path::String | nothing: Render the pip constraints for the given mode into a temporary file and return its path (`nothing` when empty). Project mode → `[pip.constraints]` of Project.nj.toml only; Manifest mode → the full manifest graph (direct + torch + nvidia + transitives) in `name==version` form, plus the Project constraints.
function pip_constraint_file(mode::Tuple)
    filesym, _ = mode
    lines = String[]
    proj = nj_project()                                             # env dir or shipped
    if proj !== nothing
        pip = proj["pip"]
        if haskey(pip, "constraints") && pip["constraints"] isa AbstractDict
            for (n, v) in pip["constraints"]
                push!(lines, pip_spec(n; version = String(v)))
            end
        end
    end
    if filesym === :manifest
        man = nj_manifest()
        man === nothing && throw(SpecResolutionError("manifest mode but no manifest"))
        pip = man["pip"]
        direct = Dict(n => e for (n, e) in pip if !(n in PIP_RESERVED))   # R3: skip sub-tables
        for pkg_tbl in (direct, get(pip, "torch", Dict{String,Any}()),
                        get(pip, "nvidia", Dict{String,Any}()), pip["transitives"])
            for (n, entry) in pkg_tbl
                n == "index" && continue
                (v, _) = entry_parts(entry)
                isempty(v) || push!(lines, "$(n)==$(v)")
            end
        end
    end
    isempty(lines) && return nothing
    unique!(lines)
    path = tempname() * ".nj-constraints.txt"
    write(path, join(lines, "\n") * "\n")
    return path
end

# ---------------------------------------------------------------------------------
# Consistency checks
# ---------------------------------------------------------------------------------

# minimal version comparison sufficient for the containment check (PEP 440-ish numerics)
struct NJVersion
    parts::Vector{Int}
end

function NJVersion(v::AbstractString)
    s = strip(v)
    startswith(s, "v") && (s = s[2:end])
    occursin('+', s) && (s = s[1:prevind(s, findfirst('+', s))])   # strip local version (+cu118)
    parts = Int[]
    for p in split(s, '.'; keepempty=true)
        rp = ""
        for ch in p
            isdigit(ch) || break          # stop at first non-digit (e.g. rc/a/b suffixes)
            rp *= ch
        end
        push!(parts, isempty(rp) ? 0 : parse(Int, rp))
    end
    return NJVersion(parts)
end

Base.isless(a::NJVersion, b::NJVersion) = _cmp(a, b) < 0
Base.isequal(a::NJVersion, b::NJVersion) = _cmp(a, b) == 0
function _cmp(a::NJVersion, b::NJVersion)
    n = max(length(a.parts), length(b.parts))
    for i in 1:n
        x = i <= length(a.parts) ? a.parts[i] : 0
        y = i <= length(b.parts) ? b.parts[i] : 0
        x == y || return x < y ? -1 : 1
    end
    return 0
end

"""
    satisfies(version, spec) -> Bool

Exact-ish evaluation of a pip-style version spec against a version string (supports
`==`, `!=`, `>=`, `<=`, `>`, `<` and comma-separated conjunctions). Local versions
(`2.3.0+cu118`) compare on their numeric part, and `==2.3.0` matches `2.3.0+cu118`
(local part ignored), mirroring pip's behaviour for `==` without local label.
"""
function satisfies(version::AbstractString, spec::AbstractString)
    v = NJVersion(version)
    for clause in split(spec, ',')
        c = strip(clause)
        isempty(c) && continue
        m = match(r"^(==|!=|>=|<=|>|<)\s*(.+)$", c)
        m === nothing && throw(SpecResolutionError("unsupported spec clause: $c"))
        op, rhs = m.captures
        r = NJVersion(rhs)
        ok = op == "=="  ? _cmp(v, r) == 0 :
             op == "!="  ? _cmp(v, r) != 0 :
             op == ">="  ? _cmp(v, r) >= 0 :
             op == "<="  ? _cmp(v, r) <= 0 :
             op == ">"   ? _cmp(v, r) >  0 :
                           _cmp(v, r) <  0
        ok || return false
    end
    return true
end

# manifest_satisfies_project() -> Vector{Pair{String,String}}: Check (as the Pkg-analogue load-time warning) that every manifest entry lies within the Project compat ranges. Returns the list of violations `name => "manifest X / project Y"`; empty = in sync. Callers warn (not error) on non-empty results (plan §7: exactness wins).
function manifest_satisfies_project()
    proj, man = nj_project(), nj_manifest()
    viol = Vector{Pair{String,String}}()
    (proj === nothing || man === nothing) && return viol
    ppip, mpip = proj["pip"], man["pip"]
    # direct + torch family
    for (n, entry) in mpip
        n in PIP_RESERVED && continue
        haskey(ppip, n) || continue
        (mv, _) = entry_parts(entry)
        pentry = ppip[n]
        (pv, _) = entry_parts(pentry)
        if !satisfies(mv, pv)
            push!(viol, n => "manifest $mv / project $pv")
        end
    end
    if haskey(mpip, "torch") && haskey(ppip, "torch")
        for pkg in ("torch", "torchvision", "torchaudio")
            mv = get(mpip["torch"], pkg, "")
            pv = get(ppip["torch"], pkg, "")
            !isempty(mv) && isempty(pv) && continue
            isempty(mv) || isempty(pv) || satisfies(mv, pv) ||
                push!(viol, pkg => "manifest $mv / project $pv")
        end
    end
    # conda
    for (n, mv) in get(man, "conda", Dict{String,Any}())
        haskey(proj["conda"], n) || continue
        satisfies(mv, proj["conda"][n]) || push!(viol, n => "manifest $mv / project $(proj["conda"][n])")
    end
    return viol
end

# python_advisory() -> nothing (warns): Advisory check of the env's Python version against `[python]` in Project.nj.toml (plan §8.4: warn only; never installs or changes the interpreter).
function python_advisory(pyversion_string::AbstractString)
    proj = nj_project()
    proj === nothing && return nothing
    py = get(proj, "python", nothing)
    py isa AbstractDict && haskey(py, "version") || return nothing
    satisfies(pyversion_string, py["version"]) ||
        @warn "Python $pyversion_string is outside the advisory range [python] $(py["version"]) in $(nj_project_file())."
    return nothing
end

end # module
