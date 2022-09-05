# Usage

## Fully automatic installation
After installing [Julia] - if not yet installed - JustSayIt can be installed directly with the [Julia package manager] from the [Julia REPL]:
```julia-repl
julia>]
  pkg> add JustSayIt
```
All dependencies are automatically installed. Python dependencies are automatically installed in a local Miniconda environment, set up by [Conda.jl]. Default language models are automatically downloaded at first usage of JustSayIt.


## Simple basic software usage
The basic usage of JustSayIt is as simple as launching the [Julia REPL] and calling the commands `using JustSayIt` followed by `start()`:
```julia-repl
$> julia
julia> using JustSayIt
julia> start()
```
More information on customization keywords of [`start`](@ref) is given in the following subsections and in the [Software reference](@ref).


## User definable mapping of command names to functions or keyboard shortcuts
The keyword `commands` of [`start`](@ref) enables to freely define a mapping of command names to functions or keyboard shortcuts, e.g.:
```julia
# Define custom commands
using JustSayIt
commands = Dict("help"      => Help.help,
                "type"      => Keyboard.type,
                "ma"        => Mouse.click_left,
                "select"    => Mouse.press_left,
                "okay"      => Mouse.release_left,
                "middle"    => Mouse.click_middle,
                "right"     => Mouse.click_right,
                "double"    => Mouse.click_double,
                "triple"    => Mouse.click_triple,
                "copy"      => (Key.ctrl, 'c'),
                "cut"       => (Key.ctrl, 'x'),
                "paste"     => (Key.ctrl, 'v'),
                "undo"      => (Key.ctrl, 'z'),
                "redo"      => (Key.ctrl, Key.shift, 'z'),
                "upwards"   => Key.page_up,
                "downwards" => Key.page_down,
                );
start(commands=commands, max_speed_subset=["ma", "select", "okay", "middle", "right", "double", "triple", "copy", "upwards", "downwards"])
```

Note that keyboard shortcuts are given as either single keys (e.g., `Key.page_up`) or tuples of keys (e.g., `(Key.ctrl, 'c')`). Special keys are selected from those available in `Key`: type `Key.`+ `tab` in the [Julia REPL] to see the available keys (the full documentation on the available keys is available [here](https://pynput.readthedocs.io/en/latest/keyboard.html#pynput.keyboard.Key)). Character keys are simply given in single quotes (e.g., `'c'`).

The keyword `subset` of [`start`](@ref) enables to activate only a subset of the default or user-defined commands. The following example selects a subset of the default commands:
```julia
# Listen only to the commands "help" and "type".
using JustSayIt
start(subset=["help", "type"])
```


## Per command choice between maximum speed or accuracy

The keyword `max_speed_subset` of [`start`](@ref) enables to define a subset of the `commands` for which the command names are to be recognized with maximum speed rather than with maximum accuracy, e.g.:
```julia
# Define custom commands
using JustSayIt
commands = Dict("copy"      => (Key.ctrl, 'c'),
                "cut"       => (Key.ctrl, 'x'),
                "paste"     => (Key.ctrl, 'v'),
                "undo"      => (Key.ctrl, 'z'),
                "redo"      => (Key.ctrl, Key.shift, 'z'),
                "upwards"   => Key.page_up,
                "downwards" => Key.page_down,
                );
start(commands=commands, max_speed_subset=["upwards", "downwards", "copy"])
```
Forcing maximum speed is usually desired for single word commands that map to functions or keyboard shortcuts that should trigger immediate actions as, e.g., mouse clicks or, as in the above example page up/down or copy (in general, actions that do not modify content and can therefore safely be triggered at maximum speed). However, it is typically not desired for "dangerous" actions, like "cut", "paste", "undo" and "redo" in this example. Note that forcing maximum speed means not to wait for a certain amount of silence after the end of a command as normally done for the full confirmation of a recognition. As a result, it enables a minimal latency between the saying of a command name and its execution. Note that it is usually possible to define very distinctive command names, which allow for a safe command name to shortcut mapping at maximum speed (to be tested case by case).

Note furthermore that a good recording quality is important in order to achieve a good recognition accuracy. In particular, background noise might reduce recognition accuracy. Thus, a microphone integrated in a notebook or a webcam might potentially lead to unsatisfying accuracy, while a headset or an external microphone that is well set up should lead to good accuracy. JustSayIt relying on the [Vosk Speech Recognition Toolkit], it is the latter that dictates the requirements on recording quality for good recognition accuracy (for more information, have a look at the subsection [accuracy](https://alphacephei.com/vosk/accuracy) on their website).


## Help on commands callable by voice
Saying "help commands" lists your available commands in the [Julia REPL] leading to, e.g., the following output:
```julia-repl
┌ Info:
│ Your commands:
│ copy      => ctrl + c
│ cut       => ctrl + x
│ double    => click_double
│ downwards => page_down
│ email     => email
│ help      => help
│ internet  => internet
│ ma        => click_left
│ middle    => click_middle
│ okay      => release_left
│ paste     => ctrl + v
│ redo      => ctrl + shift + z
│ right     => click_right
│ select    => press_left
│ triple    => click_triple
│ type      => type
│ undo      => ctrl + z
└ upwards   => page_up
```
Saying "help <command name>", where `<command name>` is to be replaced with one of the available commands, shows the help for the corresponding command. Here is, e.g., the output produced when saying "help email":
```julia-repl
[ Info: Starting command: help (latency: 6 ms)
┌ Info: Command email
│    =
│      email `inbox` | `outbox`
│    
│      Manage e-mails, performing one of the following actions:
│    
│        •  open inbox
│    
└        •  open outbox
```
Note that the submodules [`Email`](@ref) and [`Internet`](@ref) contain still very little functionality. Yet, they illustrate how submodules for all kind of operations can be programmed.


## Sleep and wake up by voice
Saying "sleep JustSayIt" puts JustSayIt to sleep. It will not execute any commands until it is awoken with the words "awake JustSayIt".


## Fast command programming with voice argument functions
JustSayIt commands map to regular Julia functions. Function arguments can be easily passed by voice thanks to the [`@voiceargs`](@ref) macro. It allows to declare arguments in standard function definitions to be directly obtainable by voice. It, furthermore, allows to define speech recognition parameters for each voice argument as, e.g., the valid speech input. The following shows some examples:

```julia
  @voiceargs (b, c) function f(a, b::String, c::String, d)
      #(...)
      return
  end
```
```julia
    @voiceargs (b=>(use_max_speed=true), c) function f(a, b::String, c::String, d)
        #(...)
        return
    end
```
```julia
    @enum TypeMode words formula
    @voiceargs (mode=>(valid_input_auto=true), token=>(model=MODELNAME.TYPE.EN_US, vararg_timeout=2.0)) function type_tokens(mode::TypeMode, tokens::String...)
        #(...)
        return
    end
```
Detailed information on [`@voiceargs`](@ref) is found in the [High-level API reference](@ref).

While contributions to the JustSayIt command modules are very much encouraged, it is possible to quickly define and use custom [`@voiceargs`](@ref) functions thanks to the API of JustSayIt ([`JustSayIt.API`](@ref)). It is illustrated in [this example](@ref Quick-definition-and-usage-of-custom-function). More information on the JustSayIt API is given in the [High-level API reference](@ref).

Note that the JustSayIt application config folder (e.g., `~/.config/JustSayIt` on Unix systems) is an easily accessible storage for scripts to start JustSayIt and/or for custom command functions: [`@include_config`](@ref) permits to conveniently `include` files from this folder.
