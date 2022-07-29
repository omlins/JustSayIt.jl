# Quick definition and usage of custom function

This example shows how one can
1. program a weather forecast search function (`weather`),
2. define a command name to function mapping, and then
3. start JustSayIt using these customly defined commands.

The command `weather` programmed here allows to find out how the weather is `today` or `tomorrow` - just say "weather today" or "weather tomorrow". Furthermore, if you say "help weather", it will show in the [Julia REPL] the function documentation written here. To run this example, type in the [Julia REPL] `include("path-to-file")` or simply copy-paste the code below inside (the corresponding file can be found [here](../../../assets/config_examples/config_custom_function.jl)).

```@eval
Main.mdinclude(joinpath(Main.EXAMPLEROOT, "config_custom_function.jl"))
```
