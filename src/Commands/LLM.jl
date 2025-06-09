"""
Module LLM

Provides functions for operations using an LLM.

# Functions

###### Tools for text writing
- [`LLM.summarize`](@ref)
- [`LLM.translate`](@ref)
- [`LLM.ask`](@ref)
- [`LLM.ask_with_text`](@ref)

###### Tools for text reading
- [`LLM.voice_summarize`](@ref)
- [`LLM.voice_translate`](@ref)
- [`LLM.voice_ask`](@ref)
- [`LLM.voice_ask_with_text`](@ref)

To see a description of a function type `?<functionname>`.
"""
module LLM

using PyCall
import ..Keyboard: get_selection_content, get_clipboard_content
import ..JustSayIt: @voiceargs, @voiceconfig, MODELNAME, LANG, interpret_enum, ask_llm, active_app, @APIUsageError
import ..JustSayIt: @ai_str
export summarize, voice_summarize, translate, voice_translate, ask, voice_ask, ask_with_text, voice_ask_with_text

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


## API FUNCTIONS

"""
    summarize

Use LLM to summarize the selected text (or text from clipboard).
"""
summarize(; stream::Bool=true, show_thinking::Bool=true) = _summarize(; stream=stream, show_thinking=show_thinking)


"""
    voice_summarize

Use LLM to summarize the selected text (or text from clipboard) and read it out loud.
"""
voice_summarize(; stream::Bool=false, show_thinking::Bool=true) = _summarize(; stream=stream, show_thinking=show_thinking, type_answer=false, say_answer=true)


function _summarize(; stream::Bool=true, show_thinking::Bool=true, type_answer::Bool=true, say_answer::Bool=false)
    delete = type_answer
    question = "Please summarize the text below. Output only the summary, without explanations, tags, quotes, or comments."
    modify_or_write_new(question; stream=stream, show_thinking=show_thinking, delete=delete, type_answer=type_answer, say_answer=say_answer)
end


"""
    translate `language`

Use LLM to translate the selected text (or text from clipboard) to the specified language.
"""
translate(; stream::Bool=true, show_thinking::Bool=true) = _translate(; stream=stream, show_thinking=show_thinking)


"""
    voice_translate `language`

Use LLM to translate the selected text (or text from clipboard) to the specified language and read it out loud.
"""
voice_translate(; stream::Bool=false, show_thinking::Bool=true) = _translate(; stream=stream, show_thinking=show_thinking, type_answer=false, say_answer=true)


@voiceargs language=>(valid_input=TRANSLATION_LANGUAGES) function _translate(language::String; stream::Bool=true, show_thinking::Bool=true, type_answer::Bool=true, say_answer::Bool=false)
    delete = type_answer
    question = "Please translate the text below to $language. Output only the translated text, without explanations, tags, quotes, or comments."
    modify_or_write_new(question; stream=stream, show_thinking=show_thinking, delete=delete, type_answer=type_answer, say_answer=say_answer)
end


"""
    ask `question/instructions`

Use LLM to reply to the `question/instructions` (the LLM is aware of the current application used).
"""
ask(; stream::Bool=true, show_thinking::Bool=true, instruction_prefix::String="") = _ask(; stream=stream, show_thinking=show_thinking, instruction_prefix=instruction_prefix)


"""
    voice_ask `question/instructions`

Use LLM to reply to the `question/instructions` (the LLM is aware of the current application used) and read it out loud.
"""
voice_ask(; stream::Bool=false, show_thinking::Bool=true, instruction_prefix::String="") = _ask(; stream=stream, show_thinking=show_thinking, instruction_prefix=instruction_prefix, type_answer=false, say_answer=true)


"""
    ask_with_text `question/instructions`

Use LLM to reply to the `question/instructions` considering the selected text (or text from clipboard).
"""
ask_with_text(; stream::Bool=true, show_thinking::Bool=true, instruction_prefix::String="") = _ask(; stream=stream, show_thinking=show_thinking, instruction_prefix=instruction_prefix, with_text=true)


"""
    voice_ask_with_text `question/instructions`

Use LLM to reply to the `question/instructions` considering the selected text (or text from clipboard) and read it out loud.
"""
voice_ask_with_text(; stream::Bool=false, show_thinking::Bool=true, instruction_prefix::String="") = _ask(; stream=stream, show_thinking=show_thinking, instruction_prefix=instruction_prefix, with_text=true, type_answer=false, say_answer=true)


@voiceargs instruction_tokens=>(model=MODELNAME.TYPE.EN_US) function _ask(instruction_tokens::String...; stream::Bool=true, show_thinking::Bool=true, with_text::Bool=false, instruction_prefix::String="", type_answer::Bool=true, say_answer::Bool=false)
    instructions = instruction_prefix * " " * join(instruction_tokens, " ")
    delete = type_answer
    if with_text
        question = "Please reply to the following question/instructions concerning/considering the text below. Output only the answer, without explanations, tags, quotes, or comments."
        question = "$question\n\nQuestion/instructions:\n$instructions"
        modify_or_write_new(question; stream=stream, show_thinking=show_thinking, delete=delete, type_answer=type_answer, say_answer=say_answer)
    else
        question = "Please reply to the following question/instructions. Output only the answer, without explanations, tags, quotes, or comments."
        question = "$question\n\nQuestion/instructions:\n$instructions"
        write_new(question; stream=stream, show_thinking=show_thinking, type_answer=type_answer, say_answer=say_answer)
    end
end

end # module LLM
