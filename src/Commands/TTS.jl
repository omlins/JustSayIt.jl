"""
Module TTS

Provides functions for text-to-speech (TTS).

# Functions

###### Tools for reading text
- [`TTS.read`](@ref)
- [`TTS.pause`](@ref)
- [`TTS.resume`](@ref)
- [`TTS.stop`](@ref)
- [`TTS.set_async_default`](@ref)

To see a description of a function type `?<functionname>`.
"""
module TTS

using PyCall
import ..Keyboard: get_selection_content, get_clipboard_content
import ..JustSayIt: @voiceargs, TTS_SUPPORTED_LOCALENGINES, switch_tts, is_playing_tts, pause_tts, resume_tts, stop_tts, set_tts_async, tts_async_default, say
export read, pause, resume, stop, set_async_default


## CONSTANTS

# const READING_LANGUAGES = ["english", "french", "german", "spanish", "italian", "portuguese", "dutch", "russian", "chinese", "japanese", "korean", "arabic", "turkish", "hindi"]


## API FUNCTIONS

"""
    read

Use TTS to read the selected text (or text from clipboard if no text is selected).
"""
function read(; async::Bool=tts_async_default())
    text = get_selection_content()
    if isempty(text) text = get_clipboard_content() end
    if isempty(text) say("No text is selected or in the clipboard to read."); return end
    say(text; streamname="read", async=async)
end

"""
    pause

Pause text reading.
"""
function pause()
    pause_tts(streamname="read")
end

"""
    resume

Resume text reading.
"""
function resume()
    resume_tts(streamname="read")
end

"""
    stop

Stop text reading.
"""
function stop()
    stop_tts(streamname="read")
end

"""
    set_async_default `async`

Set the default behavior for TTS to be asynchronous or not.
"""
set_async_default
@voiceargs async=>(valid_input=["asynchronous", "synchronous"]) function set_async_default(async::String)
    if (async == "asynchronous") set_tts_async(true)
    else                         set_tts_async(false)
    end
end

end # module TTS
