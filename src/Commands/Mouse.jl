"""
Module Mouse

Provides functions for controlling the mouse by voice.

# Functions

###### Button control
- [`Mouse.click_left`](@ref)
- [`Mouse.click_middle`](@ref)
- [`Mouse.click_right`](@ref)
- [`Mouse.press_left`](@ref)
- [`Mouse.release_left`](@ref)
- [`Mouse.click_double`](@ref)
- [`Mouse.click_triple`](@ref)

To see a description of a function type `?<functionname>`.

See also: [`Keyboard`](@ref)
"""
module Mouse

using ..JustSayIt.API
import ..JustSayIt: MouseButton
public click_left, click_middle, click_right, press_left, release_left, click_double, click_triple #TODO: public and add to doc once the implementation is generic: move_to_center, move_to_north, move_to_south, move_to_east, move_to_west, move_to_northeast, move_to_northwest, move_to_southeast, move_to_southwest


## COMMAND FUNCTIONS

"Click left mouse button."
click_left(;count::Integer=1) = controller("mouse").click(MouseButton.left, count)

"Click middle mouse button."
click_middle() = controller("mouse").click(MouseButton.middle)

"Click right mouse button."
click_right() = controller("mouse").click(MouseButton.right)

"Press and hold left mouse button."
press_left() = controller("mouse").press(MouseButton.left)

"Release left mouse button."
release_left() = controller("mouse").release(MouseButton.left)

"Doubleclick left mouse button."
click_double() = click_left(;count=2)

"Trippleclick left mouse button."
click_triple() = click_left(;count=3)

####################################################################
#TEMP IMPLEMENTATION

"Move to center."
move_to_center() = controller("mouse").position = (1920÷2, 1080÷2)

"Move to north."
move_to_north() = controller("mouse").position = (1920÷2, 1080÷6*1)

"Move to south."
move_to_south() = controller("mouse").position = (1920÷2, 1080÷6*5)

"Move to east."
move_to_east() = controller("mouse").position = (1920÷6*5, 1080÷2)

"Move to west."
move_to_west() = controller("mouse").position = (1920÷6*1, 1080÷2)

"Move to north-east."
move_to_northeast() = controller("mouse").position = (1920÷6*5, 1080÷6*1)

"Move to north-west."
move_to_northwest() = controller("mouse").position = (1920÷6*1, 1080÷6*1)

"Move to south-east."
move_to_southeast() = controller("mouse").position = (1920÷6*5, 1080÷6*5)

"Move to south-west."
move_to_southwest() = controller("mouse").position = (1920÷6*1, 1080÷6*5)

####################################################################
#TEMP

end # module Mouse
