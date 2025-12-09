from typing import List

from colorama import Fore, Style, ansi

COLORS: List[str] = [ansi.code_to_chars(30 + color_index) for color_index in range(0, 8)]


def colored(string: str, *colors: str) -> str:
  return "".join(colors + (string, Style.RESET_ALL))


def bright_colored(string: str, *colors: str) -> str:
  return "".join(colors + (Style.BRIGHT, string, Style.RESET_ALL))


def colorize_percent(
  percent: float, warning: float, critical: float, inverse: bool = False,
) -> str:
  colors = [Fore.GREEN, Fore.YELLOW, Fore.RED]

  color_index = 0 if percent < warning else 1 if percent < critical else 2
  if inverse:
    color_index = 2 - color_index

  return colored("%.2f%%" % percent, colors[color_index])
