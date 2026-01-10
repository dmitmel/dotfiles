#!/usr/bin/env python3
# Inspired by <https://github.com/aarowill/base16-gnome-terminal/blob/d9665597212f96491a728f1627138b81f4c410f6/templates/default.mustache>.
#
# Useful links:
# <https://github.com/GNOME/gnome-terminal/blob/3.41.0/src/org.gnome.Terminal.gschema.xml>
# <https://github.com/GNOME/gnome-terminal/blob/3.41.0/src/terminal-settings-list.cc>
# <https://github.com/GNOME/gnome-terminal/blob/3.41.0/src/terminal-profiles-list.cc>

import os
import uuid

from gi.repository import Gio
from main import IniTheme, Theme

__dir__ = os.path.dirname(__file__)

PROFILES_LIST_SCHEMA_ID = "org.gnome.Terminal.ProfilesList"
PROFILES_SETTINGS_SCHEMA_ID = "org.gnome.Terminal.Legacy.Profile"
NEW_PROFILE_NAME = "dmitmel's dotfiles"


def main() -> None:
  theme: Theme = IniTheme(os.path.join(__dir__, "data.ini"))

  profiles_list = Gio.Settings.new(PROFILES_LIST_SCHEMA_ID)
  profiles_list.delay()

  default_profile_uuid = profiles_list.get_string("default")
  default_profile_path = f"{profiles_list.props.path}:{default_profile_uuid}/"
  default_profile = Gio.Settings.new_with_path(PROFILES_SETTINGS_SCHEMA_ID, default_profile_path)
  default_profile.delay()

  new_profile_uuid = str(uuid.uuid4())
  new_profile_path = f"{profiles_list.props.path}:{new_profile_uuid}/"
  new_profile = Gio.Settings.new_with_path(PROFILES_SETTINGS_SCHEMA_ID, new_profile_path)
  new_profile.delay()

  for k in default_profile.props.settings_schema.list_keys():
    v = default_profile.get_user_value(k)
    if v is not None:
      new_profile.set_value(k, v)

  new_profile.set_string("visible-name", NEW_PROFILE_NAME)
  new_profile.set_boolean("use-theme-colors", False)
  new_profile.set_string("foreground-color", theme.fg.css_hex)
  new_profile.set_string("background-color", theme.bg.css_hex)
  new_profile.set_boolean("bold-color-same-as-fg", True)
  new_profile.set_string("bold-color", theme.fg.css_hex)
  new_profile.set_boolean("cursor-colors-set", True)
  new_profile.set_string("cursor-background-color", theme.cursor_bg.css_hex)
  new_profile.set_string("cursor-foreground-color", theme.cursor_fg.css_hex)
  new_profile.set_boolean("highlight-colors-set", True)
  new_profile.set_string("highlight-background-color", theme.selection_bg.css_hex)
  new_profile.set_string("highlight-foreground-color", theme.selection_fg.css_hex)
  new_profile.set_strv("palette", [color.css_hex for color in theme.ansi_colors[:16]])
  new_profile.set_boolean("bold-is-bright", True)

  # scrollbar_policy_type = (
  #   new_profile.props.settings_schema.get_key("scrollbar-policy").get_range().unpack()
  # )
  new_profile.set_enum("scrollbar-policy", 2)  # never

  profiles_list.set_strv("list", profiles_list.get_strv("list") + [new_profile_uuid])
  profiles_list.set_string("default", new_profile_uuid)

  new_profile.apply()
  profiles_list.apply()

  Gio.Settings.sync()


if __name__ == "__main__":
  main()
