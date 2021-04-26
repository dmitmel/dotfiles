#!/usr/bin/env python3

import _theme as theme
import os

with open(os.path.join(os.path.dirname(__file__), "prismjs-theme-src.css")) as f:
  css_src = f.read()

for var_name, color in theme.css_variables.items():
  css_src = css_src.replace("var(--{}{})".format(theme.css_variables_prefix, var_name), color)

print(css_src)
