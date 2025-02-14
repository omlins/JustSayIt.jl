"""
Module LLM

Provides functions for operations using an LLM.

# Functions

###### Tools for modifying text
- [`LLM.correct`](@ref)
- [`LLM.improve`](@ref)
- [`LLM.recognize`](@ref)
- [`LLM.paraphrase`](@ref)
- [`LLM.content`](@ref)

###### Tools for writing new text
- [`LLM.summarize`](@ref)
- [`LLM.exemplify`](@ref)
- [`LLM.translate`](@ref)

###### Tools for generic requests
- [`LLM.ask`](@ref)

To see a description of a function type `?<functionname>`.
"""
module LLM

using PyCall
import ..Keyboard: get_selection_content, get_clipboard_content
import ..JustSayIt: @voiceargs, MODELNAME, LANG, interpret_enum, ask_llm, active_app, @APIUsageError


## CONSTANTS

const TRANSLATION_LANGUAGES = ["english", "french", "german", "spanish", "italian", "portuguese", "dutch", "russian", "chinese", "japanese", "korean", "arabic", "turkish", "hindi"]


## FUNCTIONS

# Use LLM to modify the selected text according to the `question`.
function modify_selection(question::String; use_large::Bool=false, stream::Bool=true, show_thinking::Bool=true)
    text     = get_selection_content()
    if isempty(text) @warn "No text selected." return end
    question = "$(app_context())\n$question\n<text>$text</text>"
    ask_llm(question; use_large=use_large, stream=stream, show_thinking=show_thinking, delete=true)
end


# Use LLM to modify the selected text according to the `question`, or, if no text is selected, write a new text based on the text in the clipboard.
function modify_or_new(question::String; use_large::Bool=false, stream::Bool=true, show_thinking::Bool=true)
    selection = get_selection_content()
    do_modify = !isempty(selection)
    text      = do_modify ? selection : get_clipboard_content()
    if isempty(text) @warn "No text selected or in clipboard." return end
    question  = "$(app_context())\n$question\n<text>$text</text>"
    ask_llm(question; use_large=use_large, stream=stream, show_thinking=show_thinking, delete=do_modify)
end


# Use LLM to write a new text based on the `question` (the LLM is aware of the current application used).
function new_text(question::String; use_large::Bool=false, stream::Bool=true, show_thinking::Bool=true)
    question = "$(app_context())\n$question"
    ask_llm(question; use_large=use_large, stream=stream, show_thinking=show_thinking, delete=false)
end


"""
    correct 

Use LLM to correct the selected text.
"""
function correct(; use_large::Bool=false, stream::Bool=true, show_thinking::Bool=true)
    question = "Please correct the text below. Fix only grammar and spelling errors. Do not change sentence structure, word order, or phrasing in any way. Do not paraphrase, reword, or introduce new words. Preserve all original words and their order exactly, making only necessary grammatical or spelling corrections. Output only the corrected text, without explanations, tags, quotes, or comments."
    modify_selection(question; use_large=use_large, stream=stream, show_thinking=show_thinking)
end


"""
    improve

Use LLM to improve the selected text.
"""
function improve(; use_large::Bool=false, stream::Bool=true, show_thinking::Bool=true, academic::Bool=false)
    tone = academic ? "formal academic" : "neutral"
    question = "Please improve the text below while preserving its original meaning. Enhance clarity, conciseness, coherence, fluency and readability. Enrich the vocabulary. Correct awkward phrasing, redundancy, and ambiguity. Do not remove or add information, change facts, or alter the intended message. Use a $tone tone and ensure grammatical correctness. Output only the improved text, without explanations, tags, quotes, or comments."
    modify_selection(question; use_large=use_large, stream=stream, show_thinking=show_thinking)
end


"""
    recognize

Use LLM to recognize the original content of the selected text (or text from clipboard) which has been distorted, knowing that the text stems from speech recognition that can create sentences that do not make any sense and are grammatically incorrect.
"""
function recognize(; use_large::Bool=false, stream::Bool=true, show_thinking::Bool=true)
    question = "Please recognize the original content of the text below, which has been distorted. It is crucial to know that the text stems from a speech recognition model that often confuses similarly sounding words, resulting in sentences that do not make any sense and are grammatically incorrect (the speech recognition model is small and rather simple; it is heavily based on sound comparison, word position and occurrence probabilities; it does not verify grammar and meaning center to help correct recognition). Typical recognition errors to correct are for example 1) \"he's\" instead of \"is\" (when it is the first word of the recognition or the only word) and 2) \"off\" instead of \"of\" (when it is the last word of the recognition or the only word). A good strategy to find the original content could be to try to replace parts that do not make any sense grammatically or in meaning with something else that sounds similar restore and restores coherence and grammatical correctness. Output only the recognized text, without explanations, tags, quotes, or comments."
    modify_selection(question; use_large=use_large, stream=stream, show_thinking=show_thinking)
end


"""
    paraphrase

Use LLM to paraphrase the selected text.
"""
function paraphrase(; use_large::Bool=false, stream::Bool=true, show_thinking::Bool=true)
    question = "Please paraphrase the text below. Ensure grammatical correctness, clarity, conciseness, coherence, fluency and readability in the paraphrased text. Output only the paraphrased text, without explanations, tags, quotes, or comments."
    modify_selection(question; use_large=use_large, stream=stream, show_thinking=show_thinking)
end


"""
    content

Use LLM to improve the content of the selected text.
"""
function content(; use_large::Bool=false, stream::Bool=true, show_thinking::Bool=true)
    question = "Please improve the content of the text below. In particular, fix wrong information and important information that is clearly missing.  Maintain the tone of the original text and ensure grammatical correctness. Output only the suggested improvements, without explanations, tags, quotes, or comments."
    modify_selection(question; use_large=use_large, stream=stream, show_thinking=show_thinking)
end


# """
#     suggest

# Use LLM to suggest content improvements for the selected text (or text from clipboard).
# """
# function suggest(; use_large::Bool=false, stream::Bool=true, show_thinking::Bool=true, academic::Bool=false)
#     text = get_selection_content()
#     tone = academic ? "formal academic" : "neutral"
#     question = "Please suggest content improvements for the text below. In particular, point out elements that are missing for the understanding of the text. Use a $tone tone and ensure grammatical correctness. Output only the suggested improvements, without explanations, tags, quotes, or comments.\n<text>$text</text>"
#     ask_llm(question; use_large=use_large, stream=stream, show_thinking=show_thinking, delete=false, type_answer=false)
# end


"""
    summarize

Use LLM to summarize the selected text (or text from clipboard).
"""
function summarize(; use_large::Bool=false, stream::Bool=true, show_thinking::Bool=true)
    question = "Please summarize the text below. Ensure grammatical correctness, clarity, conciseness, coherence, fluency and readability in the summarized text. Output only the summary, without explanations, tags, quotes, or comments."
    modify_or_new(question; use_large=use_large, stream=stream, show_thinking=show_thinking)
end


"""
    exemplify

Use LLM to exemplify the selected text (or text from clipboard).
"""
function exemplify(; use_large::Bool=false, stream::Bool=true, show_thinking::Bool=true)
    question = "Please exemplify the text below. Provide examples, illustrations, or instances that clarify the meaning of the text. Ensure grammatical correctness, clarity, conciseness, coherence, fluency and readability in the exemplified text. Output only the exemplified text, without explanations, tags, quotes, or comments."
    modify_or_new(question; use_large=use_large, stream=stream, show_thinking=show_thinking)
end


@doc """
    translate `language`

Use LLM to translate the selected text (or text from clipboard) to the specified language.
"""
translate
@voiceargs language=>(valid_input=TRANSLATION_LANGUAGES) function translate(language::String; use_large::Bool=false, stream::Bool=true, show_thinking::Bool=true)
    question = "Please translate the text below from to $language while preserving its original meaning. Do not remove or add information, change facts, or alter the intended message. Maintain the tone of the original text. Ensure grammatical correctness, clarity, conciseness, coherence, fluency and readability in the translated text. Output only the translated text, without explanations, tags, quotes, or comments."
    modify_or_new(question; use_large=use_large, stream=stream, show_thinking=show_thinking)
end


# # TODO: MODELNAME.TYPE.EN_US below instead?

@doc """
    ask `question/instructions`

Use LLM to reply to the `question/instructions` (the LLM is aware of the current application used).
"""
ask
ask(; use_large::Bool=false, stream::Bool=true, show_thinking::Bool=true, instruction_prefix::String="") = _ask(; use_large=use_large, stream=stream, show_thinking=show_thinking, instruction_prefix=instruction_prefix)


@doc """
    ask_with_text `question/instructions`

Use LLM to reply to the `question/instructions` considering the selected text (or text from clipboard).
"""
ask_with_text(; use_large::Bool=false, stream::Bool=true, show_thinking::Bool=true, instruction_prefix::String="") = _ask(; use_large=use_large, stream=stream, show_thinking=show_thinking, instruction_prefix=instruction_prefix, with_text=true)


@doc """
    ask_with_reference `question/instructions`

Use LLM to reply to the `question/instructions` considering the selected text as the primary text and the text from the clipboard as a reference.
"""
ask_with_reference(; use_large::Bool=false, stream::Bool=true, show_thinking::Bool=true, instruction_prefix::String="") = _ask(; use_large=use_large, stream=stream, show_thinking=show_thinking, instruction_prefix=instruction_prefix, with_text=true, with_reference=true)


@voiceargs instruction_tokens=>(model=MODELNAME.TYPE.EN_US, vararg_timeout=2.0) function _ask(instruction_tokens::String...; use_large::Bool=false, stream::Bool=true, show_thinking::Bool=true, with_text::Bool=false, with_reference::Bool=false, instruction_prefix::String="")
    if (with_reference && !with_text) @APIUsageError("with_reference=true requires with_text=true.") end
    instructions = instruction_prefix * " " * join(instruction_tokens, " ")
    if with_reference
        reference = get_clipboard_content()
        if isempty(reference) @warn "No text in clipboard." return end
        question = "Please reply to the following question/instructions concerning/considering the text below. In addition, take also given reference text below into account. Ensure grammatical correctness, clarity, conciseness, coherence, fluency and readability in the answer. Output only the answer, without explanations, tags, quotes, or comments.\n<question-instructions>$instructions</question-instructions>\n<reference>$reference</reference>"
        modify_selection(question; use_large=use_large, stream=stream, show_thinking=show_thinking)
    elseif with_text
        question = "Please reply to the following question/instructions concerning/considering the text below. Ensure grammatical correctness, clarity, conciseness, coherence, fluency and readability in the answer. Output only the answer, without explanations, tags, quotes, or comments.\n<question-instructions>$instructions</question-instructions>"
        modify_or_new(question; use_large=use_large, stream=stream, show_thinking=show_thinking)
    else
        question = "Please reply to the following question/instructions. Ensure grammatical correctness, clarity, conciseness, coherence, fluency and readability in the answer. Output only the answer, without explanations, tags, quotes, or comments.\n<question-instructions>$instructions</question-instructions>"
        new_text(question; use_large=use_large, stream=stream, show_thinking=show_thinking)
    end
end


app_context() = "<preamble> If it is relevant for the following question/instructions, please consider that me, the user, I'm currently using the following application: $(active_app()).</preamble>"

end # module LLM
