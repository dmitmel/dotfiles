# pyright: reportTypeCommentUsage=none

ESC = "\x1b"
CSI = ESC + "["

BLACK = 0
RED = 1
GREEN = 2
YELLOW = 3
BLUE = 4
MAGENTA = 5
CYAN = 6
WHITE = 7

BOLD = 1 << 0
DIM = 1 << 1

SGR_RESET = CSI + "0" + "m"


def sgr(*, fg: int = -1, bg: int = -1, attrs: int = 0) -> str:
  commands = []  # type: list[str]

  if attrs & BOLD:
    commands.append("1")

  if attrs & DIM:
    commands.append("2")

  if 0 <= fg < 8:
    commands.append(str(30 + fg))

  if 0 <= bg < 8:
    commands.append(str(40 + bg))

  return CSI + ";".join(commands) + "m"


def colored(text: str, *, fg: int = -1, bg: int = -1, attrs: int = 0) -> str:
  return sgr(fg=fg, bg=bg, attrs=attrs) + text + SGR_RESET


def colorize_percent(
  percent: float, *, warning: float, critical: float, inverse: bool = False
) -> str:
  colors = (GREEN, YELLOW, RED)
  index = 0 if percent < warning else 1 if percent < critical else 2
  return colored("%.2f%%" % percent, fg=colors[2 - index] if inverse else colors[index])
