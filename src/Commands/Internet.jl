"""
Module Internet

Provides functions for navigating in the internet by voice.

# Functions

###### Navigate the internet
- [`Internet.internet`](@ref)

To see a description of a function type `?<functionname>`.

See also: [`Email`](@ref)
"""
module Internet

using PyCall
import DefaultApplication
import ..JustSayIt: @voiceargs, LANG, Keyboard, Key, interpret_enum, default_language


## CONSTANTS

const SEARCH_ENGINE = "https://google.com"
const SEARCH_DOC = "start search engine, enter \"type text\" mode to obtain search words from speech and then trigger the search when the keyword \"search\" is spoken."

const ACTIONS = Dict(
    LANG.DE    => ["suchen"],
    LANG.EN_US => ["search"],
    LANG.ES    => ["buscar"],
    LANG.FR    => ["chercher"],
)

## FUNCTIONS

interpret_action(input::AbstractString) = interpret_enum(input, ACTIONS)

@doc """
    internet `search`

Navigate the internet, performing one of the following actions:
- `search`: $SEARCH_DOC
"""
internet
@enum Action search
@voiceargs action=>(valid_input=Tuple(ACTIONS), interpret_function=interpret_action) function internet(action::Action)
    if (action == search) search_internet()
    else @info "unknown action" #NOTE: this should never happen.
    end
end

@doc SEARCH_DOC
function search_internet()
    DefaultApplication.open(SEARCH_ENGINE)
    Keyboard.type(Keyboard.text; end_keyword=ACTIONS[default_language()][1], active_lang=default_language())
    Keyboard.press_keys(Key.enter)
end

end # module Internet
