let
    global controller, set_controller, finalize_devices, fix_keyboard_layout, restore_keyboard_layout
    _controllers::Dict{String, PyObject}              = Dict{String, PyObject}()
    _original_keyboard_layout                         = ("", "")
    controller(name::AbstractString)::PyObject        = if (name in keys(_controllers)) return _controllers[name] else @APIUsageError("The controller for $name is not available as it has not been set up in init_jsi.") end
    set_controller(name::AbstractString, c::PyObject) = (_controllers[name] = c; return)


    function finalize_devices()
        @info "Finalizing devices..."
        restore_keyboard_layout()
    end

    function set_keyboard_layout(layout::Tuple{AbstractString, AbstractString})
        if !Sys.islinux()
            @error "Setting keyboard layout requires Linux with setxkbmap tool"
            return false
        end
        
        try
            layout_code, layout_variant = layout
            cmd = `setxkbmap $(layout_code) $(layout_variant)`
            run(cmd)
            return true
        catch e
            @error "Failed to set keyboard layout" exception=(e, catch_backtrace())
            return false
        end
    end

    function get_keyboard_layout()::Tuple{AbstractString, AbstractString}
        if !Sys.islinux()
            @error "Getting keyboard layout requires Linux with setxkbmap tool"
            return ("", "")
        end
        
        try
            # Run setxkbmap -query to get current layout information
            output = read(`setxkbmap -query`, String)
            
            # Parse the output to extract complete layout and variant lines
            layout_match = match(r"layout:\s*(.*?)$"m, output)
            variant_match = match(r"variant:\s*(.*?)$"m, output)
            
            layout = isnothing(layout_match) ? "" : strip(layout_match.captures[1])
            variant = isnothing(variant_match) ? "" : strip(variant_match.captures[1])
            
            return (layout, variant)
        catch e
            @error "Failed to get keyboard layout" exception=(e, catch_backtrace())
            return ("", "")
        end
    end

    function fix_keyboard_layout()
        if !Sys.islinux() return end
        
        # Store the original keyboard layout
        _original_keyboard_layout = get_keyboard_layout()
        
        # Extract layout and variant strings
        layout_str, variant_str = _original_keyboard_layout
        
        # If multiple layouts are defined (comma-separated), use only the first one
        if contains(layout_str, ",")
            layouts = split(layout_str, ",")
            first_layout = strip(layouts[1])
            
            # Get corresponding variant (if any)
            first_variant = ""
            if !isempty(variant_str)
                variants = split(variant_str, ",")
                first_variant = length(variants) > 0 ? strip(variants[1]) : ""
            end
            
            # Set keyboard to use only the first layout
            set_keyboard_layout((first_layout, first_variant))
        end

        return
    end

    restore_keyboard_layout() = set_keyboard_layout(_original_keyboard_layout)
end
