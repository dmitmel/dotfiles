#!/usr/bin/env python3

import _theme as theme

for i in range(3):
    print(
        ",".join(
            [
                str(int(color[2 * i + 1 : 2 * i + 3], 16))
                for color in theme.ansi_colors[:16]
            ]
        )
    )
