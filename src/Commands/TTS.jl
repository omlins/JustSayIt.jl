"""
Module TTS

Provides functions for text-to-speech (TTS).

# Functions

###### Text reading
- [`TTS.read`](@ref)
- [`TTS.pause`](@ref)
- [`TTS.resume`](@ref)
- [`TTS.stop`](@ref)
- [`TTS.set_async_default`](@ref)

###### String reading
- [`TTS.say`](@ref)

To see a description of a function type `?<functionname>`.
"""
module TTS

using ..JustSayIt.API
import ..JustSayIt.TTScore; _say = TTScore.say
public read, pause, resume, stop, set_async_default, say


## COMMAND FUNCTIONS

"""
    read

Use TTS to read the selected text (or text from clipboard if no text is selected).
"""
function read(; async::Bool=tts_async_default())
    text = get_selection_content()
    if isempty(text) text = get_clipboard_content() end
    if isempty(text) _say("No text is selected or in the clipboard to read."); return end
    _say(text; async=async)
end

"""
    pause

Pause text reading.
"""
pause() = pause_tts()

"""
    resume

Resume text reading.
"""
resume() = resume_tts()

"""
    stop

Stop text reading.
"""
stop() = stop_tts()

"""
    set_async_default `async`

Set the default behavior for TTS to be asynchronous or not.
"""
set_async_default
@voiceargs async=>(valid_input=["asynchronous", "synchronous"]) function set_async_default(async::String)
    async = (async == "asynchronous")
    set_tts_async_default(async)
    _say("Default TTS behavior is now $(async ? "asynchronous" : "synchronous")."; async=async)
end

"""
    say(text::AbstractString)

Use TTS to say the given text.
"""
say(text::AbstractString) = _say(text)

end # module TTS
