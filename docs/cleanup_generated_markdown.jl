function generated_markdown_pairs(rootdir::AbstractString)
    pairs = Tuple{String, String}[]
    for (current_root, _, files) in walkdir(rootdir)
        for upper_name in files
            if !endswith(upper_name, ".MD")
                continue
            end
            lower_name = replace(upper_name, r"\.MD$" => ".md")
            lower_path = joinpath(current_root, lower_name)
            upper_path = joinpath(current_root, upper_name)
            if isfile(lower_path)
                push!(pairs, (upper_path, lower_path))
            end
        end
    end
    return sort(pairs; by=last)
end

function cleanup_generated_markdown(rootdir::AbstractString)
    removed_files = String[]
    for (_, lower_path) in generated_markdown_pairs(rootdir)
        rm(lower_path; force=true)
        push!(removed_files, lower_path)
    end
    if isempty(removed_files)
        @info "Cleanup generated .md-files: no generated files found."
    else
        @info "Cleanup generated .md-files: removed generated files." files=removed_files
    end
    return removed_files
end