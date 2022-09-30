using JustSayIt
using JustSayIt.API
using DefaultApplication
@enum Day today tomorrow

#1) Define a custom weather forecast search function
@voiceargs day=>(valid_input_auto=true) function
weather(day::Day)
    DefaultApplication.open(
     "https://www.google.com/search?q=weather+$day")
end

#2) Define command name to function mapping, calling the custom function.
commands = Dict("help"    => Help.help,
                "weather" => weather)

# 3) Start JustSayIt with the custom commands.
start(commands=commands)
