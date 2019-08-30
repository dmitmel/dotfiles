#!/usr/bin/env python3

import _theme as theme


def print_color(key_name, color):
    print("{} {}".format(key_name, color))


print_color("background", theme.bg)
print_color("foreground", theme.fg)
print_color("cursor", theme.cursor_bg)
print_color("cursor_text_color", theme.cursor_fg)
print_color("selection_background", theme.selection_bg)
print_color("selection_foreground", theme.selection_fg)
for index, color in enumerate(theme.ansi_colors):
    print_color("color" + str(index), color)
print_color("url_color", theme.link_color)
print_color("active_border_color", theme.ansi_colors[2])
print_color("inactive_border_color", theme.ansi_colors[8])
print_color("bell_border_color", theme.ansi_colors[1])
