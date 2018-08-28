items = {
  { text = "clear screen",           keys = {{"ctrl","L"}} },
  { text = "insert mode",            keys = {{"ctrl","X"},{"ctrl","O"}} },
  { text = "undo",                   keys = {{"ctrl","shift", "-"}} },
  -- { text = "redo",                  keys = {{"alt","X"},{"r"},{"e"},{"d"},{"o"},{"return"}} },

  { text = "open command in editor", keys = {{"ctrl","X"},{"ctrl","E"}} },
  { text = "push input",             keys = {{"ctrl","Q"}} },
  { text = "pop input",              keys = {{"alt","G"}} },
  { text = "run buffer and reuse",   keys = {{"alt","G"}} },

  { text = "execute ZLE widget", keys = {{"alt","X"}} },
  { text = "cancel ZLE widget",  keys = {{"ctrl","G"}} },

  { text = "display help for current command", keys = {{"alt","H"}} },
  { text = "locate current command",           keys = {{"alt","shift","?"}} },

  { text = "go to the buffer start",     keys = {{"alt","shift","."}} },
  { text = "go to the buffer end",       keys = {{"alt","shift",","}} },
  { text = "go to the line start",       keys = {{"ctrl","A"}} },
  { text = "go to the line end",         keys = {{"ctrl","E"}} },
  { text = "move one word backward",     keys = {{"alt","B"}} },
  { text = "move one word forward",      keys = {{"alt","F"}} },
  { text = "go to the matching bracket", keys = {{"ctrl","X"},{"ctrl","B"}} },

  { text = "find in previous commands",  keys = {{"ctrl","R"}} },
  { text = "find in following commands", keys = {{"ctrl","S"}} },

  { text = "select",                    keys = {{"ctrl","shift","2"}} },
  { text = "cut word",                  keys = {{"alt","D"}} },
  { text = "go to selection start/end", keys = {{"ctrl","X"},{"ctrl","X"}} },
  { text = "cut selected text",         keys = {{"alt","W"}} },
  { text = "quote selected text",       keys = {{"alt","shift","'"}} },
  { text = "paste copied text",         keys = {{"ctrl","Y"}} },

  { text = "clear buffer", keys = {{"ctrl","X"},{"ctrl","K"}} },
  { text = "delete line",  keys = {{"ctrl","U"}} },
  { text = "delete word",  keys = {{"ctrl","W"}} },

  { text = "join lines", keys = {{"ctrl","X"},{"ctrl","J"}} },

  { text = "tmux: send Ctrl+B",    keys = {{"ctrl","B"},{"ctrl","B"}} },
  { text = "tmux: command prompt", keys = {{"ctrl","B"},{"shift",";"}} },

  { text = "tmux: rename current session", keys = {{"ctrl","B"},{"shift","4"}} },
  { text = "tmux: detach",                 keys = {{"ctrl","B"},{"d"}} },
  { text = "tmux: sessions",               keys = {{"ctrl","B"},{"s"}} },
  { text = "tmux: next session",           keys = {{"ctrl","B"},{")"}} },
  { text = "tmux: previous session",       keys = {{"ctrl","B"},{"("}} },
  { text = "tmux: last session",           keys = {{"ctrl","B"},{"shift","l"}} },

  { text = "tmux: create window",         keys = {{"ctrl","B"},{"c"}} },
  { text = "tmux: switch to window",      keys = {{"ctrl","B"}}, message = "press a number key (0-9)" },
  { text = "tmux: rename current window", keys = {{"ctrl","B"},{","}} },
  { text = "tmux: kill current window",   keys = {{"ctrl","B"},{"shift","7"}} },
  { text = "tmux: windows",               keys = {{"ctrl","B"},{"w"}} },
  { text = "tmux: next window",           keys = {{"ctrl","B"},{"n"}} },
  { text = "tmux: previous window",       keys = {{"ctrl","B"},{"p"}} },
  { text = "tmux: last window",           keys = {{"ctrl","B"},{"l"}} },
  { text = "tmux: find window",           keys = {{"ctrl","B"},{"f"}} },

  { text = "tmux: split vertically",              keys = {{"ctrl","B"},{"shift","'"}} },
  { text = "tmux: split horizontally",            keys = {{"ctrl","B"},{"shift","5"}} },
  { text = "tmux: switch to pane in a direction", keys = {{"ctrl","B"}}, message = "press an arrow key" },
  { text = "tmux: kill current pane",             keys = {{"ctrl","B"},{"x"}} },
  { text = "tmux: next pane",                     keys = {{"ctrl","B"},{"o"}} },
  { text = "tmux: last pane",                     keys = {{"ctrl","B"},{";"}} },
  { text = "tmux: toggle pane zoom",              keys = {{"ctrl","B"},{"z"}} },
  { text = "tmux: change pane layout",            keys = {{"ctrl","B"},{"space"}} },
  { text = "tmux: move pane to a new window",     keys = {{"ctrl","B"},{"shift","1"}} },

  { text = "tmux: copy mode", keys = {{"ctrl","B"},{"["}} },
  { text = "tmux: paste",     keys = {{"ctrl","B"},{"]"}} },
}

chooser = hs.chooser.new(function(item)
  if item then
    if item.message then hs.alert(item.message) end
    for _, key_combo in ipairs(item.keys) do
      hs.eventtap.keyStroke(key_combo.mods, key_combo.key)
    end
  end
end)

chooser:choices(
  hs.fnutils.imap(items, function(item)
    subText = table.concat(hs.fnutils.imap(item.keys, function(key_combo)
      return table.concat(hs.fnutils.imap(key_combo, function(key_stroke)
        return hs.utf8.registeredKeys[key_stroke] or key_stroke
      end))
    end), " ")

    keys = hs.fnutils.imap(item.keys, function(key_combo)
      mods = {}
      for i = 1, #key_combo - 1 do mods[i] = key_combo[i] end
      key = key_combo[#key_combo]
      return { mods = mods, key = key }
    end)

    return {
      text    = item.text,
      subText = subText,
      keys    = keys,
      message = item.message
    }
  end)
)

chooser:rows(9)

hs.hotkey.bind({"cmd", "shift"}, "a", function()
  app = hs.application.frontmostApplication()
  if app:name():lower():match("term") then
    chooser:show()
  end
end)
