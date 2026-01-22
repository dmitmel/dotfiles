#!/usr/bin/env python3

import json
import os
from configparser import ConfigParser
from typing import Any, BinaryIO, Callable, Iterator, Literal, Protocol, TextIO, overload

__dir__ = os.path.dirname(__file__)


class Color:
  def __init__(self, r: int, g: int, b: int) -> None:
    if not (0 <= r <= 0xFF):
      raise Exception("r component out of range")
    if not (0 <= g <= 0xFF):
      raise Exception("g component out of range")
    if not (0 <= b <= 0xFF):
      raise Exception("b component out of range")
    self.r = r
    self.g = g
    self.b = b

  @classmethod
  def from_hex(cls, s: str) -> "Color":
    if len(s) != 6:
      raise Exception("hex color string must be 6 characters long")
    return Color(int(s[0:2], 16), int(s[2:4], 16), int(s[4:6], 16))

  @property
  def css_hex(self) -> str:
    return "#" + self.hex

  @property
  def hex(self) -> str:
    return f"{self.r:02x}{self.g:02x}{self.b:02x}"

  @property
  def rgb888(self) -> int:
    return ((self.r & 0xFF) << 16) | ((self.g & 0xFF) << 8) | (self.b & 0xFF)

  @property
  def float_rgb(self) -> tuple[float, float, float]:
    return float(self.r) / 0xFF, float(self.g) / 0xFF, float(self.b) / 0xFF

  def __getitem__(self, index: int) -> int:
    if index == 0:
      return self.r
    elif index == 1:
      return self.g
    elif index == 2:
      return self.b
    else:
      raise IndexError("color component index out of range")

  def __iter__(self) -> Iterator[int]:
    yield self.r
    yield self.g
    yield self.b


ANSI_TO_BASE16_MAPPING: list[int] = [
  0x0, 0x8, 0xB, 0xA, 0xD, 0xE, 0xC, 0x5,  # 0x0
  0x3, 0x8, 0xB, 0xA, 0xD, 0xE, 0xC, 0x7,  # 0x8
  0x9, 0xF, 0x1, 0x2, 0x4, 0x6,            # 0x10
]  # yapf: disable

BASE16_TO_ANSI_MAPPING: list[int] = [ANSI_TO_BASE16_MAPPING.index(i) for i in range(16)]
BASE16_BG_COLOR_IDX = 0x0
BASE16_FG_COLOR_IDX = 0x5
BASE16_SELECTION_BG_COLOR_IDX = 0x2
BASE16_LINK_COLOR_IDX = 0xC

ANSI_COLOR_NAMES = ["Black", "Red", "Green", "Yellow", "Blue", "Magenta", "Cyan", "White"]


class Theme(Protocol):
  base16_name: str
  is_dark: bool
  base16_colors: list[Color]

  @property
  def name(self) -> str:
    return f"base16-{self.base16_name}"

  @property
  def bg(self) -> Color:
    return self.base16_colors[BASE16_BG_COLOR_IDX]

  @property
  def fg(self) -> Color:
    return self.base16_colors[BASE16_FG_COLOR_IDX]

  @property
  def cursor_bg(self) -> Color:
    return self.fg

  @property
  def cursor_fg(self) -> Color:
    return self.bg

  @property
  def selection_bg(self) -> Color:
    return self.base16_colors[BASE16_SELECTION_BG_COLOR_IDX]

  @property
  def selection_fg(self) -> Color:
    return self.fg

  @property
  def ansi_colors(self) -> list[Color]:
    return [self.base16_colors[i] for i in ANSI_TO_BASE16_MAPPING]

  @property
  def link_color(self) -> Color:
    return self.ansi_colors[BASE16_LINK_COLOR_IDX]

  @property
  def css_variables(self) -> dict[str, Color]:
    d = {
      "bg": self.bg,
      "fg": self.fg,
      "selection-bg": self.selection_bg,
      "selection-fg": self.selection_fg,
      "cursor-bg": self.cursor_bg,
      "cursor-fg": self.cursor_fg,
    }
    for index, color in enumerate(self.base16_colors):
      d[f"base-{index:02X}"] = color
    return d


class IniTheme(Theme):
  def __init__(self, file_path: str) -> None:
    self.file_path = file_path
    config = ConfigParser(interpolation=None)
    config.read(file_path)
    self.base16_name = config.get("Theme", "base16_name")
    self.is_dark = config.getboolean("Theme", "is_dark")
    self.base16_colors = [
      Color.from_hex(config.get("Theme", f"base16_color_{i:02x}")) for i in range(16)
    ]


TEXT_THEME_GENERATORS: dict[str, Callable[[Theme, TextIO], None]] = {}
BINARY_THEME_GENERATORS: dict[str, Callable[[Theme, BinaryIO], None]] = {}


@overload
def add_theme_generator(
  file_name: str, binary: Literal[True]
) -> Callable[[Callable[[Theme, BinaryIO], None]], None]: ...


@overload
def add_theme_generator(
  file_name: str, binary: Literal[False] = False
) -> Callable[[Callable[[Theme, TextIO], None]], None]: ...


def add_theme_generator(file_name: str, binary: bool = False):

  def decorator(fn: Callable[[Theme, BinaryIO | TextIO], None], /) -> None:
    (BINARY_THEME_GENERATORS if binary else TEXT_THEME_GENERATORS)[file_name] = fn

  return decorator


@add_theme_generator("kitty.conf")
def generate_kitty(theme: Theme, output: TextIO) -> None:
  def write_color(key_name: str, color: Color) -> None:
    output.write(f"{key_name} {color.css_hex}\n")

  write_color("background", theme.bg)
  write_color("foreground", theme.fg)
  write_color("cursor", theme.cursor_bg)
  write_color("cursor_text_color", theme.cursor_fg)
  write_color("selection_background", theme.selection_bg)
  write_color("selection_foreground", theme.selection_fg)
  for index, color in enumerate(theme.ansi_colors[:16]):
    write_color(f"color{index}", color)
  write_color("url_color", theme.link_color)

  write_color("active_border_color", theme.ansi_colors[2])
  write_color("inactive_border_color", theme.ansi_colors[8])
  write_color("bell_border_color", theme.ansi_colors[1])

  write_color("active_tab_foreground", theme.base16_colors[0x1])
  write_color("active_tab_background", theme.base16_colors[0xB])
  write_color("inactive_tab_foreground", theme.base16_colors[0x4])
  write_color("inactive_tab_background", theme.base16_colors[0x1])
  write_color("tab_bar_background", theme.base16_colors[0x1])


@add_theme_generator("termux.properties")
def generate_termux(theme: Theme, output: TextIO) -> None:
  def write_color(key_name: str, color: Color) -> None:
    output.write(f"{key_name}={color.css_hex}\n")

  write_color("background", theme.bg)
  write_color("foreground", theme.fg)
  write_color("cursor", theme.cursor_bg)
  for index, color in enumerate(theme.ansi_colors[:16]):
    write_color(f"color{index}", color)


@add_theme_generator("zsh.zsh")
def generate_zsh(theme: Theme, output: TextIO) -> None:
  def write_color(key_name: str, color: Color) -> None:
    output.write(f"colorscheme_{key_name}={color.hex}\n")

  write_color("bg", theme.bg)
  write_color("fg", theme.fg)
  write_color("cursor_bg", theme.cursor_bg)
  write_color("cursor_fg", theme.cursor_fg)
  write_color("selection_bg", theme.selection_bg)
  write_color("selection_fg", theme.selection_fg)
  write_color("link_color", theme.link_color)

  output.write("colorscheme_ansi_colors=(\n")
  for color in theme.ansi_colors:
    output.write(f"  {color.hex}\n")
  output.write(")\n")


@add_theme_generator("vim.vim")
def generate_vim(theme: Theme, output: TextIO) -> None:
  namespace = "dotfiles#colorscheme#"
  output.write(f"let {namespace}name = {json.dumps(theme.name)}\n")
  output.write(f"let {namespace}base16_name = {json.dumps(theme.base16_name)}\n")
  output.write(f"let {namespace}is_dark = {int(theme.is_dark)}\n")
  output.write(f"let {namespace}base16_colors = [\n")
  for gui_color, cterm_color in zip(theme.base16_colors, BASE16_TO_ANSI_MAPPING):
    output.write(
      f"\\ {{'gui': '{gui_color.css_hex}', 'cterm': {cterm_color:2},"
      f" 'r': 0x{gui_color.r:02x}, 'g': 0x{gui_color.g:02x}, 'b': 0x{gui_color.b:02x}}},\n",
    )
  output.write("\\ ]\n")
  output.write(
    f"let {namespace}ansi_colors_mapping = [{', '.join(map(str, ANSI_TO_BASE16_MAPPING))}]\n"
  )


# default setvtrgb config:
# 0,170,0,170,0,170,0,170,85,255,85,255,85,255,85,255
# 0,0,170,85,0,0,170,170,85,85,255,255,85,85,255,255
# 0,0,0,0,170,170,170,170,85,85,85,85,255,255,255,255
@add_theme_generator("setvtrgb.txt")
def generate_setvtrgb(theme: Theme, output: TextIO) -> None:
  for i in range(3):
    output.write(",".join(str(color[i]) for color in theme.ansi_colors[:16]))
    output.write("\n")


@add_theme_generator("xfce4-terminal.theme")
def generate_xfce_terminal(theme: Theme, output: TextIO) -> None:
  output.write("[Scheme]\n")
  output.write("Name=dmitmel's dotfiles colorscheme\n")
  output.write(f"ColorForeground={theme.fg.css_hex}\n")
  output.write(f"ColorBackground={theme.bg.css_hex}\n")
  output.write("ColorCursorUseDefault=FALSE\n")
  output.write(f"ColorCursorForeground={theme.cursor_fg.css_hex}\n")
  output.write(f"ColorCursor={theme.cursor_bg.css_hex}\n")
  output.write("ColorSelectionUseDefault=FALSE\n")
  output.write(f"ColorSelection={theme.selection_fg.css_hex}\n")
  output.write(f"ColorSelectionBackground={theme.selection_bg.css_hex}\n")
  output.write(f"TabActivityColor={theme.base16_colors[0x8].css_hex}\n")
  output.write("ColorBoldUseDefault=TRUE\n")
  output.write(f"ColorBold={theme.fg.css_hex}\n")
  output.write(f"ColorPalette={';'.join(color.css_hex for color in theme.ansi_colors[:16])}\n")


@add_theme_generator("vscode-colorCustomizations.json")
def generate_vscode(theme: Theme, output: TextIO) -> None:
  colors: dict[str, str] = {
    "terminal.background": theme.bg.css_hex,
    "terminal.foreground": theme.fg.css_hex,
    "terminal.selectionBackground": theme.selection_bg.css_hex,
    "terminalCursor.background": theme.cursor_fg.css_hex,
    "terminalCursor.foreground": theme.cursor_bg.css_hex,
  }

  for is_bright in [False, True]:
    for color_index, color_name in enumerate(ANSI_COLOR_NAMES):
      color = theme.ansi_colors[color_index + int(is_bright) * len(ANSI_COLOR_NAMES)]
      colors["terminal.ansi" + ("Bright" if is_bright else "") + color_name] = color.css_hex

  json.dump(colors, output, ensure_ascii=False, indent=2)
  output.write("\n")


@add_theme_generator("iterm.itermcolors", binary=True)
def generate_iterm2(theme: Theme, output: BinaryIO) -> None:
  import plistlib

  colors: dict[str, dict[str, object]] = {}

  def write_color(key_name: str, color: Color) -> None:
    r, g, b = color.float_rgb
    colors[key_name + " Color"] = {
      "Color Space": "sRGB",
      "Red Component": r,
      "Green Component": g,
      "Blue Component": b,
    }

  write_color("Background", theme.bg)
  write_color("Foreground", theme.fg)
  write_color("Bold", theme.fg)
  write_color("Cursor", theme.cursor_bg)
  write_color("Cursor Text", theme.cursor_fg)
  write_color("Selection Color", theme.selection_bg)
  write_color("Selected Text Color", theme.selection_fg)
  for index, color in enumerate(theme.ansi_colors[:16]):
    write_color("Ansi " + str(index), color)
  write_color("Link", theme.link_color)

  plistlib.dump(colors, output, fmt=plistlib.FMT_XML, sort_keys=False)


@add_theme_generator("variables.css")
def generate_css_variables(theme: Theme, output: TextIO) -> None:
  output.write(":root {\n")
  for var_name, color in theme.css_variables.items():
    output.write(f"  --dotfiles-colorscheme-{var_name}: {color.css_hex};\n")
  output.write("}\n")


@add_theme_generator("_colorscheme.scss")
def generate_scss(theme: Theme, output: TextIO) -> None:
  output.write(f"$is-dark: {'true' if theme.is_dark else 'false'};\n")
  for var_name, color in theme.css_variables.items():
    output.write(f"${var_name}: {color.css_hex};\n")
  output.write(f"$base: ({', '.join(c.css_hex for c in theme.base16_colors)});\n")
  output.write(f"$ansi: ({', '.join(c.css_hex for c in theme.ansi_colors)});\n")


@add_theme_generator("prismjs-theme.css")
def generate_prism_js(theme: Theme, output: TextIO) -> None:
  with open(os.path.join(__dir__, "prismjs-theme-src.css")) as src_file:
    src_css = src_file.read()
  for var_name, color in theme.css_variables.items():
    src_css = src_css.replace(f"var(--dotfiles-colorscheme-{var_name})", color.css_hex)
  output.write(src_css)


@add_theme_generator("colorscheme.lua")
def generate_lua(theme: Theme, output: TextIO) -> None:
  output.write("local theme = {}\n")
  output.write(f"theme.base16_name = {json.dumps(theme.base16_name)}\n")
  output.write(f"theme.is_dark = {'true' if theme.is_dark else 'false'}\n")
  output.write(
    "---@type table<integer, { gui: integer, cterm: integer, r: integer, g: integer, b: integer }>\n"
  )
  output.write("local colors = {\n")
  for index, (gui_color, cterm_color) in enumerate(
    zip(theme.base16_colors, BASE16_TO_ANSI_MAPPING)
  ):
    output.write(
      f"  [{index:2}] = {{ gui = 0x{gui_color.rgb888:06x}, cterm = {cterm_color:2},"
      f" r = 0x{gui_color.r:02x}, g = 0x{gui_color.g:02x}, b = 0x{gui_color.b:02x} }},\n"
    )
  output.write("}\n")
  output.write("theme.base16_colors = colors\n")
  output.write("theme.ansi_colors = {\n")
  for i in ANSI_TO_BASE16_MAPPING:
    output.write(f"  colors[{i}],\n")
  output.write("}\n")
  output.write(f"theme.bg = colors[{BASE16_BG_COLOR_IDX}]\n")
  output.write(f"theme.fg = colors[{BASE16_FG_COLOR_IDX}]\n")
  output.write(f"theme.cursor_bg = colors[{BASE16_FG_COLOR_IDX}]\n")
  output.write(f"theme.cursor_fg = colors[{BASE16_BG_COLOR_IDX}]\n")
  output.write(f"theme.selection_bg = colors[{BASE16_SELECTION_BG_COLOR_IDX}]\n")
  output.write(f"theme.selection_fg = colors[{BASE16_FG_COLOR_IDX}]\n")
  output.write(f"theme.link_color = colors[{BASE16_LINK_COLOR_IDX}]\n")
  output.write("---@type table<integer, integer>\n")
  output.write(
    f"theme.ansi_to_base16_mapping = {{{', '.join(map(str, ANSI_TO_BASE16_MAPPING))}}}\n"
  )
  output.write("---@type table<integer, integer>\n")
  output.write(
    f"theme.base16_to_ansi_mapping = {{{', '.join(map(str, BASE16_TO_ANSI_MAPPING))}}}\n"
  )
  output.write("return theme\n")


@add_theme_generator("apple-terminal.terminal", binary=True)
def generate_apple_terminal(theme: Theme, output: BinaryIO) -> None:
  import plistlib

  profile: dict[str, Any] = {
    "ProfileCurrentVersion": 2.07,
    "name": "dotfiles",
    "type": "Window Settings",
    "UseBrightBold": False,
  }

  def write_color(key_name: str, color: Color) -> None:
    float_rgb_str = " ".join(f"{x:.10f}".rstrip("0").rstrip(".") for x in color.float_rgb)
    color_archive = {
      "$archiver": "NSKeyedArchiver",
      "$version": 100000,
      "$top": {"root": plistlib.UID(1)},
      "$objects": [
        "$null",
        {
          "$class": plistlib.UID(2),
          "NSColorSpace": 2,  # 1 is "Generic RGB", 2 is "Device RGB"
          "NSRGB": float_rgb_str.encode("ascii") + b"\x00",
        },
        {
          "$classes": ["NSColor", "NSObject"],
          "$classname": "NSColor",
        },
      ],
    }
    profile[key_name] = plistlib.dumps(color_archive, fmt=plistlib.FMT_BINARY)

  write_color("TextColor", theme.fg)
  write_color("TextBoldColor", theme.fg)
  write_color("BackgroundColor", theme.bg)
  write_color("CursorColor", theme.cursor_bg)
  write_color("SelectionColor", theme.selection_bg)

  for is_bright in [False, True]:
    for color_index, color_name in enumerate(ANSI_COLOR_NAMES):
      color = theme.ansi_colors[color_index + int(is_bright) * len(ANSI_COLOR_NAMES)]
      write_color("ANSI" + ("Bright" if is_bright else "") + color_name + "Color", color)

  plistlib.dump(profile, output, fmt=plistlib.FMT_XML)


@add_theme_generator(".minttyrc")
def generate_mintty(theme: Theme, output: TextIO) -> None:
  def write_color(name: str, color: Color) -> None:
    output.write(f"{name}={color.r},{color.g},{color.b}\n")

  write_color("BackgroundColour", theme.bg)
  write_color("ForegroundColour", theme.fg)
  write_color("CursorColour", theme.cursor_bg)
  for idx, name in enumerate(ANSI_COLOR_NAMES):
    write_color(name, theme.ansi_colors[idx])
    write_color("Bold" + name, theme.ansi_colors[idx + 8])


def main() -> None:
  theme: Theme = IniTheme(os.path.join(__dir__, "data.ini"))

  out_dir = os.path.join(__dir__, "out")
  os.makedirs(out_dir, exist_ok=True)

  for file_name, generator in TEXT_THEME_GENERATORS.items():
    with open(os.path.join(out_dir, file_name), "w") as output:
      generator(theme, output)

  for file_name, generator in BINARY_THEME_GENERATORS.items():
    with open(os.path.join(out_dir, file_name), "wb") as output:
      generator(theme, output)


if __name__ == "__main__":
  main()
