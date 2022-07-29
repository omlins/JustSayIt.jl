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

using PyCall
import ..JustSayIt: pyimport_pip, controller, set_controller


## PYTHON MODULES

const Pynput = PyNULL()

function __init__()
    ENV["PYTHON"] = ""                                              # Force PyCall to use Conda.jl
    copy!(Pynput, pyimport_pip("pynput"))
    set_controller("mouse", Pynput.mouse.Controller())
end


## FUNCTIONS

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
