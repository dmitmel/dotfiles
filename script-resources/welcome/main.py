#!/usr/bin/env python3

import argparse
import os
import re
import sys
from typing import IO, List, Optional

from colors import COLORS, Style
from system_info import get_system_info


def main() -> None:
  parser = argparse.ArgumentParser()
  parser.add_argument("--hide-logo", action="store_true")
  parser.add_argument("--set-logo-file")
  parser.add_argument("--extra-logos-dir", action="append", default=[])
  parser.add_argument("--list-logos", action="store_true")
  args = parser.parse_args()

  logos_search_dirs: List[str] = []
  logos_search_dirs.extend(args.extra_logos_dir)
  logos_search_dirs.append(os.path.join(os.path.dirname(os.path.realpath(__file__)), "logos"))

  if args.list_logos:
    for logo_dir in logos_search_dirs:
      try:
        for file in os.scandir(logo_dir):
          try:
            logo_file = open(os.path.join(logo_dir, file))
          except IsADirectoryError:
            continue
          with logo_file:
            print()
            print(logo_file.name)
            print()
            for line in logo_file.read().splitlines():
              print(render_logo_line(line))
            print()
            print()
      except IOError as e:
        print(e, file=sys.stderr)
        continue
    return

  logo_id, info_lines = get_system_info()

  logo_lines: List[str] = []
  logo_line_widths: List[int] = []
  logo_width = 0

  logo_file: Optional[IO[str]] = None
  if args.set_logo_file:
    logo_file = open(args.set_logo_file)
  elif not args.hide_logo:
    for logo_dir in logos_search_dirs:
      try:
        logo_file = open(os.path.join(logo_dir, logo_id))
      except FileNotFoundError:
        continue
      except IOError as e:
        print(e, file=sys.stderr)
        continue

  if logo_file is not None:
    with logo_file:
      logo_lines = logo_file.read().splitlines()
    if len(logo_lines) > 0:
      logo_line_widths = [len(render_logo_line(line, remove_styling=True)) for line in logo_lines]
      logo_width = max(logo_line_widths)

  print()

  for line_index in range(0, max(len(logo_lines), len(info_lines))):
    output_line: List[str] = []

    output_line.append("  ")
    if logo_width > 0:
      logo_line_width = 0

      if line_index < len(logo_lines):
        logo_line = logo_lines[line_index]
        logo_line_width = logo_line_widths[line_index]
        output_line.append(render_logo_line(logo_line))

      output_line.append(" " * (logo_width - logo_line_width + 1))
    output_line.append("  ")

    if line_index < len(info_lines):
      info_line = info_lines[line_index]
      output_line.append(info_line)

    print("".join(output_line))

  print()


LOGO_LINE_TEMPLATE_RE = re.compile(r"{(\d+)}")


def render_logo_line(line: str, remove_styling: bool = False) -> str:

  def logo_line_replacer(match: "re.Match[str]") -> str:
    return COLORS[int(match.group(1))]

  if remove_styling:
    return LOGO_LINE_TEMPLATE_RE.sub("", line)
  else:
    return Style.BRIGHT + LOGO_LINE_TEMPLATE_RE.sub(logo_line_replacer, line) + Style.RESET_ALL


if __name__ == "__main__":
  main()
