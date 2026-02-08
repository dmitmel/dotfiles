# pyright: basic

import os
import subprocess
import sys
from contextlib import contextmanager
from typing import TYPE_CHECKING, BinaryIO, Generator, cast

from ranger.ext.img_display import (
  ImageDisplayError,
  KittyImageDisplayer,
  register_image_displayer,
)

if TYPE_CHECKING:
  from typing_extensions import override
else:
  override = lambda x: x

sys.path.insert(0, os.path.join(os.path.dirname(os.path.realpath(__file__)), "../../scripts/"))
import dotfiles.icat


# Replacement for <https://github.com/ranger/ranger/blob/f28690ef42778eb7982e2b309a2cc8d99f682eb4/ranger/ext/img_display.py#L684>
@register_image_displayer("kitty")
class PatchedKittyImageDisplayer(KittyImageDisplayer):
  def __init__(self) -> None:
    super().__init__()
    self.image_id = os.getpid()

    if os.environ.get("TMUX", ""):
      self.protocol_start = b"\x1bPtmux;" + self.protocol_start.replace(b"\x1b", b"\x1b\x1b")
      self.protocol_end = self.protocol_end.replace(b"\x1b", b"\x1b\x1b") + b"\x1b\\"

  @override
  def draw(self, path: str, start_x: int, start_y: int, width: int, height: int) -> None:
    stdout = cast(BinaryIO, self.stdbout)
    stdout.flush()

    self._delete_image(self.image_id)

    icat_wrapper_needed = bool(os.environ.get("VIM_TTY", "") or os.environ.get("TMUX", ""))

    if icat_wrapper_needed and start_x == 0 and start_y != 0:
      start_x = -1

    args = [
      "--stdin=no",
      "--transfer-mode=stream",
      "--passthrough=detect",
      f"--place={width}x{height}@{start_x}x{start_y}",
      "--align=left",
      f"--image-id={self.image_id}",
      "--no-trailing-newline",
    ]

    if icat_wrapper_needed:
      args.append("--unicode-placeholder")

    args.append("--")
    args.append(path)

    stdout.write(dotfiles.icat.SGR_RESET)
    stdout.flush()

    try:
      if icat_wrapper_needed:
        exit_code = dotfiles.icat.run(args, stdout, mode="ranger")
        stdout.flush()
        if exit_code != 0:
          raise ImageDisplayError(f"icat exited with code {exit_code}")

      else:
        result = subprocess.run(["kitten", "icat"] + args, check=False, stderr=subprocess.PIPE)
        if result.returncode != 0 or len(result.stderr) > 0:
          raise ImageDisplayError(f"icat exited with code {result.returncode}: {result.stderr}")

    finally:
      stdout.write(dotfiles.icat.SGR_RESET)
      stdout.flush()

      # self.fm.ui.win.clearok(1)

  @contextmanager
  def _open_real_tty(self) -> Generator[BinaryIO, None, None]:
    ttyname = os.environ.get("VIM_TTY", "")
    if ttyname:
      with open(ttyname, "wb", opener=dotfiles.icat.open_noctty) as f:
        yield f
    else:
      yield cast(BinaryIO, self.stdbout)

  def _delete_image(self, id: int) -> None:
    with self._open_real_tty() as tty:
      for cmd_str in self._format_cmd_str({"a": "d", "d": "I", "i": id}):
        tty.write(cmd_str)
      tty.flush()

  @override
  def clear(self, start_x: int, start_y: int, width: int, height: int) -> None:
    self._delete_image(self.image_id)
    self.fm.ui.win.redrawwin()
    self.fm.ui.win.refresh()

  @override
  def quit(self) -> None:
    self.clear(0, 0, 0, 0)
