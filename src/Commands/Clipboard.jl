"""
Module Clipboard

Provides functions for accessing the clipboard.

# Functions

###### Clipboard access
- [`Clipboard.take`](@ref)

To see a description of a function type `?<functionname>`.

See also: [`Selection`](@ref)
"""
module Clipboard

using ..JustSayIt.API
public take


## COMMAND FUNCTIONS

"""
    take

Take the content of the clipboard.
"""
take() = get_clipboard_content()

end # module Clipboard
