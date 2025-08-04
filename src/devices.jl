let
    global controller, set_controller, finalize_devices, fix_keyboard_layout, restore_keyboard_layout
    _controllers::Dict{String, PyObject}              = Dict{String, PyObject}()
    _original_keyboard_layout                         = ("", "")
    _keyboard_layout_restored                         = false
    controller(name::AbstractString)::PyObject        = if (name in keys(_controllers)) return _controllers[name] else @APIUsageError("The controller for $name is not available as it has not been set up in init_jsi.") end
    set_controller(name::AbstractString, c::PyObject) = (_controllers[name] = c; return)


    function finalize_devices()
        @info "Finalizing devices..."
        restore_keyboard_layout()
    end

    function set_keyboard_layout(layout::Tuple{AbstractString, AbstractString})
        if !Sys.islinux()
            @error "Setting X-keyboard layout requires Linux with setxkbmap tool"
            return false
        end
        
        try
            layout_code, layout_variant = layout
            cmd = `setxkbmap $(layout_code) $(layout_variant)`
            run(cmd)
            return true
        catch e
            @error "Failed to set X-keyboard layout" exception=(e, catch_backtrace())
            return false
        end
    end

    function get_keyboard_layout()::Tuple{AbstractString, AbstractString}
        if !Sys.islinux()
            @error "Getting X-keyboard layout requires Linux with setxkbmap tool"
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
            @error "Failed to get X-keyboard layout" exception=(e, catch_backtrace())
            return ("", "")
        end
    end

    function fix_keyboard_layout()
        if !Sys.islinux() return end
        
        # Store the original keyboard layout
        _original_keyboard_layout = get_keyboard_layout()
        
        # Extract layout and variant strings
        layout_str, variant_str = _original_keyboard_layout
        
        # If multiple layouts are defined (comma-separated), use only the last one
        if contains(layout_str, ",")
            layouts = split(layout_str, ",")
            last_layout = strip(layouts[end])
            
            # Get corresponding variant (if any)
            last_variant = ""
            if !isempty(variant_str)
                variants = split(variant_str, ",")
                last_variant = length(variants) > 0 ? strip(variants[end]) : ""
            end
            
            # Set keyboard to use only the last layout
            set_keyboard_layout((last_layout, last_variant))
            @info "X-keyboard layout temporarily set to: $(last_layout) - $(last_variant) (original: $(layout_str) - $(variant_str))"
        end

        return
    end

    function has_multiple_layouts(layout::Tuple{AbstractString, AbstractString})::Bool
        if !Sys.islinux() @error "this function is only defined for Linux systems" end
        layout_str, ~ = layout
        return contains(layout_str, ",")
    end

    function restore_keyboard_layout()
        if !(Sys.islinux() && has_multiple_layouts(_original_keyboard_layout) && !_keyboard_layout_restored) return end
        _keyboard_layout_restored = set_keyboard_layout(_original_keyboard_layout)
        layout_str, variant_str = _original_keyboard_layout
        @info "X-keyboard layout restored to original: $(layout_str) - $(variant_str)"
        return
    end
end
