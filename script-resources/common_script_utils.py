import sys
import os
import subprocess


def platform_not_supported_error():
    raise Exception("platform '{}' is not supported!".format(sys.platform))


def run_chooser(choices, prompt=None, async_read=False):
    if sys.platform == "darwin":
        process_args = ["choose", "-i"]
    elif os.name == "posix":
        process_args = ["rofi", "-dmenu", "-i", "-format", "i"]
        if prompt is not None:
            process_args += ["-p", prompt]
        if async_read:
            process_args += ["-async-pre-read", "0"]
    else:
        platform_not_supported_error()

    chooser_process = subprocess.Popen(
        process_args, stdin=subprocess.PIPE, stdout=subprocess.PIPE
    )

    with chooser_process.stdin as pipe:
        for choice in choices:
            assert "\n" not in choice
            pipe.write(choice.encode())
            pipe.write(b"\n")

    exit_code = chooser_process.wait()
    if exit_code != 0:
        raise Exception("chooser process failed with exit code {}".format(exit_code))

    chosen_index = int(
        # an extra newline is inserted by rofi for whatever reason
        chooser_process.stdout.read().rstrip(b"\n")
    )

    return chosen_index


def send_notification(title, message, url=None):
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


def set_clipboard(text):
    # TODO: somehow merge program selection with the logic in `zsh/functions.zsh`
    if sys.platform == "darwin":
        process_args = ["pbcopy"]
    elif os.name == "posix":
        process_args = ["xsel", "--clipboard", "--input"]
        # process_args = ["xclip", "-in", "-selection", "clipboard"]
    else:
        platform_not_supported_error()

    subprocess.run(process_args, input=text.encode(), check=True)
