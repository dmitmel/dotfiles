# <https://wiki.factorio.com/Property_tree>
# <https://wiki.factorio.com/Data_types>
# <https://github.com/credomane/factoriomodsettings/blob/master/src/ModSettingsDeserialiser.js>
# <https://github.com/credomane/factoriomodsettings/blob/master/src/ModSettingsSerialiser.js>
# <https://www.devdungeon.com/content/working-binary-data-python>

import struct
from typing import IO, Any, Generator, NamedTuple, Tuple


def read_bool(buf: IO[bytes]) -> bool:
  return buf.read(1)[0] == 1


def read_struct(buf: IO[bytes], format: str) -> Tuple[Any, ...]:
  return struct.unpack(format, buf.read(struct.calcsize(format)))


class FactorioVersion(NamedTuple):
  main: int
  major: int
  minor: int
  developer: int


def read_factorio_version(buf: IO[bytes]) -> FactorioVersion:
  # 4 unsigned shorts, see <https://wiki.factorio.com/Version_string_format>
  return FactorioVersion._make(read_struct(buf, "<HHHH"))


def read_string(buf: IO[bytes]) -> str:
  is_empty = read_bool(buf)
  if is_empty:
    return ""
  length = buf.read(1)[0]
  if length == 0xFF:
    length = read_struct(buf, "<I")[0]
  return buf.read(length).decode("utf8")


def read_property_tree_dict(buf: IO[bytes]) -> Generator[Tuple[str, Any]]:
  length = read_struct(buf, "<I")[0]
  for _ in range(length):
    key = read_string(buf)
    value = read_property_tree(buf)
    yield key, value


def read_property_tree(buf: IO[bytes]) -> Any:
  typ, _any_type_flag = buf.read(2)
  if typ == 0:
    return None
  elif typ == 1:
    return read_bool(buf)
  elif typ == 2:  # double
    return read_struct(buf, "<d")[0]
  elif typ == 3:
    return read_string(buf)
  elif typ == 4:
    return list(value for _key, value in read_property_tree_dict(buf))
  elif typ == 5:
    return dict(read_property_tree_dict(buf))
  elif typ == 6:  # signed long
    return read_struct(buf, "<q")[0]
  elif typ == 7:  # unsigned long
    return read_struct(buf, "<Q")[0]
  else:
    raise Exception(f"unknown property tree type 0x{typ:02x}")


# <https://wiki.factorio.com/Blueprint_string_format>
def load_blueprint_string(data: bytes) -> Any:
  import base64
  import json
  import zlib

  version, data = data[:1], data[1:]
  if version != b"0":
    raise ValueError("unsupported blueprint string version")
  data = base64.b64decode(data)
  data = zlib.decompress(data)
  return json.loads(data)
