#!/usr/bin/env python3

import _theme as theme

# default setvtrgb config:
# 0,170,0,170,0,170,0,170,85,255,85,255,85,255,85,255
# 0,0,170,85,0,0,170,170,85,85,255,255,85,85,255,255
# 0,0,0,0,170,170,170,170,85,85,85,85,255,255,255,255

for i in range(3):
    print(
        ",".join(
            [
                str(int(color[2 * i + 1 : 2 * i + 3], 16))
                for color in theme.ansi_colors[:16]
            ]
        )
    )
