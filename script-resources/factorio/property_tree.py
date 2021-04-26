# <https://wiki.factorio.com/Property_tree>
# <factorio.https://wiki.factorio.com/Data_types>
# <https://github.com/credomane/factoriomodsettings/blob/master/src/ModSettingsDeserialiser.js>
# <https://github.com/credomane/factoriomodsettings/blob/master/src/ModSettingsSerialiser.js>
# <https://www.devdungeon.com/content/working-binary-data-python>

import struct
from typing import Any, IO


def read_bool(buf: IO[bytes]) -> bool:
  return buf.read(1)[0] == 1


def read_number(buf: IO[bytes]) -> float:
  return struct.unpack("<d", buf.read(8))[0]


def _read_length(buf: IO[bytes]) -> int:
  return struct.unpack("<I", buf.read(4))[0]


def read_string(buf: IO[bytes]) -> str:
  is_empty = read_bool(buf)
  if is_empty:
    return ""
  len_ = buf.read(1)[0]
  if len_ == 0xFF:
    len_ = _read_length(buf)
  return buf.read(len_).decode("utf8")


def read_dictionary(buf: IO[bytes]) -> dict[str, Any]:
  len_ = _read_length(buf)
  value: dict[str, Any] = {}
  for _ in range(len_):
    key = read_string(buf)
    value[key] = read(buf)
  return value


def read_list(buf: IO[bytes]) -> list[Any]:
  len_ = _read_length(buf)
  value: list[Any] = []
  for _ in range(len_):
    read_string(buf)
    value.append(read(buf))
  return value


def read(buf: IO[bytes]) -> Any:
  type_, _any_type_flag = buf.read(2)
  if type_ == 0:
    return None
  elif type_ == 1:
    return read_bool(buf)
  elif type_ == 2:
    return read_number(buf)
  elif type_ == 3:
    return read_string(buf)
  elif type_ == 4:
    return read_list(buf)
  elif type_ == 5:
    return read_dictionary(buf)
  else:
    raise Exception("unknown property tree type 0x{:02x}".format(type_))
