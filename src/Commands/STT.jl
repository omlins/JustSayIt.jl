"""
Module STT

Provides functions for speech-to-text (STT).

# Functions

###### Text recognition
- [`STT.listen`](@ref)

To see a description of a function type `?<functionname>`.
"""
module STT

using ..JustSayIt.API
public listen


## COMMAND FUNCTIONS

"Listen to speech and return the next word group."
listen(; lang::String=default_language()) = return join(next_wordgroup(lang=lang), " ")

end # module STT
