mutable struct Recognizer
    backend::Symbol
    pyobject::PyObject
    transcriber::PyObject
    is_persistent::Bool
    valid_input::AbstractArray{String}
    valid_tokens::AbstractArray{String}

    function Recognizer(backend::Symbol, pyobject::PyObject, transcriber::PyObject, is_persistent::Bool, valid_input::AbstractArray{String})
        valid_tokens = isempty(valid_input) ? String[] : [token for input in split.(valid_input) for token in input] |> unique |> collect
        new(backend, pyobject, transcriber, is_persistent, valid_input, valid_tokens)
    end

    function Recognizer(backend::Symbol, pyobject::PyObject, is_persistent::Bool, valid_input::AbstractArray{String})
        transcriber = PyNULL()
        Recognizer(backend, pyobject, transcriber, is_persistent, valid_input)
    end

    function Recognizer(pyobject::PyObject, is_persistent::Bool, valid_input::AbstractArray{String})
        backend = :Vosk
        Recognizer(backend, pyobject, is_persistent, valid_input)
    end

    function Recognizer(pyobject::PyObject, is_persistent::Bool)
        valid_input = String[]
        Recognizer(pyobject, is_persistent, valid_input)
    end

    function Recognizer(backend::Symbol, pyobject::PyObject, transcriber::PyObject)
        is_persistent = true
        valid_input = String[]
        @show transcriber
        if transcriber != PyNULL()
            if !(transcriber.is_running()) transcriber.start() end
        end
        Recognizer(backend, pyobject, transcriber, is_persistent, valid_input)
    end

    function Recognizer(backend::Symbol, pyobject::PyObject)
        transcriber = PyNULL()
        Recognizer(backend, pyobject, transcriber)
    end
end
