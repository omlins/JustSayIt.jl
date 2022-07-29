"""
Module Email

Provides functions for operations in an Email client.

# Functions

###### Manage e-mails
- [`Email.email`](@ref)

To see a description of a function type `?<functionname>`.

See also: [`Internet`](@ref)
"""
module Email

import DefaultApplication
import ..JustSayIt: @voiceargs, LANG, interpret_enum


## CONSTANTS

const EMAIL_ENGINE = "https://mail.google.com"

const ACTIONS = Dict(
    LANG.DE    => ["eingang",   "ausgang"],
    LANG.EN_US => ["inbox",     "outbox"],
    LANG.ES    => ["entrada",   "salida"],
    LANG.FR    => ["réception", "envoi"],
)


## FUNCTIONS

interpret_action(input::AbstractString) = interpret_enum(input, ACTIONS)

@doc """
    email `inbox` | `outbox`

Manage e-mails, performing one of the following actions:
- open `inbox`
- open `outbox`
"""
email
@enum Action inbox outbox
@voiceargs action=>(valid_input=Tuple(ACTIONS), interpret_function=interpret_action) function email(action::Action)
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
