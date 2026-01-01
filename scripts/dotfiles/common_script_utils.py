import os
import signal
import subprocess
import sys
from contextlib import contextmanager
from pathlib import Path
from typing import Generator, Iterable, Optional, Set

if os.name == "posix":
  DOTFILES_CONFIG_DIR: Path = Path.home() / ".config" / "dotfiles"
  DOTFILES_CACHE_DIR: Path = Path.home() / ".cache" / "dotfiles"


def platform_not_supported_error() -> Exception:
  return Exception("platform '{}' is not supported!".format(sys.platform))


def run_chooser(
  choices: Iterable[str], prompt: Optional[str] = None, async_read: bool = False
) -> int:
  supports_result_index = True
  if os.isatty(sys.stderr.fileno()):
    process_args = [
      "fzf",
      "--with-nth=2..",
      "--height=40%",
      "--reverse",
      "--tiebreak=index",
    ]
    supports_result_index = False
  elif sys.platform == "darwin":
    process_args = ["choose", "-i"]
  elif os.name == "posix":
    process_args = ["rofi", "-dmenu", "-i", "-format", "i"]
    if prompt is not None:
      process_args += ["-p", prompt]
    if async_read:
      process_args += ["-async-pre-read", "0"]
  else:
    raise platform_not_supported_error()

  with subprocess.Popen(
    process_args,
    stdin=subprocess.PIPE,
    stdout=subprocess.PIPE,
    text=True,
    bufsize=1,  # line-buffered mode
  ) as chooser:
    assert chooser.stdin is not None
    assert chooser.stdout is not None

    pipe = chooser.stdin
    for index, choice in enumerate(choices):
      if "\n" in choice:
        raise Exception("choices can only span a single line")

      try:
        if not supports_result_index:
          pipe.write(str(index))
          pipe.write(" ")
        pipe.write(choice)
        pipe.write("\n")
      except BrokenPipeError:
        break

    try:
      pipe.close()
    except BrokenPipeError:
      pass

    exit_code: int = chooser.wait()
    if exit_code != 0:
      raise Exception("chooser process failed with exit code {}".format(exit_code))

    chosen_index = int(chooser.stdout.read().split()[0])
    return chosen_index


def send_notification(title: str, message: str, url: Optional[str] = None) -> None:
  if sys.platform == "darwin":
    cmd = ["terminal-notifier", "-title", title, "-message", message, "-open"]
    if url is not None:
      cmd.append(url)
  elif os.name == "posix":
    cmd = ["notify-send", "--icon=utilities-terminal", "--expire-time=3000", title, message]
  else:
    raise platform_not_supported_error()

  subprocess.run(cmd, check=True)


def set_clipboard(text: str) -> None:
  # TODO: somehow merge program selection with the logic in `zsh/functions.zsh`
  if sys.platform == "darwin":
    cmd = ["pbcopy"]
  elif os.name == "posix":
    cmd = ["xsel", "--clipboard", "--input"]
    # cmd = ["xclip", "-in", "-selection", "clipboard"]
  else:
    raise platform_not_supported_error()

  subprocess.run(cmd, input=text.encode(), check=True)


@contextmanager
def set_signal_handler(
  signum: "signal._SIGNUM", handler: "signal._HANDLER"
) -> Generator["signal._HANDLER", None, None]:
  prev_handler = signal.signal(signum, handler)
  try:
    yield prev_handler
  finally:
    signal.signal(signum, prev_handler)


# From <https://stackoverflow.com/a/64197445/12005228>
@contextmanager
def mask_signals(*signals: "signal._SIGNUM") -> Generator[Set["signal._SIGNUM"], None, None]:
  old_mask = signal.pthread_sigmask(signal.SIG_BLOCK, set(signals))
  try:
    yield old_mask
  finally:
    signal.pthread_sigmask(signal.SIG_SETMASK, old_mask)
