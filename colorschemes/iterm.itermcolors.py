#!/usr/bin/env python3

import _theme as theme


print(
  """\
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>\
"""
)


def print_color(key_name, color):
  r, g, b = [float(int(color[2 * i + 1:2 * i + 3], 16)) / 255 for i in range(3)]
  print(
    """\
    <key>{} Color</key>
    <dict>
        <key>Color Space</key>
        <string>sRGB</string>
        <key>Red Component</key>
        <real>{}</real>
        <key>Green Component</key>
        <real>{}</real>
        <key>Blue Component</key>
        <real>{}</real>
    </dict>\
""".format(key_name, r, g, b)
  )


print_color("Background", theme.bg)
print_color("Foreground", theme.fg)
print_color("Bold", theme.fg)
print_color("Cursor", theme.cursor_bg)
print_color("Cursor Text", theme.cursor_fg)
print_color("Selection Color", theme.selection_bg)
print_color("Selected Text Color", theme.selection_fg)
for index, color in enumerate(theme.ansi_colors[:16]):
  print_color("Ansi " + str(index), color)
print_color("Link", theme.link_color)

print("""\
</dict>
</plist>\
""")
