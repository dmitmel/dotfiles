#!/usr/bin/env python3

import json
import os
from abc import abstractmethod
from collections.abc import Iterator
from configparser import ConfigParser
from typing import IO, Any, BinaryIO, Protocol, TextIO

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
    return "#{:02x}{:02x}{:02x}".format(self.r, self.g, self.b)

  @property
  def hex(self) -> str:
    return "{:02x}{:02x}{:02x}".format(self.r, self.g, self.b)

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


class Theme(Protocol):
  base16_name: str
  is_dark: bool
  base16_colors: list[Color]

  @property
  def name(self) -> str:
    return "base16-{}".format(self.base16_name)

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
      d["base-{:02X}".format(index)] = color
    return d


class IniTheme(Theme):
  def __init__(self, file_path: str) -> None:
    self.file_path = file_path
    config = ConfigParser(interpolation=None)
    config.read(file_path)
    self.base16_name = config.get("Theme", "base16_name")
    self.is_dark = config.getboolean("Theme", "is_dark")
    self.base16_colors = [
      Color.from_hex(config.get("Theme", "base16_color_{:02x}".format(i))) for i in range(16)
    ]


class ThemeGenerator(Protocol):
  @abstractmethod
  def file_name(self) -> str:
    raise NotImplementedError()

  def is_binary(self) -> bool:
    return False

  @abstractmethod
  def generate(self, theme: Theme, output: IO[Any]) -> None:
    raise NotImplementedError()


class ThemeGeneratorKitty(ThemeGenerator):
  def file_name(self) -> str:
    return "kitty.conf"

  def generate(self, theme: Theme, output: TextIO) -> None:
    def write_color(key_name: str, color: Color) -> None:
      output.write("{} {}\n".format(key_name, color.css_hex))

    write_color("background", theme.bg)
    write_color("foreground", theme.fg)
    write_color("cursor", theme.cursor_bg)
    write_color("cursor_text_color", theme.cursor_fg)
    write_color("selection_background", theme.selection_bg)
    write_color("selection_foreground", theme.selection_fg)
    for index, color in enumerate(theme.ansi_colors[:16]):
      write_color("color{}".format(index), color)
    write_color("url_color", theme.link_color)

    write_color("active_border_color", theme.ansi_colors[2])
    write_color("inactive_border_color", theme.ansi_colors[8])
    write_color("bell_border_color", theme.ansi_colors[1])

    write_color("active_tab_foreground", theme.base16_colors[0x1])
    write_color("active_tab_background", theme.base16_colors[0xB])
    write_color("inactive_tab_foreground", theme.base16_colors[0x4])
    write_color("inactive_tab_background", theme.base16_colors[0x1])
    write_color("tab_bar_background", theme.base16_colors[0x1])


class ThemeGeneratorTermux(ThemeGenerator):
  def file_name(self) -> str:
    return "termux.properties"

  def generate(self, theme: Theme, output: TextIO) -> None:
    def write_color(key_name: str, color: Color) -> None:
      output.write("{}={}\n".format(key_name, color.css_hex))

    write_color("background", theme.bg)
    write_color("foreground", theme.fg)
    write_color("cursor", theme.cursor_bg)
    for index, color in enumerate(theme.ansi_colors[:16]):
      write_color("color{}".format(index), color)


class ThemeGeneratorZsh(ThemeGenerator):
  def file_name(self) -> str:
    return "zsh.zsh"

  def generate(self, theme: Theme, output: TextIO) -> None:
    def write_color(key_name: str, color: Color) -> None:
      output.write("colorscheme_{}={}\n".format(key_name, color.hex))

    write_color("bg", theme.bg)
    write_color("fg", theme.fg)
    write_color("cursor_bg", theme.cursor_bg)
    write_color("cursor_fg", theme.cursor_fg)
    write_color("selection_bg", theme.selection_bg)
    write_color("selection_fg", theme.selection_fg)
    write_color("link_color", theme.link_color)

    output.write("colorscheme_ansi_colors=(\n")
    for color in theme.ansi_colors:
      output.write("  {}\n".format(color.hex))
    output.write(")\n")


class ThemeGeneratorVim(ThemeGenerator):
  def file_name(self) -> str:
    return "vim.vim"

  def generate(self, theme: Theme, output: TextIO) -> None:
    namespace = "dotfiles#colorscheme#"
    output.write("let {}name = {}\n".format(namespace, json.dumps(theme.name)))
    output.write("let {}base16_name = {}\n".format(namespace, json.dumps(theme.base16_name)))
    output.write("let {}is_dark = {}\n".format(namespace, int(theme.is_dark)))
    output.write("let {}base16_colors = [\n".format(namespace))
    for gui_color, cterm_color in zip(theme.base16_colors, BASE16_TO_ANSI_MAPPING):
      output.write(
        "\\ {{'gui': '{}', 'cterm': {:2}, 'r': 0x{:02x}, 'g': 0x{:02x}, 'b': 0x{:02x}}},\n".format(
          gui_color.css_hex, cterm_color, gui_color.r, gui_color.g, gui_color.b
        ),
      )
    output.write("\\ ]\n")
    output.write(
      "let {}ansi_colors_mapping = [{}]\n".format(
        namespace, ", ".join("0x{:X}".format(i) for i in ANSI_TO_BASE16_MAPPING)
      )
    )


class ThemeGeneratorSetvtrgb(ThemeGenerator):
  # default setvtrgb config:
  # 0,170,0,170,0,170,0,170,85,255,85,255,85,255,85,255
  # 0,0,170,85,0,0,170,170,85,85,255,255,85,85,255,255
  # 0,0,0,0,170,170,170,170,85,85,85,85,255,255,255,255

  def file_name(self) -> str:
    return "setvtrgb.txt"

  def generate(self, theme: Theme, output: TextIO) -> None:
    for i in range(3):
      output.write(",".join(str(color[i]) for color in theme.ansi_colors[:16]))
      output.write("\n")


class ThemeGeneratorXfceTerminal(ThemeGenerator):
  def file_name(self) -> str:
    return "xfce4-terminal.theme"

  def generate(self, theme: Theme, output: TextIO) -> None:
    output.write("[Scheme]\n")
    output.write("Name=dmitmel's dotfiles colorscheme\n")
    output.write("ColorForeground={}\n".format(theme.fg.css_hex))
    output.write("ColorBackground={}\n".format(theme.bg.css_hex))
    output.write("ColorCursorUseDefault=FALSE\n")
    output.write("ColorCursorForeground={}\n".format(theme.cursor_fg.css_hex))
    output.write("ColorCursor={}\n".format(theme.cursor_bg.css_hex))
    output.write("ColorSelectionUseDefault=FALSE\n")
    output.write("ColorSelection={}\n".format(theme.selection_fg.css_hex))
    output.write("ColorSelectionBackground={}\n".format(theme.selection_bg.css_hex))
    output.write("TabActivityColor={}\n".format(theme.base16_colors[0x8].css_hex))
    output.write("ColorBoldUseDefault=TRUE\n")
    output.write("ColorBold={}\n".format(theme.fg.css_hex))
    output.write(
      "ColorPalette={}\n".format(";".join(color.css_hex for color in theme.ansi_colors[:16])),
    )


class ThemeGeneratorVscode(ThemeGenerator):
  ANSI_COLOR_NAMES = ["Black", "Red", "Green", "Yellow", "Blue", "Magenta", "Cyan", "White"]

  def file_name(self) -> str:
    return "vscode-colorCustomizations.json"

  def generate(self, theme: Theme, output: TextIO) -> None:
    colors: dict[str, str] = {
      "terminal.background": theme.bg.css_hex,
      "terminal.foreground": theme.fg.css_hex,
      "terminal.selectionBackground": theme.selection_bg.css_hex,
      "terminalCursor.background": theme.cursor_fg.css_hex,
      "terminalCursor.foreground": theme.cursor_bg.css_hex,
    }

    for is_bright in [False, True]:
      for color_index, color_name in enumerate(self.ANSI_COLOR_NAMES):
        color = theme.ansi_colors[color_index + int(is_bright) * len(self.ANSI_COLOR_NAMES)]
        colors["terminal.ansi" + ("Bright" if is_bright else "") + color_name] = color.css_hex

    json.dump(colors, output, ensure_ascii=False, indent=2)
    output.write("\n")


class ThemeGeneratorIterm(ThemeGenerator):
  def file_name(self) -> str:
    return "iterm.itermcolors"

  def is_binary(self) -> bool:
    return True

  def generate(self, theme: Theme, output: BinaryIO) -> None:
    import plistlib

    colors = {}

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


class ThemeGeneratorCssVariables(ThemeGenerator):
  def file_name(self) -> str:
    return "variables.css"

  def generate(self, theme: Theme, output: TextIO) -> None:
    output.write(":root {\n")
    for var_name, color in theme.css_variables.items():
      output.write("  --dotfiles-colorscheme-{}: {};\n".format(var_name, color.css_hex))
    output.write("}\n")


class ThemeGeneratorScss(ThemeGenerator):
  def file_name(self) -> str:
    return "_colorscheme.scss"

  def generate(self, theme: Theme, output: TextIO) -> None:
    output.write("$is-dark: {};\n".format("true" if theme.is_dark else "false"))
    for var_name, color in theme.css_variables.items():
      output.write("${}: {};\n".format(var_name, color.css_hex))
    output.write("$base: ({});\n".format(", ".join(c.css_hex for c in theme.base16_colors)))
    output.write("$ansi: ({});\n".format(", ".join(c.css_hex for c in theme.ansi_colors)))


class ThemeGeneratorPrismJs(ThemeGenerator):
  def file_name(self) -> str:
    return "prismjs-theme.css"

  def generate(self, theme: Theme, output: TextIO) -> None:
    with open(os.path.join(__dir__, "prismjs-theme-src.css")) as src_file:
      src_css = src_file.read()
    for var_name, color in theme.css_variables.items():
      src_css = src_css.replace("var(--dotfiles-colorscheme-{})".format(var_name), color.css_hex)
    output.write(src_css)


class ThemeGeneratorLua(ThemeGenerator):
  def file_name(self) -> str:
    return "colorscheme.lua"

  def generate(self, theme: Theme, output: TextIO) -> None:
    output.write("local theme = {}\n")
    output.write("theme.base16_name = {}\n".format(json.dumps(theme.base16_name)))
    output.write("theme.is_dark = {}\n".format("true" if theme.is_dark else "false"))
    output.write(
      "---@type table<integer, { gui: integer, cterm: integer, r: integer, g: integer, b: integer }>\n"
    )
    output.write("local colors = {\n")
    for index, (gui_color, cterm_color) in enumerate(
      zip(theme.base16_colors, BASE16_TO_ANSI_MAPPING)
    ):
      output.write(
        "  [{:2}] = {{ gui = 0x{:06x}, cterm = {:2}, r = 0x{:02x}, g = 0x{:02x}, b = 0x{:02x} }},\n".format(
          index, gui_color.rgb888, cterm_color, gui_color.r, gui_color.g, gui_color.b
        ),
      )
    output.write("}\n")
    output.write("theme.base16_colors = colors\n")
    output.write("theme.ansi_colors = {\n")
    for i in ANSI_TO_BASE16_MAPPING:
      output.write("  colors[{}],\n".format(i))
    output.write("}\n")
    output.write("theme.bg = colors[{}]\n".format(BASE16_BG_COLOR_IDX))
    output.write("theme.fg = colors[{}]\n".format(BASE16_FG_COLOR_IDX))
    output.write("theme.cursor_bg = colors[{}]\n".format(BASE16_FG_COLOR_IDX))
    output.write("theme.cursor_fg = colors[{}]\n".format(BASE16_BG_COLOR_IDX))
    output.write("theme.selection_bg = colors[{}]\n".format(BASE16_SELECTION_BG_COLOR_IDX))
    output.write("theme.selection_fg = colors[{}]\n".format(BASE16_FG_COLOR_IDX))
    output.write("theme.link_color = colors[{}]\n".format(BASE16_LINK_COLOR_IDX))
    output.write("---@type table<integer, integer>\n")
    output.write(
      "theme.ansi_to_base16_mapping = {{{}}}\n".format(
        ", ".join("0x{:0X}".format(i) for i in ANSI_TO_BASE16_MAPPING)
      )
    )
    output.write("---@type table<integer, integer>\n")
    output.write(
      "theme.base16_to_ansi_mapping = {{{}}}\n".format(
        ", ".join("0x{:02X}".format(i) for i in BASE16_TO_ANSI_MAPPING)
      )
    )
    output.write("return theme\n")


class ThemeGeneratorAppleTerminal(ThemeGenerator):
  ANSI_COLOR_NAMES = ["Black", "Red", "Green", "Yellow", "Blue", "Magenta", "Cyan", "White"]

  def file_name(self) -> str:
    return "apple-terminal.terminal"

  def is_binary(self) -> bool:
    return True

  def generate(self, theme: Theme, output: BinaryIO) -> None:
    import plistlib

    profile = {
      "ProfileCurrentVersion": 2.07,
      "name": "dotfiles",
      "type": "Window Settings",
      "UseBrightBold": False,
    }

    def write_color(key_name: str, color: Color) -> None:
      float_rgb_str = " ".join("{:.10f}".format(x).rstrip("0").rstrip(".") for x in color.float_rgb)
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
      for color_index, color_name in enumerate(self.ANSI_COLOR_NAMES):
        color = theme.ansi_colors[color_index + int(is_bright) * len(self.ANSI_COLOR_NAMES)]
        write_color("ANSI" + ("Bright" if is_bright else "") + color_name + "Color", color)

    plistlib.dump(profile, output, fmt=plistlib.FMT_XML)


class ThemeGeneratorMintty(ThemeGenerator):
  ANSI_COLOR_NAMES = ["Black", "Red", "Green", "Yellow", "Blue", "Magenta", "Cyan", "White"]

  def file_name(self) -> str:
    return ".minttyrc"

  def generate(self, theme: Theme, output: TextIO) -> None:
    def write_color(name: str, color: Color) -> None:
      output.write(f"{name}={color.r},{color.g},{color.b}\n")

    write_color("BackgroundColour", theme.bg)
    write_color("ForegroundColour", theme.fg)
    write_color("CursorColour", theme.cursor_bg)
    for idx, name in enumerate(self.ANSI_COLOR_NAMES):
      write_color(name, theme.ansi_colors[idx])
      write_color("Bold" + name, theme.ansi_colors[idx + 8])


def main() -> None:
  theme: Theme = IniTheme(os.path.join(__dir__, "data.ini"))
  generators: list[ThemeGenerator] = [
    ThemeGeneratorKitty(),
    ThemeGeneratorTermux(),
    ThemeGeneratorZsh(),
    ThemeGeneratorVim(),
    ThemeGeneratorSetvtrgb(),
    ThemeGeneratorXfceTerminal(),
    ThemeGeneratorVscode(),
    ThemeGeneratorIterm(),
    ThemeGeneratorCssVariables(),
    ThemeGeneratorScss(),
    ThemeGeneratorPrismJs(),
    ThemeGeneratorLua(),
    ThemeGeneratorAppleTerminal(),
    ThemeGeneratorMintty(),
  ]

  out_dir = os.path.join(__dir__, "out")
  os.makedirs(out_dir, exist_ok=True)

  for generator in generators:
    with open(
      os.path.join(out_dir, generator.file_name()), "wb" if generator.is_binary() else "w"
    ) as output_file:
      generator.generate(theme, output_file)


if __name__ == "__main__":
  main()
