using Conda, Pkg

## Automatically set up the Conda environment and the system tools required by JustSayIt.
if !Sys.islinux()
    @info "JustSayIt: automated dependency setup is not yet implemented for this OS; skipping."
else
    ## Pin the Conda.jl base environment to known-good versions (conda 24.11.3, python 3.12):
    ## a freshly bootstrapped miniforge ships conda >= 25/26, in which the renamed config key
    ## (pip_interop_enabled -> prefix_data_interoperability) is no longer found by Conda.jl's
    ## pip_interop check, and in which the python version is too new for the version-pinned
    ## pip packages of JustSayIt (no cp314 wheels exist). Conda.add is idempotent here: on an
    ## already pinned environment, the solver resolves to the very same versions.
    ENV["PYTHON"] = ""                                             # Force PyCall to use Conda.jl
    Conda.add(["conda=24.11.3", "python=3.12"]; channel="conda-forge")

    ## Rebuild PyCall so that it binds to the pinned python, then load it freshly (PyCall reads
    ## its build record at load time only) and check the rebinding.
    Pkg.build("PyCall")
    using PyCall
    @assert startswith(pyimport("sys").version, "3.12") "JustSayIt: PyCall is not bound to python 3.12 - the Conda base environment could not be pinned automatically; pin it manually (using Conda; Conda.add([\"conda=24.11.3\", \"python=3.12\"]; channel=\"conda-forge\")), then rebuild PyCall (Pkg.build(\"PyCall\")) and reload Julia."

    ## pymonctl (imported transitively via pywinctl) hard-requires the xset and xrandr
    ## command-line tools at import time on Linux - without them it raises SystemExit, which
    ## kills the importing process. Install them when absent; non-interactive sudo (-n) is
    ## deliberate, as a build step must never block on a password prompt.
    if Sys.which("xset") === nothing || Sys.which("xrandr") === nothing
        try
            run(`sudo -n apt-get update -qq`)
            run(`sudo -n apt-get install -y x11-utils x11-xserver-utils`)  # xset / xrandr
        catch
        end
        if Sys.which("xset") === nothing || Sys.which("xrandr") === nothing
            error("JustSayIt: could not install the command-line tools xset and xrandr, which pymonctl (imported transitively via pywinctl) requires on Linux - please install them manually (sudo apt-get install x11-utils x11-xserver-utils) and rebuild JustSayIt.")
        end
    end
end
