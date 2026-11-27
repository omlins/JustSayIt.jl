# To run this do in the Julia REPL `include("path-to-file")` or simply copy paste it inside.
using JustSayIt

# 1) Define the Jupyter notebook LLM-assisted commands shown in the JuliaCon 2025 slides.
jupyter_llm_commands = Dict(
    "generate magic" => () -> LLM.type_answer(
        instruction_prefix="Generate the appropriate IPython magic command for the following task using proper syntax (%line magic or %%cell magic) with necessary options:"
    ),
    "explain cell" => () -> LLM.type_text_answer_to(
        "Explain what the selected cell code does in simple terms. Include key functions, algorithms, and data transformations. Format as markdown with clear section headings."
    ),
    "parallelize code" => () -> LLM.type_text_answer_to(
        "Convert the selected code to use parallel processing. Use appropriate IPython magic commands (%%px, %%parallel) and add necessary setup. Return only the parallelized code with essential comments."
    ),
    "visualize data" => () -> LLM.type_text_answer_to(
        "Generate visualization code for the selected data/variables. Choose appropriate plotting libraries and create informative visualizations. Use %matplotlib inline for display. Return only executable code."
    ),
)

# 2) Combine them with the top-level help command.
commands = merge(Dict("help" => Help.help), jupyter_llm_commands)

# 3) Start JustSayIt with the Jupyter notebook LLM-assisted commands.
start(commands=commands)