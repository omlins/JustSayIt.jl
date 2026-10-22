# Jupyter notebook LLM-assisted commands

This example keeps the Jupyter notebook LLM-assisted commands from the JuliaCon 2025 slides and adds only the minimal boilerplate needed to run them as a JustSayIt configuration file. It is the focused example for application-specific LLM interaction built from predefined generic LLM helpers.

To run this example, type in the [Julia REPL] `include("path-to-file")` or simply copy-paste the code below inside (the corresponding file can be found [here](../assets/config_examples/jupyter_llm_commands.jl)).

```@eval
Main.mdinclude(joinpath(Main.EXAMPLEROOT, "jupyter_llm_commands.jl"))
```