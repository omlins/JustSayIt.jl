"""
Module Mouse

Provides functions for controlling the mouse by voice.

# Functions

###### Button control
- [`click_left`](@ref)
- [`click_middle`](@ref)
- [`click_right`](@ref)
- [`press_left`](@ref)
- [`release_left`](@ref)
- [`click_double`](@ref)
- [`click_triple`](@ref)

To see a description of a function type `?<functionname>`.
"""
module Mouse

using PyCall
import ..JustSayIt: @voiceargs, pyimport_pip, controller, set_controller


## PYTHON MODULES

const Pynput = PyNULL()

function __init__()
    copy!(Pynput, pyimport_pip("pynput"))
    set_controller("mouse", Pynput.mouse.Controller())
end


## Functions

"Click left mouse button."
click_left(;count::Integer=1) = controller("mouse").click(Pynput.mouse.Button.left, count)

"Click middle mouse button."
click_middle() = controller("mouse").click(Pynput.mouse.Button.middle)

"Click right mouse button."
click_right() = controller("mouse").click(Pynput.mouse.Button.right)

"Press and hold left mouse button."
press_left() = controller("mouse").press(Pynput.mouse.Button.left)

"Release left mouse button."
release_left() = controller("mouse").release(Pynput.mouse.Button.left)

"Doubleclick left mouse button."
click_double() = click_left(;count=2)

"Trippleclick left mouse button."
click_triple() = click_left(;count=3)

end # module Mouse
