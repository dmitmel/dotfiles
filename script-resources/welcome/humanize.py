from datetime import timedelta
from typing import List, Tuple


def humanize_timedelta(timedelta: timedelta) -> str:
  result: List[str] = []

  days = timedelta.days
  mm, ss = divmod(timedelta.seconds, 60)
  hh, mm = divmod(mm, 60)

  def plural(n: int) -> Tuple[int, str]:
    return n, "s" if abs(n) != 1 else ""

  if days > 0:
    result.append("%d day%s" % plural(days))
  if hh > 0 or result:
    result.append("%d hour%s" % plural(hh))
  if mm > 0 or result:
    result.append("%d min%s" % plural(mm))
  if len(result) <= 1:
    result.append("%d sec%s" % plural(ss))

  return ", ".join(result)


def humanize_bytes(bytes: int) -> str:
  units = ["B", "kB", "MB", "GB"]

  factor = 1
  unit = ""
  for unit in units:
    next_factor = factor << 10
    if bytes < next_factor:
      break
    factor = next_factor

  return "%.2f %s" % (float(bytes) / factor, unit)
