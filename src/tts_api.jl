## API FUNCTIONS

"Return whether TTS playback is currently active on the selected engine and stream."
is_playing_tts(; enginename::String=tts(), streamname::String=TTS_DEFAULT_STREAM) = is_tts_stream(enginename, streamname) && stream(enginename, streamname).is_playing()

"Pause the current TTS playback on the selected engine and stream."
pause_tts(; enginename::String=tts(), streamname::String=TTS_DEFAULT_STREAM)      = if is_playing_tts(enginename=enginename, streamname=streamname) stream(enginename, streamname).pause() end

"Resume paused TTS playback on the selected engine and stream."
resume_tts(; enginename::String=tts(), streamname::String=TTS_DEFAULT_STREAM)     = if is_playing_tts(enginename=enginename, streamname=streamname) stream(enginename, streamname).resume() end

"Stop the current TTS playback on the selected engine and stream."
stop_tts(; enginename::String=tts(), streamname::String=TTS_DEFAULT_STREAM)       = if is_playing_tts(enginename=enginename, streamname=streamname) stream(enginename, streamname).stop(); stop_progresser(enginename=enginename, streamname=streamname) end


## API MACROS

"""
    @voiceinfo message

Log `message` and speak it through the active TTS engine.
"""
macro voiceinfo(args...) esc(voiceinfo(args...)); end

function voiceinfo(args...)
    if (length(args) != 1) @ArgumentError("The `voiceinfo` macro takes exactly one argument.") end
    return :(@info($((args...))); say($(args...)))
end
