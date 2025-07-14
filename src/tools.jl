function remove_end_punctuation(words_str::AbstractString, lang::String)
    if lang != LANG_AUTO
        return replace(words_str, r"\p{P}+$" => "")
    else
        return words_str
    end
end

function get_clipboard_content()
    root = Tkinter.Tk() # NOTE: it seems to be necessary that the root object is created after the keyboard copy shortcut is executed has otherwise the clipboard does sometimes not contain the new content.
    root.withdraw()
    root.update()
    content = ""
    try
        content = root.clipboard_get()
    catch e
        if isa(e, PyCall.PyError)
            content = ""
        else
            rethrow(e)
        end
    end
    root.update()
    root.destroy()
    return content
end

function get_selection_content()
    sleep(0.1)
    root = Tkinter.Tk() # NOTE: it seems to be necessary that the root object is created after the keyboard copy shortcut is executed has otherwise the clipboard does sometimes not contain the new content.
    root.withdraw()
    root.update()
    content = ""
    try
        content = root.selection_get(selection="PRIMARY")
    catch e
        if isa(e, PyCall.PyError)
            content = ""
        else
            rethrow(e)
        end
    end
    root.update()
    root.destroy()
    return content
end

function download_and_unzip(destination, filename, repository)
    progress = nothing
    previous = 0
    function show_progress(total::Integer, now::Integer)
        if (total > 0) && (now != previous)
            if isnothing(progress) progress = ProgressMeter.Progress(total; dt=0.1, desc="Download ($(Base.format_bytes(total))): ", color=:magenta, output=stderr) end
            ProgressMeter.update!(progress, now)
        end
        previous = now
    end
    mkpath(destination)
    filepath = joinpath(destination, filename)
    Downloads.download(repository * "/" * filename, filepath; progress=show_progress)
    @pywith Zipfile.ZipFile(filepath, "r") as archive begin
        archive.extractall(destination)
    end
end

function ramdisk_tempdir()
    shm = "/dev/shm"
    if (Sys.islinux() && isdir(shm) && iswritable(shm)) return shm
    else                                                return tempdir()
    end
end

let
    global tic, toc
    t0::Union{Float64,Nothing} = nothing

    tic()::Float64            = ( t0 = time() )
    toc()::Float64            = ( time() - t0 )
    toc(t1::Float64)::Float64 = ( time() - t1 )
end
