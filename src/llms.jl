let
    global llm, start_llms, stop_llms
    _default_model::String             = ""
    _large_model::String               = ""
    llm(use_large::Bool=false)::String = ((use_large && !isempty(_large_model)) ? _large_model : _default_model)


    function start_llms(llm_localmodel::String, llm_remotemodel::String, llm_remotemodel_apikey::String)
        # Local model
        if !isempty(llm_localmodel)
            install_ollama()                  # Install Ollama application if not already installed
            switch_local_llm(llm_localmodel)
        end

        # Remote model
        if !isempty(llm_remotemodel)
            if isempty(llm_remotemodel_apikey) @APIUsageError("API key for remote model is missing.") end

            _large_model   = llm_remotemodel
            _default_model = isempty(_default_model) ? _large_model : _default_model
        end
    end


    function switch_local_llm(modelname::String)
        is_installed      = is_llm_installed(modelname)
        pull_llm(modelname) # Pull the model if not already pulled
        test_question     = "Please correct the text below. Fix only grammar and spelling errors. Do not change sentence structure, word order, or phrasing in any way. Do not paraphrase or introduce new words. Only correct grammar and spelling while preserving the exact meaning. Output only the corrected text, without explanations, tags, quotes, or comments. <text>These things are not always good i think. he's good to be corrected from someone who knows.</text>"
        if !is_installed || !is_llm_loaded(modelname)
            generateResponse  = Ollama.generate(modelname, test_question)
            t_load            = convert(Float64, generateResponse["load_duration"]/1e9)
            println("LLM model $modelname was loaded in $(round(t_load, digits=3)) seconds (first time load).")
        end
        generateResponse  = Ollama.generate(modelname, test_question, keep_alive="-1m") # Keep the model loaded forever (to be unloaded manually using ollama stop <modelname>)
        t_total           = convert(Float64, generateResponse["total_duration"]/1e9)
        t_load            = convert(Float64, generateResponse["load_duration"]/1e9)
        tokens_per_second = convert(Float64, split_response(get_response(generateResponse))[1] |> split |> length) / t_total
        println("LLM model $modelname accomplished a small test task in $(round(t_total, digits=3)) s (model reload: $(round(t_load, digits=3)) s): $(round(tokens_per_second, digits=1)) tokens/s.")
        println("LLM models loaded:")
        run(`ollama ps`)
        _default_model = modelname
    end

    unload_local_llm(modelname::String) = run(`ollama stop $modelname`)
end


function install_ollama()
    try
        run(`ollama --version`)
    catch
        @info "To run a LLM model locally, Ollama is required but not installed (or not setup correctly). Install Ollama now?"
        answer = ""
        while !(answer in ["yes", "no"]) println("Type \"yes\" or \"no\":")
            answer = readline()
        end
        if answer == "yes"
            if Sys.islinux()
                run(`curl -fsSL https://ollama.com/install.sh \| sh`)
            elseif Sys.isapple()
                run(`brew install --cask ollama`)
            elseif Sys.iswindows()
                installer = Downloads.download("https://ollama.com/download/OllamaSetup.exe"; progress=show_progress)
                @info "Follow the instructions of the installer to install Ollama. It is crucial to note the following (from Ollama documentation): \"The Ollama install does not require Administrator, and installs in your home directory by default. You'll need at least 4GB of space for the binary install. Once you've installed Ollama, you'll need additional space for storing the Large Language models, which can be tens to hundreds of GB in size. If your home directory doesn't have enough space, you can change where the binaries are installed, and where the models are stored.\""
                run(`$installer`)
            else
                @ExternalError("unknown operating system. Please install Ollama manually and try again.")
            end
            try
                run(`ollama --version`)
            catch
                @ExternalError("Installation failed. Please install Ollama manually and try again.")
            end 
        else
            @ExternalError("Installation aborted. Ollama is required to run a LLM model locally. You can install Ollama yourself and try again or use a remote model or set `use_llm=false`.")
        end
    end
end


function pull_llm(modelname::String)
    if !is_llm_installed(modelname)
        @info "To run a LLM model locally, it must be downloaded from the Ollama repository (the default LLM model used, $LLM_DEFAULT_LOCALMODEL, is about 1 GB, other models can be much bigger). Download the model $modelname now?"
        answer = ""
        while !(answer in ["yes", "no"]) println("Type \"yes\" or \"no\":")
            answer = readline()
        end
        if answer == "yes"
            try
                run(`ollama pull $modelname`)
            catch
                @ArgumentError("Model $modelname not found in Ollama repository. Please check the model name and try again.")
            end
            if !is_llm_installed(modelname) @ExternalError("Pulling the model $modelname failed.") end
        else
            @ExternalError("Download aborted. You can choose a smaller model or use a remote model or set `use_llm=false`.")
        end
    end
    println("LLM model $modelname is ready to use.")
end


function is_llm_installed(modelname::String)
    models = Ollama.list().models
    return any(m.model == modelname for m in models)
end

function is_llm_loaded(modelname::String)
    models = Ollama.ps().models
    return any(m.model == modelname for m in models)
end


function ask_llm(question::String; use_large::Bool=false, stream::Bool=false, show_thinking::Bool=true, delete::Bool=false, type_answer::Bool=true)
    if (show_thinking) @info "LLM question: $question" end
    model = llm(use_large) #"deepseek-r1:1.5b"
    if (delete) Keyboard.press_delete() end
    if stream
        is_thinking = false
        for part in Ollama.generate(model, question, stream=true)
            token = get_response(part)
            if (token == "<think>") 
                is_thinking = true
                if (show_thinking) @info "LLM thinking:" end
            end
            if (show_thinking) print(token) end
            if (!is_thinking && type_answer) Keyboard.type_string(token) end
            if (token == "</think>") 
                is_thinking = false
                if (show_thinking) println(); @info "LLM answer:" end
            end
        end
    else
        answer, thinking = llm_generate(model, question)
        if (show_thinking) 
            @info "LLM thinking: $thinking"
            @info "LLM answer: $answer"
        end
        if (type_answer) Keyboard.type_string(answer) end
    end
end


llm_generate(model::String, question::String) = split_response(get_response(Ollama.generate(model, question)))
get_response(generateResponse::PyObject)      = pystring(generateResponse["response"])[2:end-1]  # NOTE: remove the first and last character are single quotes added by Python


function split_response(response::String)
    thinking_match = match(r"<think>.+</think>", response)
    if isnothing(thinking_match) 
        thinking = ""
        answer   = response
    else                         
        thinking = thinking_match.match
        answer   = match(r"</think>\\n?\\n?(.+)", response).captures[1] 
    end
    return answer, thinking
end
    