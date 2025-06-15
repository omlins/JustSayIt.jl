## API FUNCTIONS

is_playing_tts(; enginename::String=tts(), streamname::String=TTS_DEFAULT_STREAM) = is_tts_stream(enginename, streamname) && stream(enginename, streamname).is_playing()
pause_tts(; enginename::String=tts(), streamname::String=TTS_DEFAULT_STREAM)      = if is_playing_tts(enginename=enginename, streamname=streamname) stream(enginename, streamname).pause() end
resume_tts(; enginename::String=tts(), streamname::String=TTS_DEFAULT_STREAM)     = if is_playing_tts(enginename=enginename, streamname=streamname) stream(enginename, streamname).resume() end
stop_tts(; enginename::String=tts(), streamname::String=TTS_DEFAULT_STREAM)       = if is_playing_tts(enginename=enginename, streamname=streamname) stream(enginename, streamname).stop() end


## API MACROS

macro voiceinfo(args...) esc(voiceinfo(args...)); end

function voiceinfo(args...)
    if (length(args) != 1) @ArgumentError("The `voiceinfo` macro takes exactly one argument.") end
    return :(@info($((args...))); say($(args...)))
end
