"""
Module Internet

Provides functions for navigating in the internet by voice.

# Functions

###### Searching
- [`search`](@ref)

To see a description of a function type `?<functionname>`.
"""
module Internet

import DefaultApplication
import ..JustSayIt: @voiceargs, Keyboard


## CONSTANTS

const SEARCH_ENGINE = "https://google.com"


## Functions

@doc """
    internet `search`

Navigate the internet, performing one of the following actions:
- `search`
"""
internet
@enum Action search
@voiceargs action=>(valid_input_auto=true, use_max_accuracy=true) function internet(action::Action)
    if (action == search) search_internet()
    else @info "unknown action" #NOTE: this should never happen.
    end
end

@doc "Search in internet: start search engine and automatically change to type command waiting for search keywords to be spoken."
function search_internet()
    DefaultApplication.open(SEARCH_ENGINE)
    Keyboard.type(Keyboard.text)
end

end # module Internet
