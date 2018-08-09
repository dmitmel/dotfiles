import re

from colors import Style, COLORS
from system_info import get_system_info

print("")

logo_lines, info_lines = get_system_info()
logo_line_widths = [len(re.sub(r"{\d}", "", line)) for line in logo_lines]
logo_width = max(logo_line_widths)

for line_index in range(0, max(len(logo_lines), len(info_lines))):
    line = ""

    logo_line_width = 0

    if line_index < len(logo_lines):
        logo_line = logo_lines[line_index]
        logo_line_width = logo_line_widths[line_index]

        line += Style.BRIGHT
        line += logo_line.format(*COLORS)
        line += Style.RESET_ALL

    line += " " * (logo_width - logo_line_width + 3)

    if line_index < len(info_lines):
        info_line = info_lines[line_index]
        line += info_line

    print(line)

print("")
