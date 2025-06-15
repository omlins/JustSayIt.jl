"""
Module LLM

Provides functions for operations using an LLM.

# Functions

###### Text writing
- [`LLM.type_summary`](@ref)
- [`LLM.type_translation`](@ref)
- [`LLM.type_answer`](@ref)
- [`LLM.type_text_answer`](@ref)

###### Text reading
- [`LLM.read_summary`](@ref)
- [`LLM.read_translation`](@ref)
- [`LLM.read_answer`](@ref)
- [`LLM.read_text_answer`](@ref)

###### Text generation (no typing or reading)
- [`LLM.ask`](@ref)
- [`LLM.ask!`](@ref)

To see a description of a function type `?<functionname>`.
"""
module LLM

using ..JustSayIt.API
import ..JustSayIt.LLMcore: @ai_str
public type_summary, read_summary, type_translation, read_translation, type_answer, read_answer, type_text_answer, read_text_answer

## CONSTANTS

const TRANSLATION_LANGUAGES = ["english", "french", "german", "spanish", "italian", "portuguese", "dutch", "russian", "chinese", "japanese", "korean", "arabic", "turkish", "hindi"]


## HELPER FUNCTIONS

# Use LLM to modify the selected text according to the `question`, or, if no text is selected, write a new text based on the text in the clipboard.
function modify_or_write_new(question::String; stream::Bool=true, show_thinking::Bool=true, delete::Bool=true, type_answer::Bool=true, say_answer::Bool=false)
    selection = get_selection_content()
    do_modify = !isempty(selection)
    text      = do_modify ? selection : get_clipboard_content()
    if isempty(text) @warn "No text selected or in clipboard." return end
    question  = "$question\n\nText:\n$text"
    ask_llm(question; stream=stream, show_thinking=show_thinking, delete=(delete && do_modify), type_answer=type_answer, say_answer=say_answer)
end


# Use LLM to write a new text based on the `question` (the LLM is aware of the current application used).
function write_new(question::String; stream::Bool=true, show_thinking::Bool=true, type_answer::Bool=true, say_answer::Bool=false)
    ask_llm(question; stream=stream, show_thinking=show_thinking, delete=false, type_answer=type_answer, say_answer=say_answer)
end


## COMMAND FUNCTIONS

"""
    type_summary

Use LLM to summarize the selected text (or text from clipboard) and type it.
"""
type_summary(; stream::Bool=true, show_thinking::Bool=true) = _summarize(; stream=stream, show_thinking=show_thinking)


"""
    read_summary

Use LLM to summarize the selected text (or text from clipboard) and read it out loud.
"""
read_summary(; stream::Bool=false, show_thinking::Bool=true) = _summarize(; stream=stream, show_thinking=show_thinking, type_answer=false, say_answer=true)


function _summarize(; stream::Bool=true, show_thinking::Bool=true, type_answer::Bool=true, say_answer::Bool=false)
    delete = type_answer
    question = "Please summarize the text below. Output only the summary, without explanations, tags, quotes, or comments."
    modify_or_write_new(question; stream=stream, show_thinking=show_thinking, delete=delete, type_answer=type_answer, say_answer=say_answer)
end


"""
    type_translation `language`

Use LLM to translate the selected text (or text from clipboard) to the specified language and type it.
"""
type_translation(; stream::Bool=true, show_thinking::Bool=true) = _translate(; stream=stream, show_thinking=show_thinking)


"""
    read_translation `language`

Use LLM to translate the selected text (or text from clipboard) to the specified language and read it out loud.
"""
read_translation(; stream::Bool=false, show_thinking::Bool=true) = _translate(; stream=stream, show_thinking=show_thinking, type_answer=false, say_answer=true)


@voiceargs language=>(valid_input=TRANSLATION_LANGUAGES) function _translate(language::String; stream::Bool=true, show_thinking::Bool=true, type_answer::Bool=true, say_answer::Bool=false)
    delete = type_answer
    question = "Please translate the text below to $language. Output only the translated text, without explanations, tags, quotes, or comments."
    modify_or_write_new(question; stream=stream, show_thinking=show_thinking, delete=delete, type_answer=type_answer, say_answer=say_answer)
end


"""
    type_answer `question/instructions`

Use LLM to reply to the `question/instructions` and type it.
"""
type_answer(; stream::Bool=true, show_thinking::Bool=true, instruction_prefix::String="", lang::String=default_language()) = @voiceconfig language=lang _answer(; stream=stream, show_thinking=show_thinking, instruction_prefix=instruction_prefix)


"""
    read_answer `question/instructions`

Use LLM to reply to the `question/instructions` and read it out loud.
"""
read_answer(; stream::Bool=false, show_thinking::Bool=true, instruction_prefix::String="") = _answer(; stream=stream, show_thinking=show_thinking, instruction_prefix=instruction_prefix, type_answer=false, say_answer=true)


"""
    type_text_answer `question/instructions`

Use LLM to reply to the `question/instructions` considering the selected text (or text from clipboard) and type it.
"""
type_text_answer(; stream::Bool=true, show_thinking::Bool=true, instruction_prefix::String="", lang::String=default_language()) = @voiceconfig language=lang _answer(; stream=stream, show_thinking=show_thinking, instruction_prefix=instruction_prefix, with_text=true)


"""
    read_text_answer `question/instructions`

Use LLM to reply to the `question/instructions` considering the selected text (or text from clipboard) and read it out loud.
"""
read_text_answer(; stream::Bool=false, show_thinking::Bool=true, instruction_prefix::String="") = _answer(; stream=stream, show_thinking=show_thinking, instruction_prefix=instruction_prefix, with_text=true, type_answer=false, say_answer=true)


@voiceargs instruction_tokens=>(modeltype=MODELTYPE_SPEECH) function _answer(instruction_tokens::String...; stream::Bool=true, show_thinking::Bool=true, with_text::Bool=false, instruction_prefix::String="", type_answer::Bool=true, say_answer::Bool=false)
    instructions = instruction_prefix * " " * join(instruction_tokens, " ")
    delete = type_answer
    if with_text
        question = "Please reply to the following question/instructions concerning/considering the text below. Reply in the same language as the \"Question/instructions\". Output only the answer, without explanations, tags, quotes, or comments."
        question = "$question\n\nQuestion/instructions:\n$instructions"
        modify_or_write_new(question; stream=stream, show_thinking=show_thinking, delete=delete, type_answer=type_answer, say_answer=say_answer)
    else
        question = "Please reply to the following question/instructions. Reply in the same language as the \"Question/instructions\". Output only the answer, without explanations, tags, quotes, or comments."
        question = "$question\n\nQuestion/instructions:\n$instructions"
        write_new(question; stream=stream, show_thinking=show_thinking, type_answer=type_answer, say_answer=say_answer)
    end
end


"""
    ask(question::AbstractString)

Use LLM to reply to the `question`.
"""
ask(question::AbstractString) = ask_llm(question; stream=false, show_thinking=true, delete=false, type_answer=false, say_answer=false)


"""
    ask!(question::AbstractString)
Use LLM to reply to the `question` and type the answer.
"""
ask!(question::AbstractString) = ask_llm!(question; show_thinking=true, delete=false, type_answer=false, say_answer=false)

end # module LLM
