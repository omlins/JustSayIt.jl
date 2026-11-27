# Application-specific command dictionaries

This example shows one larger executable configuration file that combines reusable base commands with browser and coding contexts. It keeps the code in one contiguous example, as it would actually be run, while the current [JustSayItRecipes.jl](https://github.com/omlins/JustSayItRecipes.jl) recipes remain the authoritative larger recipe collection. The top-level command dictionary includes `help` explicitly so spoken help stays available while switching application contexts.

To run this example, type in the [Julia REPL] `include("path-to-file")` or simply copy-paste the code below inside (the corresponding file can be found [here](../assets/config_examples/application_specific_commands.jl)).

```@eval
Main.mdinclude(joinpath(Main.EXAMPLEROOT, "application_specific_commands.jl"))
```