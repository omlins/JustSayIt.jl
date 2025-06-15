let
    global controller, set_controller
    _controllers::Dict{String, PyObject}                                                                = Dict{String, PyObject}()
    controller(name::AbstractString)::PyObject                                                          = if (name in keys(_controllers)) return _controllers[name] else @APIUsageError("The controller for $name is not available as it has not been set up in init_jsi.") end
    set_controller(name::AbstractString, c::PyObject)                                                   = (_controllers[name] = c; return)
end