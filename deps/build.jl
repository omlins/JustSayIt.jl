using Conda, Pkg

## Automatically set up the Conda environment and the system tools required by JustSayIt.
if !(Sys.islinux() || Sys.isapple() || Sys.iswindows())
    @info "JustSayIt: automated dependency setup is not yet implemented for this OS; skipping."
else
    ## Pin the Conda.jl base environment to known-good versions: a freshly bootstrapped
    ## miniforge ships a python that is too new for the version-pinned pip packages of
    ## JustSayIt (no cp314 wheels exist), so python is pinned to 3.12 on every operating
    ## system. On Linux and macOS, conda is pinned as well: a freshly bootstrapped miniforge
    ## ships conda >= 25/26, in which the renamed config key (pip_interop_enabled ->
    ## prefix_data_interoperability) is no longer found by Conda.jl's pip_interop check. On
    ## Windows, that downgrade cannot be performed at all: a running conda.exe is locked by
    ## the operating system and cannot replace itself, so the conda version of the base
    ## environment is left as bootstrapped and only the python pin applies. Conda.add is
    ## idempotent here: on an already pinned environment, the solver resolves to the very
    ## same versions.
    ENV["PYTHON"] = ""                                             # Force PyCall to use Conda.jl
    if Sys.iswindows()
        Conda.add(["python=3.12"]; channel="conda-forge")
    else
        Conda.add(["conda=24.11.3", "python=3.12"]; channel="conda-forge")
    end

    ## Rebuild PyCall so that it binds to the pinned python, then load it freshly (PyCall reads
    ## its build record at load time only) and check the rebinding.
    Pkg.build("PyCall")
    using PyCall
    @assert startswith(pyimport("sys").version, "3.12") "JustSayIt: PyCall is not bound to python 3.12 - the Conda base environment could not be pinned automatically; pin it manually (using Conda; Conda.add([\"conda=24.11.3\", \"python=3.12\"]; channel=\"conda-forge\")), then rebuild PyCall (Pkg.build(\"PyCall\")) and reload Julia."

    ## The PyAudio version pinned by JustSayIt's audio packages provides no macOS arm64
    ## wheels, so that it is built from source during the pip installs - a build that needs
    ## the portaudio headers and library. On Linux, the conda portaudio package is pulled in
    ## implicitly through the Conda fallback for sounddevice; on macOS, the sounddevice wheel
    ## bundles the PortAudio library instead, so that this fallback never runs and nothing
    ## provides the headers. Install the conda package explicitly: it provides both the
    ## headers and the library exactly where the source build searches for them.
    if Sys.isapple()
        Conda.add(["portaudio"]; channel="conda-forge")
    end

    ## pymonctl (imported transitively via pywinctl) hard-requires the xset and xrandr
    ## command-line tools at import time on Linux - without them it raises SystemExit, which
    ## kills the importing process. Install them when absent; non-interactive sudo (-n) is
    ## deliberate, as a build step must never block on a password prompt.
    if Sys.islinux() && (Sys.which("xset") === nothing || Sys.which("xrandr") === nothing)
        try
            run(`sudo -n apt-get update -qq`)
            run(`sudo -n apt-get install -y x11-utils x11-xserver-utils`)  # xset / xrandr
        catch
        end
        if Sys.which("xset") === nothing || Sys.which("xrandr") === nothing
            error("JustSayIt: could not install the command-line tools xset and xrandr, which pymonctl (imported transitively via pywinctl) requires on Linux - please install them manually (sudo apt-get install x11-utils x11-xserver-utils) and rebuild JustSayIt.")
        end
    end

    ## On Windows, Julia's test process cannot spawn conda.exe or pip.exe ("could not spawn
    ## ... EBADF/ENOTSUP"), so the installation of missing Python modules at JustSayIt's
    ## import time fails there before it can even begin: everything JustSayIt needs must be
    ## installed ahead of time in this build process instead. The native dependencies of the
    ## Python modules are installed with Conda first, the pip packages themselves afterwards,
    ## so that the import in the test process is served entirely from the installed
    ## environment.
    if Sys.iswindows()
        Conda.pip_interop(true)
        Conda.add(["ffmpeg", "pyaudio"]; channel="conda-forge")             # Native dependencies of JustSayIt's Python modules
        Conda.pip("install", ["vosk", "sounddevice", "scipy", "numpy", "pynput", "unidecode", "pywinctl", "ollama", "RealtimeSTT", "realtimetts[system, kokoro]"])
    end
end
