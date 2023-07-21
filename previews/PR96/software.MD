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

## Submodules for command name to function mapping
#### Index
* [`JustSayIt.Help`](@ref)
* [`JustSayIt.Keyboard`](@ref)
* [`JustSayIt.Mouse`](@ref)
* [`JustSayIt.Email`](@ref)
* [`JustSayIt.Internet`](@ref)

#### Documentation
```@docs
Help
Keyboard
Mouse
Email
Internet
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
* [`JustSayIt.Keyboard.type`](@ref)

#### Documentation
```@docs
Keyboard.type
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


## Functions of [`Email`](@ref)
#### Index
* [`JustSayIt.Email.email`](@ref)

#### Documentation
```@docs
Email.email
```


## Functions of [`Internet`](@ref)
#### Index
* [`JustSayIt.Internet.internet`](@ref)

#### Documentation
```@docs
Internet.internet
```
