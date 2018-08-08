import os
import platform
import socket
from datetime import datetime, timedelta
import re
from getpass import getuser
from colorama import Fore, Back, Style, ansi
import psutil

COLORS = [ansi.code_to_chars(30 + color_index) for color_index in range(0, 8)]


def colored(string, *colors):
  return ''.join(colors + (string, Style.RESET_ALL))


def bright_colored(string, *colors):
  return ''.join(colors + (Style.BRIGHT, string, Style.RESET_ALL))


def format_timedelta(timedelta):
  result = []

  days = timedelta.days
  mm, ss = divmod(timedelta.seconds, 60)
  hh, mm = divmod(mm, 60)

  def plural(n):
    return n, 's' if abs(n) != 1 else ''

  if days > 0:
    result.append('%d day%s' % plural(days))
  if hh > 0 or len(result) > 0:
    result.append('%d hour%s' % plural(hh))
  if mm > 0 or len(result) > 0:
    result.append('%d min%s' % plural(mm))
  if len(result) <= 1:
    result.append('%d sec%s' % plural(ss))

  return ', '.join(result)


def humanize_bytes(bytes):
  units = ['B', 'kB', 'MB', 'GB']

  factor = 1
  for unit in units:
    next_factor = factor << 10
    if bytes < next_factor:
      break
    factor = next_factor

  return '%.2f %s' % (float(bytes) / factor, unit)


def colorize_percent(percent, warning, critical, inverse=False):
  COLORS = [Fore.GREEN, Fore.YELLOW, Fore.RED]

  color_index = 0 if percent < warning else 1 if percent < critical else 2
  if inverse:
    color_index = 2 - color_index

  return colored('%.2f%%' % percent, COLORS[color_index])


def get_hostname():
  hostname = socket.gethostname()
  local_ip = socket.gethostbyname(hostname)
  return hostname, local_ip


def uptime():
  return datetime.now() - datetime.fromtimestamp(psutil.boot_time())


def users():
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
    colored_terminals = [
        colored(term, Style.BRIGHT, Fore.BLACK) for term in terminals
    ]

    terminals_str = ', '.join(colored_terminals)
    if len(colored_terminals) > 1:
      terminals_str = '(%s)' % terminals_str
    result.append(colored_name + '@' + terminals_str)

  return ', '.join(result)


def shell():
  return os.environ['SHELL']


def cpu_usage():
  percent = psutil.cpu_percent()

  return colorize_percent(percent, warning=60, critical=80)


def memory():
  memory = psutil.virtual_memory()
  return (humanize_bytes(memory.used), humanize_bytes(memory.total),
          colorize_percent(memory.percent, warning=60, critical=80))


def disks():
  result = []
  for disk in psutil.disk_partitions(all=False):
    if psutil.WINDOWS and ('cdrom' in disk.opts or disk.fstype == ''):
      # skip cd-rom drives with no disk in it on Windows; they may raise ENOENT,
      # pop-up a Windows GUI error for a non-ready partition or just hang
      continue

    usage = psutil.disk_usage(disk.mountpoint)
    result.append((disk.mountpoint, humanize_bytes(usage.used),
                   humanize_bytes(usage.total),
                   colorize_percent(usage.percent, warning=70, critical=85)))
  return result


def battery():
  if not hasattr(psutil, 'sensors_battery'):
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
    status = 'charging' if percent < 100 else 'fully charged'
  else:
    status = '%s left' % format_timedelta(timedelta(seconds=battery.secsleft))

  return colorize_percent(
      percent, critical=10, warning=20, inverse=True), status


def get_distro_info():
  if psutil.WINDOWS:
    return 'windows', platform.system(), platform.release(), ''
  elif psutil.LINUX:
    import distro
    return distro.id(), distro.name(), distro.version(), distro.codename()
  elif psutil.OSX:
    from plistlib import readPlist
    sw_vers = readPlist('/System/Library/CoreServices/SystemVersion.plist')
    return 'mac', sw_vers['ProductName'], sw_vers['ProductVersion'], ''
  else:
    raise NotImplementedError('unsupported OS')


def get_system_info():
  info_lines = []

  def info(name, value, *format_args):
    line = colored(name + ':', Style.BRIGHT, Fore.YELLOW) + ' ' + value
    if len(format_args) > 0:
      line = line % format_args
    info_lines.append(line)

  username = getuser()
  hostname, local_ip = get_hostname()

  info_lines.append(
      bright_colored(username, Fore.BLUE) + '@' +
      bright_colored(hostname, Fore.RED))
  info_lines.append('')

  distro_id, distro_name, distro_version, distro_codename = get_distro_info()
  info('OS', ' '.join([distro_name, distro_version, distro_codename]))

  logo_path = os.path.join(os.path.dirname(__file__), 'logos', distro_id)
  with open(logo_path) as logo_file:
    logo_lines = logo_file.read().splitlines()

  info('Kernel', '%s %s', platform.system(), platform.release())

  info('Uptime', format_timedelta(uptime()))
  info('Users', users())
  info('Shell', shell())
  info('IP address', local_ip)

  info_lines.append('')

  info('CPU Usage', '%s', cpu_usage())
  info('Memory', '%s / %s (%s)', *memory())

  for disk_info in disks():
    info('Disk (%s)', '%s / %s (%s)', *disk_info)

  battery_info = battery()
  if battery_info is not None:
    info('Battery', '%s (%s)', *battery_info)

  return logo_lines, info_lines


print('')

logo_lines, info_lines = get_system_info()
logo_line_widths = [len(re.sub(r'{\d}', '', line)) for line in logo_lines]
logo_width = max(logo_line_widths)

for line_index in range(0, max(len(logo_lines), len(info_lines))):
  line = ''

  logo_line_width = 0

  if line_index < len(logo_lines):
    logo_line = logo_lines[line_index]
    logo_line_width = logo_line_widths[line_index]

    line += Style.BRIGHT
    line += logo_line.format(*COLORS)
    line += Style.RESET_ALL

  line += ' ' * (logo_width - logo_line_width + 3)

  if line_index < len(info_lines):
    info_line = info_lines[line_index]
    line += info_line

  print(line)

print('')
