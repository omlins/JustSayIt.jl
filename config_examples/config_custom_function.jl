# To run this do in the Julia REPL `include("path-to-file")` or simply copy paste it inside.
using JustSayIt
using JustSayIt.API       # Import JustSayIt API to write @voicearg functions
using DefaultApplication  # To install type: `]` and then `add DefaultApplication`

# 1) Define a custom weather forecast search function.
@doc """
    weather `today` | `tomorrow`

Find out how the weather is `today` or `tomorrow`.
"""
weather
@enum Day today tomorrow
@voiceargs day=>(valid_input_auto=true, use_max_accuracy=true) function weather(day::Day)
    DefaultApplication.open("https://www.google.com/search?q=weather+$day")
end

# 2) Define command name to function mapping, calling custom function
commands = Dict("help"      => Help.help,
                "weather"   => weather,
                );

# 3) Start JustSayIt with the custom commands.
start(commands=commands)  # If you say "help weather", it will show the documentation written above in the Julia REPL.
