using JustSayIt

#1) Define mapping of command names to functions, 
#   keyboard shortcuts and command sequences.
commands = Dict(
    "help"      => Help.help,
    "type"      => Keyboard.type,
    "ma"        => Mouse.click_left,
    "middle"    => Mouse.click_middle,
    "right"     => Mouse.click_right,
    "hold"      => Mouse.press_left,
    "release"   => Mouse.release_left,
    "undo"      => (Key.ctrl, 'z'),
    "redo"      => (Key.ctrl, Key.shift, 'z'),
    "take"      => [Mouse.click_double, 
                    (Key.ctrl, 'c')],
    "replace"   => [Mouse.click_double, 
                    (Key.ctrl, 'v')]
    )

#2) Start JustSayIt, activating max speed 
#   recognition for a subset of the commands.
start(commands=commands, 
      type_languages=["en-us", "fr"], 
      max_speed_subset=["ma", "middle", "right", 
      "hold", "release", "page up", "page down", 
      "take"])
