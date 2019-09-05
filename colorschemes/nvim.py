#!/usr/bin/env python3

import _theme as theme

print("let dotfiles_colorscheme_name = '{}'".format(theme.name))
print("let dotfiles_colorscheme_base16_name = '{}'".format(theme.base16_name))
print("let dotfiles_colorscheme_base16_colors = [")
gui_to_cterm_mapping = [0, 18, 19, 8, 20, 7, 21, 15, 1, 16, 3, 2, 6, 4, 5, 17]
for colors_pair in zip(theme.base16_colors, gui_to_cterm_mapping):
    print("\\ {{'gui': '{}', 'cterm': '{:>02}'}},".format(*colors_pair))
print("\\ ]")


def print_terminal_color(key_name, color):
    print("let terminal_color_{} = '{}'".format(key_name, color))


print_terminal_color("background", theme.bg)
print_terminal_color("foreground", theme.fg)
for index, color in enumerate(theme.ansi_colors):
    print_terminal_color(str(index), color)
