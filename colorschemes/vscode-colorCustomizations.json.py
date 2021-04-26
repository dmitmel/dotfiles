#!/usr/bin/env python3

import _theme as theme
import json


ANSI_COLOR_NAMES = [
    "Black",
    "Red",
    "Green",
    "Yellow",
    "Blue",
    "Magenta",
    "Cyan",
    "White",
]

colors = {
    "terminal.background": theme.bg,
    "terminal.foreground": theme.fg,
    "terminal.selectionBackground": theme.selection_bg,
    "terminalCursor.background": theme.cursor_fg,
    "terminalCursor.foreground": theme.cursor_bg,
}

for color_brightness in [False, True]:
    for color_index, color_name in enumerate(ANSI_COLOR_NAMES):
        color = theme.ansi_colors[color_index + int(color_brightness) * len(ANSI_COLOR_NAMES)]
        colors["terminal.ansi" + ("Bright" if color_brightness else "") + color_name] = color

print(json.dumps(colors, ensure_ascii=False, indent=2))
