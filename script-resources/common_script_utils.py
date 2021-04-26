import sys
import os
import subprocess
from pathlib import Path
from typing import Iterable, NoReturn

if os.name == "posix":
    DOTFILES_CONFIG_DIR: Path = Path.home() / ".config" / "dotfiles"
    DOTFILES_CACHE_DIR: Path = Path.home() / ".cache" / "dotfiles"


def platform_not_supported_error() -> NoReturn:
    raise Exception("platform '{}' is not supported!".format(sys.platform))


def run_chooser(choices: Iterable[str], prompt: str = None, async_read: bool = False) -> int:
    supports_result_index = True
    if os.isatty(sys.stderr.fileno()):
        process_args = [
            "fzf",
            "--with-nth=2..",
            "--height=50%",
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
        platform_not_supported_error()

    chooser_process = subprocess.Popen(process_args, stdin=subprocess.PIPE, stdout=subprocess.PIPE)

    with chooser_process.stdin as pipe:
        for index, choice in enumerate(choices):
            assert "\n" not in choice
            if not supports_result_index:
                pipe.write(str(index).encode())
                pipe.write(b" ")
            pipe.write(choice.encode())
            pipe.write(b"\n")

    exit_code: int = chooser_process.wait()
    if exit_code != 0:
        raise Exception("chooser process failed with exit code {}".format(exit_code))

    chosen_index = int(chooser_process.stdout.read().strip().split()[0])
    return chosen_index


def send_notification(title: str, message: str, url: str = None) -> None:
    if sys.platform == "darwin":
        process_args = [
            "terminal-notifier",
            "-title",
            title,
            "-message",
            message,
            "-open",
        ]
        if url is not None:
            process_args += [url]
    elif os.name == "posix":
        process_args = [
            "notify-send",
            "--icon=utilities-terminal",
            "--expire-time=3000",
            title,
            message,
        ]
    else:
        platform_not_supported_error()

    subprocess.run(process_args, check=True)


def set_clipboard(text: str) -> None:
    # TODO: somehow merge program selection with the logic in `zsh/functions.zsh`
    if sys.platform == "darwin":
        process_args = ["pbcopy"]
    elif os.name == "posix":
        process_args = ["xsel", "--clipboard", "--input"]
        # process_args = ["xclip", "-in", "-selection", "clipboard"]
    else:
        platform_not_supported_error()

    subprocess.run(process_args, input=text.encode(), check=True)
