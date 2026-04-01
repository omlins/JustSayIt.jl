```@meta
CurrentModule = JustSayIt
```

# Software reference

This is the official Software reference of `JustSayIt`. Note that it can also be queried interactively from the [Julia REPL] using the [help mode](https://docs.julialang.org/en/v1/stdlib/REPL/#Help-mode):
```julia-repl
julia> using JustSayIt
julia>?
help?> JustSayIt
```

## Root module
```@docs
JustSayIt
```

## Functions to configure and start JustSayIt
#### Index
* [`JustSayIt.start`](@ref)
* [`JustSayIt.@include`](@ref)
* [`JustSayIt.@edit`](@ref)

#### Documentation
```@docs
start
@include
@edit
```

## Root convenience reexports
#### Index
* [`JustSayIt.take`](@ref)
* [`JustSayIt.type`](@ref)
* [`JustSayIt.ask`](@ref)
* [`JustSayIt.ask!`](@ref)
* [`JustSayIt.grab`](@ref)
* [`JustSayIt.listen`](@ref)
* [`JustSayIt.say`](@ref)

#### Documentation
```@docs
take
type
ask
ask!
grab
listen
say
```

## Public helper utilities
#### Index
* [`JustSayIt.set_preferences!`](@ref)
* [`JustSayIt.load_preference`](@ref)
* [`JustSayIt.has_preference`](@ref)
* [`JustSayIt.delete_preferences!`](@ref)

#### Documentation
```@docs
set_preferences!
load_preference
has_preference
delete_preferences!
```

## Software-facing modules
#### Index
* [`JustSayIt.Clipboard`](@ref)
* [`JustSayIt.Generic`](@ref)
* [`JustSayIt.Help`](@ref)
* [`JustSayIt.Keyboard`](@ref)
* [`JustSayIt.LLM`](@ref)
* [`JustSayIt.Mouse`](@ref)
* [`JustSayIt.Selection`](@ref)
* [`JustSayIt.STT`](@ref)
* [`JustSayIt.TTS`](@ref)

#### Documentation
```@docs
Clipboard
Generic
Help
Keyboard
LLM
Mouse
Selection
STT
TTS
```

## Keyboard shortcut namespace
The root `JustSayIt` module also re-exports `Key` for command mappings and keyboard shortcuts.
Use `Key.` completion in the Julia REPL to inspect the currently available key names.


## Functions of [`Generic`](@ref)
#### Index
```@index
Modules = [JustSayIt.Generic]
Order = [:function]
```

#### Documentation
```@autodocs
Modules = [JustSayIt.Generic]
Order = [:function]
```


## Functions of [`Help`](@ref)
#### Index
```@index
Modules = [JustSayIt.Help]
Order = [:function]
```

#### Documentation
```@autodocs
Modules = [JustSayIt.Help]
Order = [:function]
```


## Functions of [`Keyboard`](@ref)
#### Index
```@index
Modules = [JustSayIt.Keyboard]
Order = [:function]
```

#### Documentation
```@autodocs
Modules = [JustSayIt.Keyboard]
Order = [:function]
```


## Functions of [`LLM`](@ref)
#### Index
```@index
Modules = [JustSayIt.LLM]
Order = [:function]
```

#### Documentation
```@autodocs
Modules = [JustSayIt.LLM]
Order = [:function]
```


## Functions of [`Mouse`](@ref)
#### Index
```@index
Modules = [JustSayIt.Mouse]
Order = [:function]
```

#### Documentation
```@autodocs
Modules = [JustSayIt.Mouse]
Order = [:function]
```


## Functions of [`TTS`](@ref)
#### Index
```@index
Modules = [JustSayIt.TTS]
Order = [:function]
```

#### Documentation
```@autodocs
Modules = [JustSayIt.TTS]
Order = [:function]
```
