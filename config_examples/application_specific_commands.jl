# To run this do in the Julia REPL `include("path-to-file")` or simply copy paste it inside.
using JustSayIt

# 1) Define reusable commands shared by several application contexts.
base_commands = Dict(
    "sentence"     => Keyboard.type_sentence,
    "continuation" => Keyboard.type_sentence_lowercase,
    "spell"        => Keyboard.type_letters,
    "type summary" => LLM.type_summary,
    "answer"       => LLM.read_text_answer,
    "followup"     => LLM.read_followup,
    "read this"    => TTS.read,
    "pause"        => TTS.pause,
    "stop"         => TTS.stop,
)

# 2) Extend the base dictionary with browser-specific commands.
browser_commands = merge(
    base_commands,
    Dict(
        "new tab"      => (Key.ctrl, 't'),
        "close tab"    => (Key.ctrl, 'w'),
        "jump address" => (Key.ctrl, 'l'),
        "search web"   => [(Key.ctrl, 'l'), Keyboard.type_lowercase, Key.enter],
    ),
)

# 3) Extend the base dictionary with coding-specific commands.
coding_commands = merge(
    base_commands,
    Dict(
        "comment"          => (Key.ctrl, '/'),
        "format selection" => [(Key.ctrl, 'k'), (Key.ctrl, 'f')],
        "workspace search" => (Key.ctrl, Key.shift, 'f'),
        "jump line"        => [(Key.ctrl, 'g'), Keyboard.type_digits, Key.enter],
    ),
)

# 4) Assemble top-level commands that activate nested application contexts.
commands = Dict(
    "help"    => Help.help,
    "browser" => [`firefox`, browser_commands],
    "coding"  => [`code`, coding_commands],
)

# 5) Start JustSayIt with the application-specific command dictionaries.
start(commands=commands)