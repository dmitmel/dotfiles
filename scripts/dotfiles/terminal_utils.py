import ctypes
import os
from fcntl import ioctl
from termios import TIOCGWINSZ, TIOCSWINSZ


class winsize(ctypes.Structure):  # noqa: N801
  _fields_ = (
    ("ws_row", ctypes.c_ushort),
    ("ws_col", ctypes.c_ushort),
    ("ws_xpixel", ctypes.c_ushort),
    ("ws_ypixel", ctypes.c_ushort),
  )
  ws_row: int
  ws_col: int
  ws_xpixel: int
  ws_ypixel: int


def tiocgwinsz(fd: int) -> winsize:
  size = winsize()
  ioctl(fd, TIOCGWINSZ, size)
  return size


def tiocswinsz(fd: int, size: winsize) -> None:
  ioctl(fd, TIOCSWINSZ, size)


# Opens a TTY device without making it the controlling terminal of this process.
# Not sure if this is really necessary, though.
def open_noctty(path: str, mode: int) -> int:
  return os.open(path, mode | os.O_NOCTTY)


# The logic in Python's built-in `shutil.get_terminal_size()` function[1] is
# insufficient, as it only queries the dimensions of the TTY connected to the
# stdout, and doesn't try `/dev/tty` (see ctermid(3)) if that fails, which
# breaks if stdout is piped into another program or is captured with `$(...)` in
# the shell. Also, importing `shutil` imports a lot of other useless stuff
# (namely, compression algorithms), which increases startup time of small
# scripts that must be super fast (such as my `icat`).
# [1]: <https://github.com/python/cpython/blob/v3.13.9/Lib/shutil.py#L1439-L1482>
def get_terminal_size(stream: int) -> "tuple[int, int]":
  final_cols, final_rows = 0, 0
  for attempt in range(3):
    size = winsize(0, 0, 0, 0)

    if attempt == 0:
      try:
        size.ws_col = int(os.environ["COLUMNS"])
      except (KeyError, ValueError):
        size.ws_col = 0

      try:
        size.ws_row = int(os.environ["LINES"])
      except (KeyError, ValueError):
        size.ws_row = 0

    elif attempt == 1:
      try:
        ioctl(stream, TIOCGWINSZ, size)
      except OSError:
        continue

    elif attempt == 2:
      try:
        with open(os.ctermid(), "rb", opener=open_noctty) as cterm_fd:
          ioctl(cterm_fd, TIOCGWINSZ, size)
      except OSError:
        continue

    if final_cols <= 0:
      final_cols = size.ws_col
    if final_rows <= 0:
      final_rows = size.ws_row

    if final_cols > 0 and final_rows > 0:
      return final_cols, final_rows

  return 0, 0
