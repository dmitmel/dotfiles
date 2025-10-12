--- My very own blink.cmp source for completing Vim options within modelines!
---@class dotfiles.blink_cmp_modelines : blink.cmp.Source
local source = require('dotfiles.autoload')('dotfiles.blink_cmp_modelines', {})
source.__index = source

function source.new(opts)
  local self = setmetatable({}, source)
  self.opts = opts
  return self
end

---@return boolean
function source:enabled()
  return (vim.bo.modeline and vim.o.modelines > 0)
    or (vim.fn.exists('#SecureModeLines') ~= 0 and vim.fn.exists('b:disable_secure_modelines') == 0)
end

---@return string[]
function source:get_trigger_characters()
  return {
    ':', -- The start of the modeline, also can be used as the separator between options
    ' ', -- Separator between options (doesn't seem to work as a trigger)
    '=', -- Included to trigger the completion menu when starting to type the option value
    ',', -- Also trigger the menu for every value in options with multiple values
  }
end

---@param context blink.cmp.Context
---@param callback fun(response: blink.cmp.CompletionResponse | nil)
function source:get_completions(context, callback)
  -- Don't run in the terminal or on the command line
  if context.mode ~= 'default' then return callback(nil) end

  local modeline = self:parse_modeline_under_cursor(context)
  if not modeline then return callback(nil) end

  local LSP = vim.lsp.protocol

  ---@type lsp.CompletionItem[]
  local items = {}

  -- Using the built-in |getcompletion()| function does have a lot of
  -- limitations, such as completing the option names incorrectly after `no` or
  -- `inv` is typed, or processing |wildcard| characters and backslashes instead
  -- of treating them literally, and in general not giving much information to
  -- work with beyond just a list of strings (without any descriptions, types or
  -- anything like that), but it does most of the heavy lifting of parsing the
  -- |:set| command for us. Also, did you know that there exists an old syntax
  -- to set the options with `:set name:value` instead of `:set name=value`?
  for i, completion in
    ipairs(vim.fn.getcompletion('set ' .. modeline.options_before_cursor, 'cmdline'))
  do
    items[i] = {
      label = completion,
      kind = LSP.CompletionItemKind.Property,
      sortText = completion,
    }
  end

  -- Check if the literal `set` command was not given, and that we are
  -- completing the first word after the modeline marker.
  if modeline.set_cmd == nil and modeline.options_before_cursor:match('^[\t ]*%w*$') then
    items[#items + 1] = {
      label = 'set',
      kind = LSP.CompletionItemKind.Snippet,
      insertText = (modeline.options_before_cursor == '' and ' ' or '') .. 'set $0 :',
      insertTextFormat = LSP.InsertTextFormat.Snippet,
      sortText = '_set',
    }
  end

  callback({
    items = items,
    -- This is a bit wasteful, since it makes blink.cmp call |getcompletion()|
    -- on every typed character, but it is required to get accurate results.
    is_incomplete_backward = true,
    is_incomplete_forward = true,
  })
end

local MODELINE_BEGINNING_REGEX =
  vim.regex([[\%(\S\@1<!\%(vi:\|[Vv]im[<>=]\?[0-9]*:\)\|\s\@1<=ex:\)]])

--- Parser for the syntax of modelines described in `:help modeline`. See also
--- <https://github.com/neovim/neovim/blob/v0.11.4/src/nvim/buffer.c#L3756> and
--- <https://github.com/ciaranm/securemodelines/blob/9751f29699186a47743ff6c06e689f483058d77a/plugin/securemodelines.vim>.
---@param ctx blink.cmp.Context
function source:parse_modeline_under_cursor(ctx)
  local linenr, colnr = ctx.cursor[1], ctx.cursor[2]

  local modelines_limit = vim.g.secure_modelines_modelines or vim.o.modelines
  local buf_lines = vim.api.nvim_buf_line_count(ctx.bufnr)
  if not (linenr <= modelines_limit or linenr > buf_lines - modelines_limit) then return nil end
  local line = vim.api.nvim_buf_get_lines(ctx.bufnr, linenr - 1, linenr, true)[1]

  local offset = 0
  while offset < #line do
    -- The `match_str()` method does not allow setting the start offset, while
    -- `match_line()` does. Also, the returned indexes are 0-based and are
    -- relative to this offset. Who designed the API for `vim.regex`???
    local marker_start, marker_end =
      MODELINE_BEGINNING_REGEX:match_line(ctx.bufnr, linenr - 1, offset)
    if not (marker_start and marker_end) then return nil end
    marker_start = offset + marker_start + 1
    marker_end = offset + marker_end
    offset = marker_end + 1

    if colnr < marker_end then return nil end

    local marker = line:sub(marker_start, marker_end)
    local options_start = marker_end + 1
    local _set_cmd_start, set_cmd_end, set_cmd = line:find('^[\t ]*(set?) ', options_start)
    if set_cmd_end then options_start = set_cmd_end + 1 end

    -- Modelines starting with `Vim:` must be followed by an explicit `set` command.
    if marker:sub(1, 1) == 'V' and set_cmd ~= 'set' then goto continue end

    local options_end = (set_cmd and line:find('[^\\]:', options_start - 1) or nil) or #line
    offset = options_end + 1

    if colnr <= options_end then
      return {
        marker_start = marker_start,
        marker_end = marker_end,
        marker = marker,
        set_cmd = set_cmd,
        options_start = options_start,
        options_end = options_end,
        options_before_cursor = self:unescape_colons_in_modeline(
          line:sub(options_start, math.min(colnr, options_end))
        ),
      }
    end

    ::continue::
  end
end

---@param str string
function source:unescape_colons_in_modeline(str)
  local unescaped = {}

  local i = 0
  while true do
    local colon = str:find(':', i, true)
    if not colon then
      table.insert(unescaped, str:sub(i, -1))
      break
    elseif str:sub(colon - 1, colon - 1) == '\\' then
      table.insert(unescaped, str:sub(i, colon - 2))
      table.insert(unescaped, ':')
    else
      table.insert(unescaped, str:sub(i, colon - 1))
      table.insert(unescaped, ' ')
    end
    i = colon + 1
  end

  return table.concat(unescaped)
end

return source
