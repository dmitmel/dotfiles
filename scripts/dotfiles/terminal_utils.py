import os


# Opens a TTY device without making it the controlling terminal of this process.
# Not sure if this is really necessary, though.
def open_noctty(path: str, mode: int) -> int:
  return os.open(path, (mode | os.O_NOCTTY) if hasattr(os, "O_NOCTTY") else mode)


def ctermid() -> str:
  if hasattr(os, "ctermid"):
    return os.ctermid()
  else:
    # Some platforms don't have the ctermid(3) function, most notably, Windows and Android
    return "CONOUT$" if os.name == "nt" else "/dev/tty"


# The logic in Python's built-in `shutil.get_terminal_size()` function[1] is
# insufficient, as it only queries the dimensions of the TTY connected to the
# stdout, and doesn't try `/dev/tty` (see ctermid(3)) if that fails, which
# breaks if stdout is piped into another program or is captured with `$(...)` in
# the shell. Also, importing `shutil` imports a lot of other useless stuff
# (namely, compression algorithms), which increases startup time of small
# scripts that must be super fast (such as my `icat`).
# [1]: <https://github.com/python/cpython/blob/v3.13.9/Lib/shutil.py#L1439-L1482>
def get_terminal_size(fd: int) -> "tuple[int, int]":
  final_cols, final_rows = 0, 0
  attempt = 0
  while True:
    attempt += 1

    if attempt == 1:
      try:
        cols = int(os.environ["COLUMNS"])
      except (KeyError, ValueError):
        cols = 0

      try:
        rows = int(os.environ["LINES"])
      except (KeyError, ValueError):
        rows = 0

    elif attempt == 2:
      try:
        cols, rows = os.get_terminal_size(fd)
      except OSError:
        continue

    elif attempt == 3:
      try:
        with open(ctermid(), "wb", opener=open_noctty) as cterm_fd:
          cols, rows = os.get_terminal_size(cterm_fd.fileno())
      except OSError:
        continue

    else:
      break

    if final_cols <= 0:
      final_cols = cols
    if final_rows <= 0:
      final_rows = rows

    if final_cols > 0 and final_rows > 0:
      return final_cols, final_rows

  return 0, 0
