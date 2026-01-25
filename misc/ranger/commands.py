# pyright: basic

import os
import subprocess
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

    if os.environ.get("VIM_TTY", "") or os.environ.get("TMUX", ""):
      if start_x == 0 and start_y != 0:
        start_x = -1

      command = ["icat", "--unicode-placeholder"]
      os.environ["DOTFILES_ICAT_MODE"] = "ranger"

    else:
      command = ["kitten", "icat"]

    command.extend([
      "--stdin=no",
      "--transfer-mode=stream",
      "--passthrough=detect",
      f"--place={width}x{height}@{start_x}x{start_y}",
      "--align=left",
      f"--image-id={self.image_id}",
      "--no-trailing-newline",
      path,
    ])

    ansi_reset = b"\x1b[m"
    stdout.write(ansi_reset)
    stdout.flush()

    result = subprocess.run(command, check=False, stderr=subprocess.PIPE)

    stdout.write(ansi_reset)
    stdout.flush()

    # self.fm.ui.win.clearok(1)

    if result.returncode != 0 or len(result.stderr) > 0:
      raise ImageDisplayError(f"icat exited with code {result.returncode}: {result.stderr}")

  @contextmanager
  def _open_real_tty(self) -> Generator[BinaryIO, None, None]:
    ttyname = os.environ.get("VIM_TTY", "")
    if ttyname:
      with open(ttyname, "wb", opener=(lambda path, mode: os.open(path, mode | os.O_NOCTTY))) as f:
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
