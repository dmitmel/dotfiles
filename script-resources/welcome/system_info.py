import os
import platform
import socket
from datetime import datetime, timedelta
from getpass import getuser
from typing import Dict, List, Optional, Tuple, cast

import psutil
from colors import Fore, Style, bright_colored, colored, colorize_percent
from humanize import humanize_bytes, humanize_timedelta


def get_system_info() -> Tuple[List[str], List[str]]:
  info_lines: List[str] = []

  def info(name: str, value: str, *format_args: object) -> None:
    line = bright_colored(name + ":", Fore.YELLOW) + " " + value
    if format_args:
      line = line % format_args
    info_lines.append(line)

  username = getuser()
  hostname = _get_hostname()

  info_lines.append(bright_colored(username, Fore.BLUE) + "@" + bright_colored(hostname, Fore.RED))
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

  shell = _get_shell()
  if shell is not None:
    info("Shell", shell)

  info_lines.append("")

  cpu_usage_info = _get_cpu_usage()
  if cpu_usage_info is not None:
    info("CPU Usage", "%s", cpu_usage_info)
  info("Memory", "%s / %s (%s)", *_get_memory())

  for disk_info in _get_disks():
    info("Disk (%s)", "%s / %s (%s)", *disk_info)

  battery_info = _get_battery()
  if battery_info is not None:
    info("Battery", "%s (%s)", *battery_info)

  info_lines.append("")

  for local_ip_address in _get_local_ipv4_addresses():
    info("Local IPv4 Address (%s)", "%s", *local_ip_address)

  return logo_lines, info_lines


def _get_hostname() -> str:
  hostname = socket.gethostname()
  return hostname


def _get_uptime() -> timedelta:
  return datetime.now() - datetime.fromtimestamp(psutil.boot_time())


def _get_users() -> str:
  users: Dict[str, List[str]] = {}

  for user in psutil.users():
    name: str = user.name
    terminal: str = user.terminal
    if name in users:
      users[name].append(terminal)
    else:
      users[name] = [terminal]

  result: List[str] = []

  for name in users:
    terminals = users[name]

    colored_name = bright_colored(name, Fore.BLUE)
    colored_terminals = [colored(str(term), Style.DIM, Fore.WHITE) for term in terminals]

    terminals_str = ", ".join(colored_terminals)
    if len(colored_terminals) > 1:
      terminals_str = "(%s)" % terminals_str
    result.append(colored_name + "@" + terminals_str)

  return ", ".join(result)


def _get_shell() -> Optional[str]:
  return os.environ.get("SHELL")


def _get_cpu_usage() -> Optional[str]:
  try:
    percent = cast(float, psutil.cpu_percent())
  except Exception as e:
    print("Error in _get_cpu_usage:", e)
    return None

  return colorize_percent(percent, warning=60, critical=80)


def _get_memory() -> Tuple[str, str, str]:
  memory = psutil.virtual_memory()
  return (
    humanize_bytes(memory.used),
    humanize_bytes(memory.total),
    colorize_percent(memory.percent, warning=60, critical=80),
  )


def _get_disks() -> List[Tuple[str, str, str, str]]:
  result: List[Tuple[str, str, str, str]] = []

  for disk in psutil.disk_partitions(all=False):
    if psutil.WINDOWS and ("cdrom" in disk.opts or disk.fstype == ""):
      # skip cd-rom drives with no disk in it on Windows; they may raise
      # ENOENT, pop-up a Windows GUI error for a non-ready partition or
      # just hang
      continue

    usage = psutil.disk_usage(disk.mountpoint)
    result.append((
      disk.mountpoint,
      humanize_bytes(usage.used),
      humanize_bytes(usage.total),
      colorize_percent(usage.percent, warning=70, critical=85),
    ))

  return result


def _get_battery() -> Optional[Tuple[str, str]]:
  if not hasattr(psutil, "sensors_battery"):
    return None

  try:
    battery = psutil.sensors_battery()
  except Exception as e:
    print("Error in _get_battery:", e)
    return None

  if battery is None:
    return None

  percent = battery.percent
  if battery.power_plugged:
    status = "charging" if percent < 100 else "fully charged"
  else:
    status = "%s left" % humanize_timedelta(timedelta(seconds=battery.secsleft))
  return colorize_percent(percent, critical=10, warning=20, inverse=True), status


def _get_local_ipv4_addresses() -> List[Tuple[str, str]]:
  result: List[Tuple[str, str]] = []

  for interface, addresses in psutil.net_if_addrs().items():
    for address in addresses:
      if address.family != socket.AF_INET:
        # allow only IPv4 addresses (skip IPv6 and MAC, for example)
        continue
      if interface.startswith("lo"):
        # skip loopback interfaces
        continue

      result.append((interface, address.address))

  return result


def _get_distro_info() -> Tuple[str, str, str, str]:
  if psutil.WINDOWS:
    return "windows", platform.system(), platform.release(), ""
  elif psutil.OSX:
    import plistlib

    with open("/System/Library/CoreServices/SystemVersion.plist", "rb") as f:
      sw_vers = plistlib.load(f)
    return "mac", sw_vers["ProductName"], sw_vers["ProductVersion"], ""
  elif _is_android():
    import subprocess

    android_version = subprocess.run(
      ["getprop", "ro.build.version.release"],
      check=True,
      stdout=subprocess.PIPE,
    ).stdout
    return "android", "Android", android_version.decode().strip(), ""
  elif psutil.LINUX:
    import distro

    return distro.id(), distro.name(), distro.version(), distro.codename()

  raise NotImplementedError("unsupported OS")


def _is_android() -> bool:
  return os.path.isdir("/system/app") and os.path.isdir("/system/priv-app")
