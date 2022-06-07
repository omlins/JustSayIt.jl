"""
Module Internet

Provides functions for navigating in the internet by voice.

# Functions

###### Searching
- [`search`](@ref)

To see a description of a function type `?<functionname>`.

See also: [`Email`](@ref)
"""
module Internet

using PyCall
import DefaultApplication
import ..JustSayIt: @voiceargs, Keyboard, Key


## CONSTANTS

const SEARCH_ENGINE = "https://google.com"
const SEARCH_DOC = "start search engine, enter \"type text\" mode to obtain search words from speech and then trigger the search when the keyword \"search\" is spoken."


## FUNCTIONS

@doc """
    internet `search`

Navigate the internet, performing one of the following actions:
- `search`: $SEARCH_DOC
"""
internet
@enum Action search
@voiceargs action=>(valid_input_auto=true) function internet(action::Action)
    if (action == search) search_internet()
    else @info "unknown action" #NOTE: this should never happen.
    end
end

@doc SEARCH_DOC
function search_internet()
    DefaultApplication.open(SEARCH_ENGINE)
    Keyboard.type(Keyboard.text; end_keyword="search")
    Keyboard.press_keys(Key.enter)
end

end # module Internet
