# <https://wiki.factorio.com/Property_tree>
# <factorio.https://wiki.factorio.com/Data_types>
# <https://github.com/credomane/factoriomodsettings/blob/master/src/ModSettingsDeserialiser.js>
# <https://github.com/credomane/factoriomodsettings/blob/master/src/ModSettingsSerialiser.js>
# <https://www.devdungeon.com/content/working-binary-data-python>

import struct


def read_bool(buf):
    return buf.read(1)[0] == 1


def read_number(buf):
    return struct.unpack("<d", buf.read(8))[0]


def _read_length(buf):
    return struct.unpack("<I", buf.read(4))[0]


def read_string(buf):
    is_empty = read_bool(buf)
    if is_empty:
        return ""
    len_ = buf.read(1)[0]
    if len_ == 0xFF:
        len_ = _read_length(buf)
    return buf.read(len_).decode("utf8")


def read_dictionary(buf):
    len_ = _read_length(buf)
    value = {}
    for _ in range(len_):
        key = read_string(buf)
        value[key] = read(buf)
    return value


def read_list(buf):
    len_ = _read_length(buf)
    value = []
    for _ in range(len_):
        read_string(buf)
        value.append(read(buf))
    return value


def read(buf):
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
