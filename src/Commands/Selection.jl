"""
Module Selection

Provides functions for accessing the text selected by the user.

# Functions

###### Selection Access
- [`Selection.grab`](@ref)

To see a description of a function type `?<functionname>`.

See also: [`Clipboard`](@ref)
"""
module Selection

using ..JustSayIt.API
public grab


## COMMAND FUNCTIONS

"""
    grab

Grab the text selected by the user.
"""
grab() = get_selection_content()

end # module Selection
