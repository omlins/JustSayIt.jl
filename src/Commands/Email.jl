"""
Module Email

Provides functions for operations in an Email client.

# Functions

###### Open inbox
- [`inbox`](@ref)

To see a description of a function type `?<functionname>`.

See also: [`Internet`](@ref)
"""
module Email

import DefaultApplication
import ..JustSayIt: @voiceargs


## CONSTANTS

const EMAIL_ENGINE = "https://mail.google.com"


## FUNCTIONS

@doc """
    email `inbox` | `outbox`

Manage e-mails, performing one of the following actions:
- open `inbox`
- open `outbox`
"""
email
@enum Action inbox outbox
@voiceargs action=>(valid_input_auto=true) function email(action::Action)
    if     (action == inbox)  open_inbox()
    elseif (action == outbox) open_outbox()
    else                      @info "unknown action"  #NOTE: this should never happen.
    end
end

@doc "Open E-mail inbox."
open_inbox() = DefaultApplication.open(EMAIL_ENGINE)

@doc "Open E-mail outbox."
open_outbox() = DefaultApplication.open(EMAIL_ENGINE * "/" * "#sent")

end # module Email
