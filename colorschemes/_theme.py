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
    base16_colors[i]
    for i in [
        0x0,
        0x8,
        0xB,
        0xA,
        0xD,
        0xE,
        0xC,
        0x5,
        0x3,
        0x8,
        0xB,
        0xA,
        0xD,
        0xE,
        0xC,
        0x7,
    ]
]

link_color = ansi_colors[12]
