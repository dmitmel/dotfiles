#!/usr/bin/env python

import _theme as theme

print("background", theme.bg)
print("foreground", theme.fg)
print("cursor", theme.cursor_bg)
print("cursor_text_color", theme.cursor_fg)
print("selection_background", theme.selection_bg)
print("selection_foreground", theme.selection_fg)
for index, color in enumerate(theme.ansi_colors):
    print("color" + str(index), color)
print("url_color", theme.link_color)
print("active_border_color", theme.ansi_colors[2])
print("inactive_border_color", theme.ansi_colors[8])
print("bell_border_color", theme.ansi_colors[1])
