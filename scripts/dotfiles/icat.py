# This script is a giant bodge that exists solely to make image previews in the
# LF file manager work when LF is running inside (neo)vim. It wraps the `icat`
# utility provided by the Kitty terminal, which is used to print images directly
# into the terminal by means of the Kitty Graphics Protocol[1], which is
# basically a set of some new escape sequences for sending static or animated
# images to the terminal. This protocol obviously requires the terminal and any
# programs that sit in between the terminal and the end application to support
# it, or at least to pass these escape sequences through[2], which Neovim,
# unfortunately, does not.
#
# [1]: <https://sw.kovidgoyal.net/kitty/graphics-protocol/>
# [2]: <https://github.com/junegunn/fzf/commit/d8188fce7b7bea982e7f9050c35e488e49fb8fd0>
#
# To work around this, my script calls `icat`, reads its output and then splits
# it in two streams: the Kitty Graphics Protocol[1] commands are parsed and sent
# directly to the TTY that Vim is running in, which belongs to Kitty itself, and
# the rest (text or other escape sequences) goes into stdout, which will be
# displayed in the terminal window inside Vim. It also does the job of guessing
# the on-screen size of this inner terminal window in pixels, as that is needed
# for appropriately scaling the image (Neovim doesn't report it correctly[3][4],
# due to considerations of running Nvim in `--headless` mode and connecting from
# a different TTY with `--remote-ui`[5], although this may be implemented in the
# future[6]. Though, plain old Vim does report the window size correctly).
#
# [3]: <https://github.com/neovim/neovim/issues/8259>
# [4]: <https://github.com/neovim/neovim/pull/28621>
# [5]: <https://github.com/neovim/neovim/pull/28621#issuecomment-2097518428>
# [6]: <https://github.com/neovim/neovim/issues/32189#issuecomment-2651403020>
#
# It also relies on a feature that is currently implemented only by Kitty (as
# opposed to other terminals supporting the Kitty Graphics Protocol, such as
# WezTerm or Ghostty) - namely, the possibility of using Unicode characters from
# the Private Use Area[7] for positioning the image on the screen[8]. Basically,
# the idea is that we can upload the pixel data of the image to Kitty, and then
# fill the cells where we want the image to be displayed with the character
# U+10EEEE mixed with some diacritical marks which encode the positions of each
# cell in the image. The ID of the image is encoded through the foreground color
# of these placeholder characters. This in itself is a brilliant hack on the
# part of Kitty to make image rendering work in apps like terminal multiplexers,
# which only need to support Unicode, since U+10EEEE is a Unicode character,
# just like any other. Since the placement of the image follows these
# placeholder characters, it will be scrolled, cropped, or even reflown with the
# other text in the terminal multiplexer.
#
# [7]: <https://en.wikipedia.org/wiki/Private_Use_Areas>
# [8]: <https://sw.kovidgoyal.net/kitty/graphics-protocol/#unicode-placeholders>
#
# So basically, to get the best output from this script, you should call it with
# `--transfer=stream --unicode-placeholders=yes --passthrough=detect`, wherein
# it will send the pixel data to Kitty (even over an SSH connection to a remote
# machine and/or inside tmux) and print a rectangle of Unicode placeholders into
# a terminal window in Neovim, which Kitty will render the image onto.
#
# As for the choice of the language: it *had* to be written in Python, mainly
# because I needed a language that exposes the ioctl(2) function. Other choices
# include LuaJIT, C, Go and Perl (I have tried rewriting this script in Perl
# already - its startup time is way worse then Python's, and it doesn't offer a
# cross-platform way of obtaining the `TIOCGWINSZ` constant). The startup time
# can be profiled by running this script with `python -X importtime =icat`.

import ctypes
import os
import re
import subprocess
import sys
from contextlib import ExitStack
from fcntl import ioctl
from termios import TIOCGWINSZ
from typing import BinaryIO, List, Optional, Tuple

# <https://github.com/alacritty/alacritty/wiki/ANSI-References>
# <https://vt100.net/emu/dec_ansi_parser>
# <https://invisible-island.net/xterm/ctlseqs/ctlseqs.html>
# <https://ghostty.org/docs/vt/concepts/sequences>
# <https://en.wikipedia.org/wiki/ANSI_escape_code>
# <https://wezterm.org/escape-sequences.html#graphic-rendition-sgr>
ESC = b"\x1b"
APC = ESC + b"_"  # Application Program Command
DCS = ESC + b"P"  # Device Control String
CSI = ESC + b"["  # Control Sequence Introducer
ST = ESC + b"\\"  # String Terminator
SGR = b"m"  # Select Graphic Rendition
SGR_RESET = CSI + b"0" + SGR
DECSC = ESC + b"7"  # save cursor
DECRC = ESC + b"8"  # restore cursor

# <https://stackoverflow.com/questions/14693701/how-can-i-remove-the-ansi-escape-sequences-from-a-string-in-python>
CSI_REGEX = re.compile(rb"^\x1b\[[\x30-\x3f]*[\x20-\x2f]*[\x40-\x7e]")


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


# Opens a TTY device without making it the controlling terminal of this process.
# Not sure if this is really necessary, though.
def open_noctty(path: str, mode: int) -> int:
  return os.open(path, mode | os.O_NOCTTY)


def run(argv: List[str], stdout: BinaryIO, mode: Optional[str] = None) -> int:
  cols, rows = get_terminal_size(stdout.fileno())

  # Vim is supposed to provide this variable, see `../nvim/init.vim`
  vim_tty = os.environ.get("VIM_TTY", "") or os.ctermid()
  with open(vim_tty, "wb", opener=open_noctty) as vim_tty:
    vim = winsize()
    ioctl(vim_tty, TIOCGWINSZ, vim)
    xpixels = vim.ws_xpixel * cols // vim.ws_col
    ypixels = vim.ws_ypixel * rows // vim.ws_row

    cmd = ["kitten", "icat", f"--use-window-size={cols},{rows},{xpixels},{ypixels}"]
    if mode == "lf-preview":
      # This is needed to fit the image into a ${cols} by ${rows} rectangle
      # because fitting is only activated when the `--place` flag is given:
      # <https://github.com/kovidgoyal/kitty/blob/v0.44.0/kittens/icat/native.go#L99-L102>
      cmd.append(f"--place={cols}x{rows}@0x0")
    cmd.extend(argv[1:])

    try:
      proc = subprocess.run(cmd, check=True, stdout=subprocess.PIPE)
    except subprocess.CalledProcessError as e:
      if e.returncode < 0:  # Exited due to a signal
        print(e)
        # This is just a convention used by most shells, such an exit code is
        # not special and doesn't actually give any information to the operating
        # system. More info here: <https://www.cons.org/cracauer/sigint.html>.
        return 0x80 + -e.returncode
      else:
        return e.returncode
    except OSError as e:
      print(e)
      return 0x7F

    output = proc.stdout

    # The mother of all hacks: the loop that parses the ANSI escape sequences
    # outputted by `kitten icat`. It only needs to be able to process these:
    # <https://github.com/kovidgoyal/kitty/blob/v0.44.0/kittens/icat/transmit.go#L250-L279>.
    i = 0
    last_sgr = b""
    while i < len(output):
      if output.startswith(CSI, i):
        match = CSI_REGEX.match(output[i:])
        if match:
          csi = match.group(0)

          # The preview window in LF supports only a very limited number of ANSI
          # sequences: <https://github.com/gokcehan/lf/blob/r39/termseq.go#L40-L84>
          # <https://github.com/gokcehan/lf/blob/r39/termseq_test.go>
          if mode == "lf-preview" and not csi.endswith(SGR):
            i += match.end()
            continue

          if csi.endswith(SGR):
            # Also, LF does not support colon separators in SGR sequences, see
            # <https://github.com/gokcehan/lf/blob/r39/termseq.go#L125>.
            if csi.startswith(CSI + b"38:"):
              csi = csi.replace(b":", b";")
            last_sgr = csi

          stdout.write(csi)
          stdout.flush()
          i += match.end()
          continue

      # These sequences are inserted because of the `--place` flag that we had
      # to provide for previews in LF, they must be stripped from the output.
      if mode == "lf-preview" and output.startswith((DECSC, DECRC), i):
        i += 2
        continue

      # The image data will be sent either as `ESC "_G" ... ST` or `ESC "Ptmux;"
      # ESC ESC "_G" ... ESC ST ST`.
      # <https://github.com/kovidgoyal/kitty/blob/v0.44.0/kittens/icat/transmit.go#L39-L43>
      # <https://github.com/kovidgoyal/kitty/blob/v0.44.0/tools/tui/graphics/command.go#L210-L251>
      # When wrapped in sequences for passthrough in tmux, a doubled ESC
      # character counts as a plain ESC, and an unescaped ESC followed by
      # backslash terminates the sequence.
      # <https://github.com/tmux/tmux/wiki/FAQ#what-is-the-passthrough-escape-sequence-and-how-do-i-use-it>
      # <https://github.com/tmux/tmux/blob/3.6/input.c#L689-L698>
      if output.startswith((APC, DCS), i):
        end = i + 2
        while end < len(output):
          esc = output.find(ESC, end)
          end = esc + 2
          if output[esc:end] == ST:
            break
        vim_tty.write(output[i:end])
        vim_tty.flush()
        i = end
        continue

      # Jump to the next escape sequence
      esc = output.find(ESC, i + 1)
      if esc < 0:
        esc = len(output)
      chunk = output[i:esc]
      if mode == "less":
        # For efficiency sake, less assumes that every line starts out
        # non-colored, but `icat` prints the SGR sequence to set the foreground
        # color only once - therefore it needs to be repeated on every line.
        chunk = chunk.replace(b"\r", b"").replace(b"\n", b"\n" + last_sgr)
      stdout.write(chunk)
      stdout.flush()
      i = esc

    return 0


# The logic in Python's built-in `shutil.get_terminal_size()` function is
# insufficient, as it only queries the TTY size of the TTY connected to the
# stdout, and doesn't try `/dev/tty` (see ctermid(3)) if that fails, so this
# whole script breaks if its output is piped into `| cat -A`, for instance,
# which makes debugging more painful than it has to be. Also, importing `shutil`
# imports a lot of other useless stuff (namely, compression algorithms).
# <https://github.com/python/cpython/blob/v3.13.9/Lib/shutil.py#L1439-L1482>
def get_terminal_size(stream: int) -> Tuple[int, int]:
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


def main() -> None:
  sys.exit(run(sys.argv, sys.stdout.buffer, os.environ.get("DOTFILES_ICAT_MODE")))


if __name__ == "__main__":
  main()
