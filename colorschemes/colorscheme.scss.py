#!/usr/bin/env python3

# TODO: Prefix the name with an underscore when I rewrite the theme generator,
# see <https://sass-lang.com/documentation/at-rules/use#partials>.

import _theme as theme


print('$is-dark: {};'.format("true" if theme.is_dark else "false"))
for var_name, color in theme.css_variables.items():
  print("${}: {};".format(var_name, color))
print("$base: ({});".format(', '.join(theme.base16_colors)))
print("$ansi: ({});".format(', '.join(theme.ansi_colors)))
