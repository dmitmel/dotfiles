#!/usr/bin/env python3

# base16-eighties by Chris Kempson (http://chriskempson.com)
base16_name = "eighties"
name = "base16-" + base16_name
base16_colors = [
    "#2d2d2d",  # 0
    "#393939",  # 1
    "#515151",  # 2
    "#747369",  # 3
    "#a09f93",  # 4
    "#d3d0c8",  # 5
    "#e8e6df",  # 6
    "#f2f0ec",  # 7
    "#f2777a",  # 8
    "#f99157",  # 9
    "#ffcc66",  # a
    "#99cc99",  # b
    "#66cccc",  # c
    "#6699cc",  # d
    "#cc99cc",  # e
    "#d27b53",  # f
]

bg = base16_colors[0x0]
fg = base16_colors[0x5]

cursor_bg = fg
cursor_fg = bg

selection_bg = base16_colors[0x2]
selection_fg = fg

ansi_colors = [
    base16_colors[int(i, 16)]
    for i in "0 8 B A D E C 5 3 8 B A D E C 7 9 F 1 2 4 6".split()
]

link_color = ansi_colors[0xC]

css_variables_prefix = "dotfiles-colorscheme-"
css_variables = {
    "bg": bg,
    "fg": fg,
    "selection-bg": selection_bg,
    "selection-fg": selection_fg,
    "cursor-bg": cursor_bg,
    "cursor-fg": cursor_fg,
    **{"base-{:02X}".format(index): color for index, color in enumerate(base16_colors)},
}
