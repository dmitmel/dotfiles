#!/usr/bin/env python3

import _theme as theme


def print_color(key_name, color):
    print("{}={}".format(key_name, color))


print_color("background", theme.bg)
print_color("foreground", theme.fg)
print_color("cursor", theme.cursor_bg)
for index, color in enumerate(theme.ansi_colors[:16]):
    print_color("color" + str(index), color)
