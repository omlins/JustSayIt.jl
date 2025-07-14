## HELPER FUNCTIONS

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


## API FUNCTIONS

function _ask_llm(question::AbstractString; stream::Bool=false, show_thinking::Bool=true, delete::Bool=false, type_answer::Bool=true, say_answer::Bool=false)
    if (show_thinking) @info "LLM question: $question" end
    model = llm()
    if (delete) Keyboard.press_delete() end
    play_delay = 30
    nb_tokens = 0
    answer = ""
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
                answer = join((answer, token), " ")
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
            if !isempty(thinking) @info "LLM thinking: $thinking" end
            @info "LLM answer: $answer"
        end
        if (type_answer) Keyboard.type_string(answer) end
        if (say_answer) say(answer) end
    end
    return answer
end

function _ask_llm_pt(question::AbstractString; stream::Bool=false, show_thinking::Bool=true, delete::Bool=false, type_answer::Bool=true, say_answer::Bool=false, follow_up::Bool=false)
    if (stream) @APIUsageError("streaming is not supported using the PT backend.") end
    if (show_thinking) @info "LLM question: $question" end
    if (delete) Keyboard.press_delete() end
    response = follow_up ? ai!"$question" : ai"$question"
    answer, thinking = split_response(response.content)
    if show_thinking
        if !isempty(thinking) @info "LLM thinking: $thinking" end
        @info "LLM answer: $answer"
    end
    if (type_answer) Keyboard.type_string(answer) end
    if (say_answer) say(answer) end
    return answer
end


function ask_llm(question::AbstractString; stream::Bool=false, show_thinking::Bool=true, delete::Bool=false, type_answer::Bool=true, say_answer::Bool=false)
    if stream
        if (!USE_LOCAL_LLM) @APIUsageError("streaming is not supported for remote LLMs.") end
        _ask_llm(question; stream=stream, show_thinking=show_thinking, delete=delete, type_answer=type_answer, say_answer=say_answer)
    else
        _ask_llm_pt(question; show_thinking=show_thinking, delete=delete, type_answer=type_answer, say_answer=say_answer)
    end
end

function ask_llm!(question::AbstractString; stream::Bool=false, show_thinking::Bool=true, delete::Bool=true, type_answer::Bool=true, say_answer::Bool=false)
    if (stream) @APIUsageError("streaming is not supported for questions with follow up.") end
    _ask_llm_pt(question; stream=stream, show_thinking=show_thinking, delete=delete, type_answer=type_answer, say_answer=say_answer, follow_up=true)
end
