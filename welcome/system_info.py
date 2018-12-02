import os
import platform
import socket
from datetime import datetime, timedelta
from getpass import getuser

import psutil

from colors import Fore, Style, bright_colored, colored, colorize_percent
from humanize import humanize_bytes, humanize_timedelta


def get_system_info():
    info_lines = []

    def info(name, value, *format_args):
        line = bright_colored(name + ":", Fore.YELLOW) + " " + value
        if format_args:
            line = line % format_args
        info_lines.append(line)

    username = getuser()
    hostname, local_ip = _get_hostname()

    info_lines.append(
        bright_colored(username, Fore.BLUE) + "@" + bright_colored(hostname, Fore.RED)
    )
    info_lines.append("")

    distro_id, distro_name, distro_version, distro_codename = _get_distro_info()
    info("OS", " ".join([distro_name, distro_version, distro_codename]))

    logo_path = os.path.join(os.path.dirname(__file__), "logos", distro_id)
    with open(logo_path) as logo_file:
        logo_lines = logo_file.read().splitlines()

    info("Kernel", "%s %s", platform.system(), platform.release())

    info("Uptime", humanize_timedelta(_get_uptime()))

    users_info = _get_users()
    if users_info:
        info("Users", users_info)

    info("Shell", _get_shell())

    info("IP address", local_ip)

    info_lines.append("")

    info("CPU Usage", "%s", _get_cpu_usage())
    info("Memory", "%s / %s (%s)", *_get_memory())

    for disk_info in _get_disks():
        info("Disk (%s)", "%s / %s (%s)", *disk_info)

    battery_info = _get_battery()
    if battery_info is not None:
        info("Battery", "%s (%s)", *battery_info)

    return logo_lines, info_lines


def _get_hostname():
    hostname = socket.gethostname()
    local_ip = socket.gethostbyname(hostname)
    return hostname, local_ip


def _get_uptime():
    return datetime.now() - datetime.fromtimestamp(psutil.boot_time())


def _get_users():
    users = {}

    for user in psutil.users():
        name = user.name
        terminal = user.terminal
        if name in users:
            users[name].append(terminal)
        else:
            users[name] = [terminal]

    result = []

    for name in users:
        terminals = users[name]

        colored_name = bright_colored(name, Fore.BLUE)
        colored_terminals = [colored(term, Style.DIM, Fore.WHITE) for term in terminals]

        terminals_str = ", ".join(colored_terminals)
        if len(colored_terminals) > 1:
            terminals_str = "(%s)" % terminals_str
        result.append(colored_name + "@" + terminals_str)

    return ", ".join(result)


def _get_shell():
    return os.environ["SHELL"]


def _get_cpu_usage():
    percent = psutil.cpu_percent()

    return colorize_percent(percent, warning=60, critical=80)


def _get_memory():
    memory = psutil.virtual_memory()
    return (
        humanize_bytes(memory.used),
        humanize_bytes(memory.total),
        colorize_percent(memory.percent, warning=60, critical=80),
    )


def _get_disks():
    result = []
    for disk in psutil.disk_partitions(all=False):
        if psutil.WINDOWS and ("cdrom" in disk.opts or disk.fstype == ""):
            # skip cd-rom drives with no disk in it on Windows; they may raise
            # ENOENT, pop-up a Windows GUI error for a non-ready partition or
            # just hang
            continue

        usage = psutil.disk_usage(disk.mountpoint)
        result.append(
            (
                disk.mountpoint,
                humanize_bytes(usage.used),
                humanize_bytes(usage.total),
                colorize_percent(usage.percent, warning=70, critical=85),
            )
        )
    return result


def _get_battery():
    if not hasattr(psutil, "sensors_battery"):
        return None

    try:
        battery = psutil.sensors_battery()
    except Exception as e:
        print(e)
        return None

    if battery is None:
        return None

    percent = battery.percent
    if battery.power_plugged:
        status = "charging" if percent < 100 else "fully charged"
    else:
        status = "%s left" % humanize_timedelta(timedelta(seconds=battery.secsleft))
    return colorize_percent(percent, critical=10, warning=20, inverse=True), status


def _get_distro_info():
    if psutil.WINDOWS:
        return "windows", platform.system(), platform.release(), ""
    elif psutil.OSX:
        from plistlib import readPlist

        sw_vers = readPlist("/System/Library/CoreServices/SystemVersion.plist")
        return "mac", sw_vers["ProductName"], sw_vers["ProductVersion"], ""
    elif _is_android():
        from subprocess import check_output

        android_version = check_output(["getprop", "ro.build.version.release"])
        return "android", "Android", android_version.decode().strip(), ""
    elif psutil.LINUX:
        import distro

        return distro.id(), distro.name(), distro.version(), distro.codename()

    raise NotImplementedError("unsupported OS")


def _is_android():
    return os.path.isdir("/system/app") and os.path.isdir("/system/priv-app")
