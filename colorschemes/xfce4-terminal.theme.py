#!/usr/bin/env python3

import _theme as theme


print("[Scheme]")
print("Name=dmitmel's dotfiles colorscheme")
print("ColorForeground={}".format(theme.fg))
print("ColorBackground={}".format(theme.bg))
print("ColorCursorUseDefault=FALSE")
print("ColorCursorForeground={}".format(theme.cursor_fg))
print("ColorCursor={}".format(theme.cursor_bg))
print("ColorSelectionUseDefault=FALSE")
print("ColorSelection={}".format(theme.selection_fg))
print("ColorSelectionBackground={}".format(theme.selection_bg))
print("TabActivityColor={}".format(theme.ansi_colors[1]))
print("ColorBoldUseDefault=TRUE")
print("ColorPalette={}".format(";".join(theme.ansi_colors)))
