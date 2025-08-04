
## PYTHON MODULES
const Vosk        = PyNULL()
const Sounddevice = PyNULL()
const Wave        = PyNULL()
const Scipy       = PyNULL()
const Numpy       = PyNULL()
const Time        = PyNULL()
const Zipfile     = PyNULL()
const Pynput      = PyNULL()
const Key         = PyNULL()
const MouseButton = PyNULL()
const Unidecode   = PyNULL()
const Pywinctl    = PyNULL()
const Tkinter     = PyNULL()
const Ollama      = PyNULL()
const Torch       = PyNULL()
const RealtimeTTS = PyNULL()
const RealtimeSTT = PyNULL()
const Transcriber = PyNULL()


## ENVIRONMENT BUILD AND PYTHON MODULE IMPORTS

function __init__()
    if !haskey(ENV, "JSI_USE_PYTHON") ENV["JSI_USE_PYTHON"] = "1" end
    if ENV["JSI_USE_PYTHON"] == "1"                                     # ENV["JSI_USE_PYTHON"] = "0" enables to deactivate the setup of Python related things at module load time, e.g. for the docs build.
        do_restart = false
        ENV["CONDA_JL_USE_MINIFORGE"] = "1"                             # Force usage of miniforge
        if !Conda.USE_MINIFORGE
            @info "Rebuilding Conda.jl for using Miniforge..."
            Pkg.build("Conda")
            do_restart = true
        end
        ENV["PYTHON"] = ""                                              # Force PyCall to use Conda.jl
        if !any(startswith.(PyCall.python, DEPOT_PATH))                 # Rebuild of PyCall if it has not been built with Conda.jl
            @info "Rebuilding PyCall for using Julia Conda.jl and installing/updating Conda..."
            Conda.update()                                             # Update Conda.jl; ensures also that miniforge gets installed before it is potentially used in a situation where it is expected to be installed (config / pip_interop...?)
            Pkg.build("PyCall")
            do_restart = true
        end
        if do_restart
            @info "...rebuild completed. Restart Julia and JustSayIt."
            exit()
        end
        copy!(Vosk,        pyimport_pip("vosk"))
        copy!(Sounddevice, pyimport_pip("sounddevice"; dependencies=["portaudio"]))
        copy!(Wave,        pyimport("wave"))
        copy!(Scipy,       pyimport_pip("scipy"))
        copy!(Numpy,       pyimport_pip("numpy"))
        copy!(Time,        pyimport("time"))
        copy!(Zipfile,     pyimport("zipfile"))
        copy!(Pynput,      pyimport_pip("pynput"))
        copy!(Key,         Pynput.keyboard.Key)
        copy!(MouseButton, Pynput.mouse.Button)
        copy!(Unidecode,   pyimport_pip("unidecode"))
        copy!(Pywinctl,    pyimport_pip("pywinctl"))
        copy!(Tkinter,     pyimport_pip("tkinter"))
        copy!(Ollama,      pyimport_pip("ollama"))
        # if startswith(get_cuda_version(), "11.")
            # Conda.pip("uninstall --yes", ["ctranslate2", "nvidia-cublas-cu12", "nvidia-cudnn-cu12", "nvidia-cublas-cu11", "nvidia-cudnn-cu11"])
            # pyimport_pip("nvidia.cublas"; modulename_pip="nvidia-cublas-cu11")
            # pyimport_pip("nvidia.cudnn"; modulename_pip="nvidia-cudnn-cu11==8.*")

            # Conda.pip("uninstall --yes", "ctranslate2")
            # pyimport_pip("ctranslate2"; modulename_pip="ctranslate2==3.24.0")
        # end
        # kokoro requires a driver update!
        if get_cuda_version() != ""  # Install Torch with CUDA support if available (for RealtimeTTS)
            try 
                copy!(Torch, pyimport("torch"))
            catch e
            end
            if (Torch==PyNULL()) || !(Torch.cuda.is_available())
                Conda.pip("uninstall --yes", ["torch", "torchvision", "torchaudio"])
            end
            # if startswith(get_cuda_version(), "11.")
                copy!(Torch, pyimport_pip("torch", args_pip="--index-url=https://download.pytorch.org/whl/cu118"; modulename_pip="torch==2.3.0")) #; dependencies=["pytorch-cuda=11.8"]))
                pyimport_pip("torchvision", args_pip="--index-url=https://download.pytorch.org/whl/cu118"; modulename_pip="torchvision==0.18.0")
                pyimport_pip("torchaudio", args_pip="--index-url=https://download.pytorch.org/whl/cu118"; modulename_pip="torchaudio==2.3.0")
            # else
            #    copy!(Torch, pyimport_pip("torch", args_pip="--index-url=https://download.pytorch.org/whl/$(get_torch_cuda_version())"; dependencies=["pytorch-cuda"]))
            #    pyimport_pip("torchvision", args_pip="--index-url=https://download.pytorch.org/whl/$(get_torch_cuda_version())")
            #    pyimport_pip("torchaudio", args_pip="--index-url=https://download.pytorch.org/whl/$(get_torch_cuda_version())")
            # end
        end
        copy!(RealtimeSTT, pyimport_pip("RealtimeSTT"; dependencies=["ffmpeg"], force_dependencies=true))
        copy!(RealtimeTTS, pyimport_pip("RealtimeTTS"; modulename_pip="realtimetts[system, kokoro]", dependencies=["pyaudio"], force_dependencies=true)) # NOTE: PyAudio fails to install with pip; so, it is installed with Conda...
        @pyinclude(joinpath(@__DIR__, "transcriber.py"))
        copy!(Transcriber, py"Transcriber")

        # Set keyboard layout and the device controllers
        fix_keyboard_layout() # This is a workaround for the following pyinput issue: https://github.com/moses-palmer/pynput/issues/639
        set_controller("keyboard", Pynput.keyboard.Controller())
        set_controller("mouse", Pynput.mouse.Controller())
        atexit(restore_keyboard_layout)
    end
end


## FUNCTIONS

# (import)

function pyimport_pip(modulename::AbstractString; dependencies::AbstractArray=[], channel::AbstractString="conda-forge", force_dependencies::Bool=false, modulename_pip::AbstractString="", args_pip::AbstractString="")
    modulename_pip = isempty(modulename_pip) ? modulename : modulename_pip
    args_pip = isempty(args_pip) ? "" : " $args_pip"
    try
        pyimport(modulename)
    catch e
        if isa(e, PyCall.PyError)
            if !(force_dependencies && !isempty(dependencies)) # If the dependencies installation has to be forced, we skip trying without dependencies.
                Conda.pip_interop(true)
                Conda.pip("install$args_pip", modulename_pip)
            end
            try
                pyimport(modulename)
            catch e
                if isa(e, PyCall.PyError) && (!isempty(dependencies)) # If the module import still failed after installation, try installing the dependencies with Conda first.
                    Conda.pip("uninstall --yes", modulename_pip)
                    for dependency in dependencies
                        Conda.add(dependency; channel=channel)
                    end
                    Conda.pip("install$args_pip", modulename_pip)
                    pyimport(modulename)
                else
                    rethrow(e)
                end
            end
        else
            rethrow(e)
        end
    end
end

function pyimport_pip(symbol::Symbol, pymodule::PyObject, symbolname_pip::AbstractString; args_pip::AbstractString="")
    args_pip = isempty(args_pip) ? "" : " $args_pip"
    try
        getproperty(pymodule, symbol)
    catch
        Conda.pip_interop(true)
        Conda.pip("install$args_pip", symbolname_pip)
        getproperty(pymodule, symbol)
    end
end


# (version detection)

function get_cuda_version()
    # Try to get CUDA version from nvcc
    try
        output = read(`nvcc --version`, String)
        for line in split(output, "\n")
            if occursin("release", line)
                return split(split(line, "release")[2], ",")[1] |> strip
            end
        end
    catch e
        println("nvcc not found. Trying nvidia-smi...")
    end

    # Try to get CUDA version from nvidia-smi
    try
        output = read(`nvidia-smi`, String)
        for line in split(output, "\n")
            if occursin("CUDA Version", line)
                return split(line, "CUDA Version:")[2] |> split |> first |> strip
            end
        end
    catch e
        println("nvidia-smi not found. No CUDA detected.")
    end

    return ""  # Return empty string if no CUDA detected
end

function get_torch_cuda_version()
    cuda_version = get_cuda_version()
    if cuda_version != ""
        major, minor = split(cuda_version, ".")[1:2]
        return "cu$(major)$(minor)"  # Example: CUDA 11.8 → cu118
    else
        return ""
    end
end

# function install_pytorch()
#     cuda_version = get_cuda_version()

#     if cuda_version != ""
#         major, minor = split(cuda_version, ".")[1:2]
#         torch_cuda_version = "cu$(major)$(minor)"  # Example: CUDA 11.8 → cu118
#         println("Installing PyTorch with CUDA $torch_cuda_version support...")
#         Conda.pip_interop(true)
#         Conda.pip("install --index-url=https://download.pytorch.org/whl/$torch_cuda_version", ["torch", "torchaudio"])
#     else
#         println("Installing CPU-only PyTorch...")
#         Conda.pip_interop(true)
#         Conda.pip("install", ["torch", "torchaudio"])
#     end
# end

# install_torch()

