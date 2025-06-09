let
    global llm, start_llm, stop_llm, switch_llm
    USE_LOCAL_LLM::Bool    = true
    _default_model::String = ""
    llm()::String          = _default_model


    function start_llm(modelname::String, api_key::String)
        if isempty(modelname) @APIUsageError("LLM model name is missing.") end
        USE_LOCAL_LLM = isempty(api_key)
        if USE_LOCAL_LLM
            install_ollama()  # Install Ollama application if not already installed
            switch_local_llm(modelname)
        else
            set_llm_api_key(api_key)
            switch_remote_llm(modelname)
        end
    end

    function stop_llm()
        if USE_LOCAL_LLM && !isempty(_default_model)
            unload_local_llm(_default_model)
            _default_model = ""
        end
    end

    function switch_local_llm(modelname::String)
        is_installed      = is_llm_installed(modelname)
        pull_llm(modelname) # Pull the model if not already pulled
        test_question     = "Please correct the text below. Fix only grammar and spelling errors. Do not change sentence structure, word order, or phrasing in any way. Do not paraphrase or introduce new words. Only correct grammar and spelling while preserving the exact meaning. Output only the corrected text, without explanations, tags, quotes, or comments. <text>These things are not always good i think. he's good to be corrected from someone who knows.</text>"
        generateResponse  = nothing
        if !is_installed || !is_llm_loaded(modelname)
            try
                generateResponse  = Ollama.generate(modelname, test_question)
            catch
                install_ollama(; force_reinstall=true)
                pull_llm(modelname)
                generateResponse  = Ollama.generate(modelname, test_question)
            end
            t_load            = convert(Float64, generateResponse["load_duration"]/1e9)
            println("LLM model $modelname was loaded in $(round(t_load, digits=3)) seconds (first time load).")
        end
        try
            generateResponse  = Ollama.generate(modelname, test_question, keep_alive="-1m") # Keep the model loaded forever (to be unloaded manually using ollama stop <modelname>)
        catch
            install_ollama(; force_reinstall=true)
            pull_llm(modelname)
            generateResponse  = Ollama.generate(modelname, test_question, keep_alive="-1m") # Keep the model loaded forever (to be unloaded manually using ollama stop <modelname>)
        end
        t_total           = convert(Float64, generateResponse["total_duration"]/1e9)
        t_load            = convert(Float64, generateResponse["load_duration"]/1e9)
        tokens_per_second = convert(Float64, split_response(get_response(generateResponse))[1] |> split |> length) / t_total
        println("LLM model $modelname accomplished a small test task in $(round(t_total, digits=3)) s (model reload: $(round(t_load, digits=3)) s): $(round(tokens_per_second, digits=1)) tokens/s.")
        println("LLM models loaded:")
        run(`ollama ps`)
        register_llm(modelname) # Register the model if not already registered (only after it has been verified to work!)
        set_default_llm(modelname) 
    end

    unload_local_llm(modelname::String) = run(`ollama stop $modelname`)
    
    function set_default_llm(modelname::String)
        if USE_LOCAL_LLM && !is_llm_loaded(modelname) @APIUsageError("Model $modelname is not loaded. Please load the model before setting it as default.") end
        if USE_LOCAL_LLM && !is_llm_registered(modelname) @APIUsageError("Model $modelname is not registered. Please register the model before setting it as default.") end
        PT.MODEL_CHAT = modelname
        _default_model = modelname
        @info "LLM default model set: $(PT.MODEL_CHAT)"
    end

    function set_llm_api_key(api_key::String)
        if isempty(api_key) @APIUsageError("API key for remote model is missing.") end
        PT.OPENAI_API_KEY = api_key
        @info "LLM: OpenAI API key set."
    end

    switch_remote_llm(modelname::String) = set_default_llm(modelname)

    switch_llm(modelname::String) = USE_LOCAL_LLM ? switch_local_llm(modelname) : switch_remote_llm(modelname)
end


function install_ollama(; force_reinstall::Bool=false)
    try
        run(`ollama --version`)
        if force_reinstall run(`ollama update`) end
    catch
        @voiceinfo "To run a LLM model locally, Ollama is required but not installed (or outdated or not setup correctly). (Re-)install Ollama now?"
        answer = ""
        while !(answer in ["yes", "no"]) println("Type \"yes\" or \"no\":")
            answer = readline()
        end
        if answer == "yes"
            if Sys.islinux()
                run(pipeline(`curl -fsSL https://ollama.com/install.sh`, `sh`))
            elseif Sys.isapple()
                if Sys.which("brew") === nothing
                    @ExternalError("Homebrew is not installed. Please install Homebrew from https://brew.sh/ and rerun JustSayIt.")
                else
                    run(`brew install --cask ollama`)
                end
            elseif Sys.iswindows()
                installer = Downloads.download("https://ollama.com/download/OllamaSetup.exe"; progress=show_progress)
                @voiceinfo "Follow the instructions of the installer to install Ollama. It is crucial to note the following (from Ollama documentation): \"The Ollama install does not require Administrator, and installs in your home directory by default. You'll need at least 4GB of space for the binary install. Once you've installed Ollama, you'll need additional space for storing the Large Language models, which can be tens to hundreds of GB in size. If your home directory doesn't have enough space, you can change where the binaries are installed, and where the models are stored.\""
                run(`cmd /c $(Base.shell_escape(installer))`)
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
        @voiceinfo "To run a LLM model locally, it must be downloaded from the Ollama repository (the default LLM model used, $LLM_DEFAULT_LOCALMODEL, is about 1 GB, other models can be much bigger). Download the model $modelname now?"
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

function register_llm(modelname::String)
    if !is_llm_registered(modelname)
        @info "Registering the model $modelname in the local registry."
        PT.register_model!(; name = modelname, schema = PT.OllamaSchema(), description = "$modelname model")
    end
end

function is_llm_installed(modelname::String)
    models = Ollama.list().models
    return any(m.model == modelname for m in models)
end

function is_llm_loaded(modelname::String)
    models = Ollama.ps().models
    return any(m.model == modelname for m in models)
end

function is_llm_registered(modelname::String)
    models = PT.list_registry()
    aliases = PT.list_aliases()
    return any(m == modelname for m in models) || any(m == modelname for m in aliases)
end


function ask_llm(question::String; stream::Bool=false, show_thinking::Bool=true, delete::Bool=false, type_answer::Bool=true, say_answer::Bool=false)
    if (show_thinking) @info "LLM question: $question" end
    model = llm()
    if (delete) Keyboard.press_delete() end
    play_delay = 30
    nb_tokens = 0
    if stream
        is_thinking = false
        for part in Ollama.generate(model, question, stream=true)
            token = get_response(part)
            if (token == "<think>") 
                is_thinking = true
                if (show_thinking) @info "LLM thinking:" end
            end
            if (show_thinking) print(token) end
            if !is_thinking
                if (type_answer) Keyboard.type_string(token) end
                if say_answer
                    if (nb_tokens < play_delay) feed_tts(token)
                    else                        say(token)
                    end
                end
            end
            if (token == "</think>") 
                is_thinking = false
                if (show_thinking) println(); @info "LLM answer:" end
            end
            nb_tokens += 1
        end
        if (nb_tokens <= play_delay) play_tts() end
    else
        answer, thinking = llm_generate(model, question)
        if (show_thinking) 
            @info "LLM thinking: $thinking"
            @info "LLM answer: $answer"
        end
        if (type_answer) Keyboard.type_string(answer) end
        if (say_answer) say(answer) end
    end
end


llm_generate(model::String, question::String) = split_response(get_response(Ollama.generate(model, question)))
get_response(generateResponse::PyObject)      = strip(pystring(generateResponse["response"]), ['\''])  # NOTE: remove the first and last character are single quotes added by Python


function split_response(response::AbstractString)
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
