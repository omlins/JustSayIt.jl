"""
Module Email

Provides functions for operations in an Email client.

# Functions

###### Open inbox
- [`inbox`](@ref)

To see a description of a function type `?<functionname>`.
"""
module Email

import DefaultApplication
import ..JustSayIt: @voiceargs


## CONSTANTS

const EMAIL_ENGINE = "https://mail.google.com"


## Functions

@doc """
    email `inbox`

Manage e-mails, performing one of the following actions:
    - `inbox`
"""
email
@enum Action inbox
@voiceargs action=>(valid_input_auto=true, use_max_accuracy=true) function email(action::Action)
    if (action == inbox) open_inbox()
    else @info "unknown action" #NOTE: this should never happen.
    end
end

@doc "Search in internet: start search engine and automatically change to type command waiting for search keywords to be spoken."
function open_inbox()
    DefaultApplication.open(EMAIL_ENGINE)
end

end # module Email
