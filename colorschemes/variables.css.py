#!/usr/bin/env python3

import _theme as theme


print(":root {")
for var_name, color in theme.css_variables.items():
  print("  --{}{}: {};".format(theme.css_variables_prefix, var_name, color))
print("}")
