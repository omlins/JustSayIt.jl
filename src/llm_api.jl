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

function ask_llm(question::AbstractString; stream::Bool=false, show_thinking::Bool=true, delete::Bool=false, type_answer::Bool=true, say_answer::Bool=false)
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


function ask_llm!(question::AbstractString; show_thinking::Bool=true, delete::Bool=true, type_answer::Bool=true, say_answer::Bool=false)
    #TODO: the implementation is missing and this currently just falls back to `ask_llm`
    ask_llm(question; stream=false, show_thinking=show_thinking, delete=delete, type_answer=type_answer, say_answer=say_answer)
end
