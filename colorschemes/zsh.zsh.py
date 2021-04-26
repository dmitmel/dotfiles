#!/usr/bin/env python3

import _theme as theme

for attr in [
    "bg",
    "fg",
    "cursor_bg",
    "cursor_fg",
    "selection_bg",
    "selection_fg",
    "link_color",
]:
    color = getattr(theme, attr)
    print("colorscheme_{}={}".format(attr, color[1:]))
print("colorscheme_ansi_colors=(")
for color in theme.ansi_colors:
    print("  {}".format(color[1:]))
print(")")
