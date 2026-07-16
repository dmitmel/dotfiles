#!/usr/bin/env python3
# pyright: reportTypeCommentUsage=none

import argparse
import itertools
import os
import re
import sys

from ..terminal_utils import get_terminal_size
from . import colors
from .system_info import get_system_info


def main() -> None:
  if sys.platform == "win32":
    try:
      import colorama
    except ImportError:
      pass
    else:
      if hasattr(colorama, "just_fix_windows_console"):
        colorama.just_fix_windows_console()
      else:
        colorama.init()

  parser = argparse.ArgumentParser()
  parser.add_argument("--hide-logo", action="store_true")
  parser.add_argument("--set-logo-file")
  parser.add_argument("--extra-logos-dir", action="append", default=[])
  parser.add_argument("--list-logos", action="store_true")
  args = parser.parse_args()

  logos_search_dirs = args.extra_logos_dir + [
    os.path.join(os.path.dirname(os.path.realpath(__file__)), "logos"),
  ]  # type: list[str]

  if args.list_logos:
    for logo_dir in logos_search_dirs:
      try:
        files = os.scandir(logo_dir)
      except IOError as e:
        print(e, file=sys.stderr)
        continue

      for file in files:
        full_path = os.path.join(logo_dir, file)
        try:
          logo_lines = _read_lines(full_path)
        except IsADirectoryError:
          continue
        except IOError as e:
          print(e, file=sys.stderr)
          continue

        print()
        print(full_path)
        print()
        for line in logo_lines:
          print("  ", _render_logo_line(line), sep="")
        print()
        print()

    return

  logo_id, info_lines = get_system_info()

  logo_lines = []  # type: list[str]
  logo_line_widths = []  # type: list[int]
  logo_width = 0

  if args.set_logo_file:
    logo_lines = _read_lines(args.set_logo_file)
  elif not args.hide_logo:
    for logo_dir in logos_search_dirs:
      try:
        logo_lines = _read_lines(os.path.join(logo_dir, logo_id))
        break
      except FileNotFoundError:
        continue
      except IOError as e:
        print(e, file=sys.stderr)
        continue

  if logo_lines:
    logo_line_widths = [len(_render_logo_line(line, remove_styling=True)) for line in logo_lines]
    logo_width = max(logo_line_widths)

  space_before_logo = "  "
  space_after_logo = "   " if logo_width > 0 else "  "

  terminal_width, terminal_height = get_terminal_size(sys.stdout.fileno())
  info_width = terminal_width - logo_width - len(space_before_logo) - len(space_after_logo)

  wrapped_info_lines = _render_info_lines(info_lines, info_width)
  side_by_side_height = 1 + max(len(logo_lines), len(wrapped_info_lines)) + 1
  consecutive_height = 1 + len(logo_lines) + 1 + len(info_lines) + 1

  if len(wrapped_info_lines) <= terminal_height and side_by_side_height <= consecutive_height:
    # If the screen space allows -- print the logo and system info side by side
    print()
    for line, logo_line_width, info_line in itertools.zip_longest(
      logo_lines, logo_line_widths, wrapped_info_lines, fillvalue=None
    ):
      print(
        space_before_logo,
        _render_logo_line(line) if line else "",
        " " * (logo_width - (logo_line_width or 0)),
        space_after_logo,
        info_line or "",
        sep="",
      )
    print()

  else:
    # Otherwise, display them one after another
    print()
    for line in logo_lines:
      print(space_before_logo, _render_logo_line(line), sep="")
    print()
    for header, line in info_lines:
      print(space_before_logo, header, " ", line, sep="")
    print()


def _read_lines(file: str) -> "list[str]":
  with open(file, "r") as f:
    return f.read().splitlines()


def _render_info_lines(info_lines: "list[tuple[str, str]]", max_width: int) -> "list[str]":
  max_width = max(max_width, 1)

  # This regex will split the string into consecutive chunks of normal text and
  # ANSI SGR sequences, like this:
  #
  #     "\e[31m red \e[m normal" -> ["", "\e[31m", " red ", "\e[m", " normal"]
  #
  # because if you put a capture group into a regex used for splitting, the
  # captured text will be intermixed with the split results. This basically
  # makes it a poor man's ANSI sequence parser. Notice how normal text will
  # always be in elements with even indexes (0, 2, 4...) and the SGR sequences
  # will always be at odd ones.
  parse_sgr_sequences = re.compile(r"(\x1b\[[0-9;:]*m)").split

  def colored_text_width(chunks: "list[str]") -> int:
    return sum(map(len, chunks[::2]))  # Sum up the length of chunks of normal text

  wrapped_lines = []  # type: list[list[str]]

  def wrap_text(chunks: "list[str]", indent: str = "") -> None:
    wrapped_lines.append([indent])
    col = len(indent)
    last_sgr = ""

    for i, chunk in enumerate(chunks):
      if i % 2 == 0:  # normal text
        start = 0

        while start < len(chunk):
          if col >= max_width:  # the line has to be wrapped
            wrapped_lines[-1].append(colors.SGR_RESET)
            wrapped_lines.append([indent, last_sgr])
            col = len(indent)

          # Slice at least one character to ensure that we are making forward
          # progress in this loop
          remaining = max(max_width - col, 1)
          sliced = chunk[start : start + remaining]
          wrapped_lines[-1].append(sliced)
          start += len(sliced)
          col += len(sliced)

      else:  # SGR sequence
        wrapped_lines[-1].append(chunk)
        last_sgr = chunk

  for header, line in info_lines:
    header_chunks = parse_sgr_sequences(header)

    if not line:
      if colored_text_width(header_chunks) <= max_width:
        wrapped_lines.append(header_chunks)
      else:
        wrap_text(header_chunks)
      continue

    line_chunks = parse_sgr_sequences(line)

    if colored_text_width(header_chunks) + 1 + colored_text_width(line_chunks) <= max_width:
      wrapped_lines.append(header_chunks + [" "] + line_chunks)
    else:
      wrap_text(header_chunks)
      wrap_text(line_chunks, indent=" ")

  return ["".join(chunks) for chunks in wrapped_lines]


LOGO_LINE_TEMPLATE_RE = re.compile(r"{(\d+)}")
LOGO_COLOR_STRINGS = [colors.sgr(fg=i) for i in range(8)]
LOGO_LINE_STYLE = colors.sgr(attrs=colors.BOLD)


def _render_logo_line(line: str, remove_styling: bool = False) -> str:

  def color_replacer(match: "re.Match[str]") -> str:
    return LOGO_COLOR_STRINGS[int(match.group(1))]

  if remove_styling:
    return LOGO_LINE_TEMPLATE_RE.sub("", line)
  else:
    return LOGO_LINE_STYLE + LOGO_LINE_TEMPLATE_RE.sub(color_replacer, line) + colors.SGR_RESET
