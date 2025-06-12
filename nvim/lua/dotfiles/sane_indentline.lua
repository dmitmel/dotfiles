--- Over time this plugin of mine got further and further from sanity, but I've
--- done my best to squeeze every last drop of performance out of it.
---
--- Based on:
--- <https://github.com/bfredl/bfredl.github.io/blob/ed438742f0a1d8a36669bcd4ccb019f5dca9fac2/nvim/lua/bfredl/miniguide.lua>
--- <https://github.com/lukas-reineke/indent-blankline.nvim/blob/0a98fa8dacafe22df0c44658f9de3968dc284d20/lua/indent_blankline/init.lua>
--- <https://github.com/Yggdroot/indentLine/blob/5617a1cf7d315e6e6f84d825c85e3b669d220bfa/after/plugin/indentLine.vim>
---
--- TODO: remove compat with Yggdroot/indentLine and lukas-reineke/indent-blankline.nvim
local self, module = require('dotfiles.autoload')('dotfiles.sane_indentline', {})

local utils = require('dotfiles.utils')

self.ns_id = vim.api.nvim_create_namespace(module.name)

self.scope_data = nil ---@type dotfiles.sane_indentline.scope_data

---@type table<integer, dotfiles.sane_indentline.win_info>
self.wins_info = self.wins_info or {}

---@type vim.api.keyset.set_decoration_provider
self.decoration_provider = self.decoration_provider or {}

---@generic T
---@param ibl_name string
---@param il_name? string
---@param default T
---@param dict? vim.var_accessor
---@return T
function self.get_option_from_vim(ibl_name, il_name, default, dict)
  dict = dict or vim.g
  local ibl_opt = dict['indent_blankline_' .. ibl_name]
  if ibl_opt ~= nil then return ibl_opt end
  if il_name then
    local il_opt = dict['indentLine_' .. il_name]
    if il_opt ~= nil then return il_opt end
  end
  return default
end

-- |strdisplaywidth()| takes too much time to keep constantly invoking it! I am
-- also use it instead of |nvim_strwidth()| because it gives the closest results
-- to how the characters will actually be rendered, taking into account the
-- values of `tabstop` for <Tab>s, `display` for unprintable ones and so on.
local cached_string_widths = {} ---@type table<string, integer>
local function get_str_display_width(str) ---@param str string
  local width = cached_string_widths[str] or vim.fn.strdisplaywidth(str)
  cached_string_widths[str] = width
  return width
end

function self.decoration_provider.on_start(_, tick)
  ---@type integer
  self.last_redraw_tick = tick

  ---@type table<integer, boolean>
  self.bufs_excluded = {}

  local visible_wins = utils.list_to_set(vim.api.nvim_tabpage_list_wins(0))
  for winid in pairs(self.wins_info) do
    -- Sweep the cache from time to time.
    if not visible_wins[winid] then self.wins_info[winid] = nil end
  end

  local opt = self.get_option_from_vim
  if not utils.is_truthy(opt('enabled', 'enabled', true)) then return false end

  ---@type string[]
  self.chars = opt('char_list', 'char_list', {})
  if #self.chars == 0 then self.chars = { opt('char', 'char', '|') } end
  ---@type integer[]
  self.char_widths = {}
  for i, str in ipairs(self.chars) do
    self.char_widths[i] = get_str_display_width(str)
  end

  ---@type string
  self.blankline_char = opt('space_char_blankline', nil, ' ')
  if get_str_display_width(self.blankline_char) ~= 1 then self.blankline_char = ' ' end

  ---@type string[]
  self.hlgroups = opt('char_highlight_list', nil, {})
  if #self.hlgroups == 0 then self.hlgroups = { 'IblIndent' } end
  ---@type string[]
  self.hlgroups_space = opt('space_char_highlight_list', nil, {})
  if #self.hlgroups_space == 0 then self.hlgroups_space = { 'IblWhitespace' } end
  ---@type string[]
  self.hlgroups_blankline_space = opt('space_char_blankline_highlight_list', nil, {})
  if #self.hlgroups_blankline_space == 0 then
    self.hlgroups_blankline_space = { 'IblWhitespace' }
  end
  ---@type string[]
  self.hlgroups_scope = opt('context_highlight_list', nil, {})
  if #self.hlgroups_scope == 0 then self.hlgroups_scope = { 'IblScope' } end

  ---@type integer
  self.max_indent_level = opt('indentLevel', 'indent_level', 20)
  self.add_one_more_indent_on_blanklines =
    utils.is_truthy(opt('show_trailing_blankline_indent', nil, true))
  self.show_first_indent_level =
    utils.is_truthy(opt('show_first_indent_level', 'showFirstIndentLevel', true))
  self.show_on_folded_lines = utils.is_truthy(opt('show_foldtext', nil, false))
  self.show_scope = utils.is_truthy(opt('show_current_context', nil, false))

  local to_set = utils.list_to_set
  self.disable_with_nolist = utils.is_truthy(opt('disable_with_nolist', nil, false))
  ---@type table<string, boolean>
  self.filetypes_include = to_set(opt('filetype', 'fileType', {}))
  ---@type table<string, boolean>
  self.filetypes_exclude = to_set(opt('filetype_exclude', 'fileTypeExclude', {}))
  ---@type table<string, boolean>
  self.buftype_exclude = to_set(opt('buftype_exclude', 'bufTypeExclude', {}))
  ---@type string[]
  self.bufname_exclude = opt('bufname_exclude', 'bufNameExclude', {})
end

-- <https://github.com/neovim/neovim/pull/26833>
-- <https://github.com/neovim/neovim/commit/dc48a98f9ac614dc94739637c967aa29e064807e>
-- <https://github.com/neovim/neovim/commit/444f37fe510f4c28c59bade40d7ba152a5ee8f7c>
local has_correct_botrow_reporting = utils.has('nvim-0.10.0')

function self.decoration_provider.on_win(_, winid, bufnr, toprow, botrow)
  -- Check if we've already encountered this buffer and explicitly rejected it.
  if self.bufs_excluded[bufnr] then return false end
  if self.disable_with_nolist and not vim.wo[winid].list then return false end
  local current_win = vim.api.nvim_get_current_win()

  -- A little thing I've discovered: |nvim_win_call()| and |nvim_buf_call()|
  -- return the value that was returned by the callback. Nice!
  return vim.api.nvim_win_call(winid, function()
    if self.bufs_excluded[bufnr] == nil then
      -- It's the first time we've seen this buffer, so we don't know whether
      -- indentlines should be enabled or not. Also, `on_buf` is not triggered
      -- on every redraw (or at all???), so buffer checks have to be performed
      -- in `on_win`.
      if not self.is_enabled_for_current_buf() then
        self.bufs_excluded[bufnr] = true
        self.wins_info[winid] = nil
        return false
      else
        self.bufs_excluded[bufnr] = false
      end
    end

    -- NOTE: The range represented by `toprow` and `botrow` (end-inclusive and
    -- zero-indexed) corresponds to the window's entire viewport (the first and
    -- last visible lines), and not the region that will be redrawn. The
    -- information in `botrow` used to be unreliable though, which was fixed by
    -- <https://github.com/neovim/neovim/pull/26833#issuecomment-1873869653>.
    -- NOTE: Additionally, the value for `botrow` is obtained the same way as
    -- `botline` in the dictionary returned by `getwininfo()`, which actually is
    -- the last **completely displayed** line (as opposed to a wrapped line that
    -- does not fit into the window and continues in the off-screen area).
    -- Therefore, `botrow + 1` would be either the last partially visible line,
    -- or, when the last line is fully visible, the line number just below it.
    local botline = has_correct_botrow_reporting and botrow
      or vim.api.nvim_eval('getwininfo(' .. winid .. ')[0].botline')
    local topline = toprow + 1

    self.update_win_info(winid, bufnr, topline, botline)
    if winid == current_win then self.update_scope(winid) end
  end)
end

--- Replicates the logic of <https://github.com/Yggdroot/indentLine/blob/5617a1cf7d315e6e6f84d825c85e3b669d220bfa/after/plugin/indentLine.vim#L286-L306>
--- and <https://github.com/lukas-reineke/indent-blankline.nvim/blob/0a98fa8dacafe22df0c44658f9de3968dc284d20/lua/indent_blankline/utils.lua#L50-L101>.
function self.is_enabled_for_current_buf()
  if not utils.is_truthy(self.get_option_from_vim('enabled', 'enabled', true, vim.b)) then
    return false
  end

  local ft = vim.bo.filetype
  if self.filetypes_exclude[ft] then return false end
  if self.buftype_exclude[vim.bo.buftype] then return false end
  if #self.filetypes_include > 0 and not self.filetypes_include[ft] then return false end

  local bufname = vim.fn.bufname()
  for _, name in ipairs(self.bufname_exclude) do
    -- This check actually has a logical flaw: it will exclude buffers with an
    -- empty name. But I'm leaving it this way for bug-to-bug compatibility.
    if vim.fn.matchstr(bufname, name) == bufname then return false end
  end

  return true
end

---@param winid integer
---@param bufnr integer
---@param topline integer
---@param botline integer
function self.update_win_info(winid, bufnr, topline, botline)
  ---@class dotfiles.sane_indentline.win_info
  local info = self.wins_info[winid] or {}

  info.last_redraw_tick = self.last_redraw_tick
  info.winid = winid
  info.bufnr = bufnr
  info.topline = topline
  info.botline = botline
  info.height = vim.fn.winheight(winid)
  info.view = vim.fn.winsaveview()

  info.shiftwidth = vim.fn.shiftwidth()
  info.breakindent = vim.wo.breakindent
  info.list = vim.wo.list
  -- `vim.wo.listchars` does not work here for some reason in Neovim versions
  -- before 0.7.0. But I think in the context of reading the value of a
  -- |global-local| option `vim.o.listchars` behaves the same?
  info.listchars = info.list and self.parse_listchars(vim.o.listchars) or {}
  -- This is a tough one. Neovim offers no API for interacting with folds other
  -- than querying lines one by one with `foldclosed()` to see if the line is in
  -- a fold or not. However, since folds have to contain at least two lines, I
  -- think this is a reasonable shortcut: basically, if the range of lines
  -- displayed in the window is the same as its height, we can be sure that no
  -- lines have been folded, and no folds are visible on the screen right now.
  -- NOTE: Keep an eye on this: <https://github.com/neovim/neovim/issues/19226>.
  info.no_folds = botline - topline + 1 == info.height

  self.wins_info[winid] = info
end

--- This is actually one of the few places where my militant autism has helped.
--- `vim.opt_local.listchars:get()` is super slow and consumes a noticeable
--- amount of time in `self.update_win_info`, mainly due to usage of `vim.split`
--- and `vim.validate`. Well, I believe that the `vim.opt(_local)` interface
--- simply was not intended to be super performant. Instead, I'll go by the
--- logic of the real C code that handles this option,
--- <https://github.com/neovim/neovim/blob/v0.11.1/src/nvim/optionstr.c#L2152-L2372>,
--- and assume that the string in of `vim.wo.listchars` is already well-formed.
---@param str string
function self.parse_listchars(str)
  local result = {} ---@type table<string, string>
  local pos = 1
  while pos <= #str do
    local colon = str:find(':', pos)
    if not colon then break end
    local comma = str:find(',', colon + 2) or (#str + 1)
    result[str:sub(pos, colon - 1)] = str:sub(colon + 1, comma - 1)
    pos = comma + 1
  end
  return result
end

---@param winid integer
---@param first integer
---@param last integer
---@type fun(winid: integer, first: integer, last: integer)
function self.redraw_range(winid, first, last)
  -- Nicely borrowed from <https://github.com/folke/snacks.nvim/blob/bc0630e43be5699bb94dadc302c0d21615421d93/lua/snacks/util/init.lua#L200-L211>
  vim.api.nvim__redraw({ win = winid, range = { first - 1, last }, valid = true, flush = false })
end

if vim.api.nvim__redraw == nil then
  self.redraw_range = utils.schedule_once_per_frame(function() vim.cmd('redraw!') end)
end

---@param line integer
---@return integer
function self.get_line_indent(line)
  local level = vim.fn.indent(line)
  -- This is not *strictly* necessary, but exists to catch bugs that would
  -- otherwise slip through the cracks.
  assert(level >= 0)
  return level
end

---@param line integer
---@return integer indent
---@return boolean is_blank
function self.get_blankline_indent(line)
  local indent = self.get_line_indent(line)
  local next_nb = vim.fn.nextnonblank(line)
  if line == next_nb then
    return indent, false
  else
    local prev_nb = vim.fn.prevnonblank(line)
    local prev_indent = prev_nb > 0 and self.get_line_indent(prev_nb) or 0
    local next_indent = next_nb > 0 and self.get_line_indent(next_nb) or 0
    return math.min(prev_indent, next_indent), true
  end
end

---@param winid integer
function self.update_scope(winid)
  if not self.show_scope then
    self.scope_data = nil
    return
  end

  local win_info = self.wins_info[winid]
  local cursor_line = win_info.view.lnum
  local indent = self.get_blankline_indent(cursor_line)
  local level = math.floor((indent - 1) / win_info.shiftwidth)

  if self.is_in_scope(winid, win_info.bufnr, cursor_line, level) then
    self.scope_data.first_line = self.expand_scope(level, self.scope_data.first_line, true)
    self.scope_data.last_line = self.expand_scope(level, self.scope_data.last_line, false)
    return
  end

  ---@class dotfiles.sane_indentline.scope_data
  local new_scope = {
    winid = winid,
    bufnr = win_info.bufnr,
    level = level,
    first_line = self.expand_scope(level, cursor_line, true),
    last_line = self.expand_scope(level, cursor_line, false),
  }

  local old_scope = self.scope_data
  self.scope_data = new_scope

  if old_scope ~= nil and vim.api.nvim_win_is_valid(old_scope.winid) then
    self.redraw_range(old_scope.winid, old_scope.first_line, old_scope.last_line)
  end
  self.redraw_range(winid, new_scope.first_line, new_scope.last_line)
end

---@param winid integer
---@param bufnr integer
---@param line integer
---@param indent_level integer
---@return boolean
function self.is_in_scope(winid, bufnr, line, indent_level)
  local scope = self.scope_data
  return scope ~= nil
    and (scope.winid == winid and scope.bufnr == bufnr and scope.level == indent_level)
    and (scope.first_line <= line and line <= scope.last_line)
end

---@param scope_level integer
---@param line integer
---@param up boolean
---@return integer
function self.expand_scope(scope_level, line, up)
  local win_info = self.wins_info[vim.api.nvim_get_current_win()]
  local step = up and -1 or 1

  -- Expand the search radius by one line up and down. This is necessary to draw
  -- the scope correctly when the last line is only partially displayed (due to
  -- wrapping), but also helps with performance when scrolling the buffer by
  -- holding j/l or <C-u>/<C-d>.
  local min_line = math.max(1, win_info.topline - 1)
  local max_line = math.min(win_info.botline + 1, vim.api.nvim_buf_line_count(0))

  while true do
    if not win_info.no_folds then
      -- This is a very generous assumption, but let's presume that all lines
      -- within the folded region are indented at the same level or more. Which
      -- is a good assumption nonetheless, in 99% of cases we will encounter
      -- folds that align with block constructs, and in virtually all
      -- programming languages blocks are indented deeper than the wrapping
      -- construct. But what about the remaining 1%? Let's say, hypothetically,
      -- the programmer has written a multi-line string or a heredoc, that has
      -- to be aligned to the first column, and this construct sits in a fold --
      -- the detected scope size will change depending on whether the fold is
      -- open or closed. But oh well, tough shit, better than parsing
      -- potentially hundreds of lines enclosed within the fold.
      local fold_start_line = vim.fn.foldclosed(line)
      if fold_start_line > 0 then
        -- The start of the fold will be used to estimate its indentation level,
        -- for two reasons: 1) the first line of the fold is what is displayed on
        -- the screen; 2) in languages like Python the start of the block is more
        -- indented than the end.
        line = up and fold_start_line or vim.fn.foldclosedend(line)
      end
    end

    line = line + step
    if line < min_line or line > max_line then
      return up and min_line or max_line -- reached the top or the bottom of the buffer
    end

    local indent = self.get_blankline_indent(line)
    local level = math.floor((indent - 1) / win_info.shiftwidth)
    if level < scope_level then
      return line - step -- reached the end of the indented block
    end
  end
end

---@type vim.api.keyset.set_extmark
local reusable_extmark = {
  ephemeral = true,
  hl_mode = 'combine',
  virt_text = { { '', '' } },
  virt_text_win_col = -1,
}

---@type vim.api.keyset.set_extmark
local reusable_spaces_extmark = {
  ephemeral = true,
  hl_group = '',
  end_col = -1,
}

-- <https://github.com/neovim/neovim/commit/bbd5c6363c25e8fbbfb962f8f6c5ea1800d431ca>
local has_virt_text_repeat_linebreak = utils.has('nvim-0.10.0')
-- <https://github.com/neovim/neovim/commit/245ac6f263b6017c050f885212ee80e5738d3b9f>
local has_virtcol2col = utils.exists('*virtcol2col')

function self.decoration_provider.on_line(_, winid, bufnr, row)
  local info = self.wins_info[winid]
  local line = row + 1
  local shiftwidth = info.shiftwidth

  local indent, blank_line = -1, false
  -- NOTE: Folds are window-local, so we need to switch to the respective window
  -- to check them. |nvim_win_call()| also switches the current buffer.
  vim.api.nvim_win_call(winid, function()
    if info.no_folds or self.show_on_folded_lines or vim.fn.foldclosed(line) < 0 then
      indent, blank_line = self.get_blankline_indent(line)
    end
  end)

  if indent < 0 then
    return -- The line is invalid, don't draw anything on it.
  elseif blank_line and self.add_one_more_indent_on_blanklines then
    indent = indent + 1
  end

  if has_virt_text_repeat_linebreak then
    -- See the comment about reusing extmark objects below.
    reusable_extmark.virt_text_repeat_linebreak = info.breakindent
  end

  local col = info.view.leftcol
    + ((info.list and info.listchars.precedes ~= nil and info.view.leftcol > 0) and 1 or 0)
    + ((not self.show_first_indent_level) and 1 or 0)

  local max_col = math.min(indent, self.max_indent_level * shiftwidth)
  while col < max_col do
    local level = math.floor(col / shiftwidth)

    if col % shiftwidth == 0 then
      -- Instead of spamming extmark tables on every invocation of `on_line`, I
      -- will keep just one table around and modify it, this should help reduce
      -- the pressure on the garbage collector. Also, note that Nvim will
      -- interleave the calls to `on_line` when rendering multiple windows, so
      -- the extmark object must be prepared within `on_line` and used only for
      -- the duration of this event handler!
      local extmark_chunk = reusable_extmark.virt_text[1]
      extmark_chunk[1] = self.chars[level % #self.chars + 1]
      extmark_chunk[2] = self.hlgroups[level % #self.hlgroups + 1]
      if self.show_scope and self.is_in_scope(winid, bufnr, line, level) then
        extmark_chunk[2] = self.hlgroups_scope[level % #self.hlgroups_scope + 1]
      end
      reusable_extmark.virt_text_win_col = level * shiftwidth - info.view.leftcol
      vim.api.nvim_buf_set_extmark(bufnr, self.ns_id, row, 0, reusable_extmark)
      col = col + self.char_widths[level % #self.char_widths + 1]
    end

    local alignment = -col % shiftwidth -- <https://stackoverflow.com/a/57426670>
    local next_col = math.min(col + alignment, max_col)

    -- This is a crude hack that does not render spaces on blank lines, probably
    -- breaks when you mix tabs and spaces, and does not work correctly when
    -- `breakindent` is enabled, but it's a start. Properly adding hlgroups to
    -- spaces in between the indentation guides requires using virtual text
    -- extmarks, but virtual texts cannot act as a highlight-only overlay, I
    -- have to add some characters that will be necessarily drawn over what Vim
    -- renders, so then I'd have to do a lot of wheel reinventing, such as for
    -- displaying `listchars`.
    if has_virtcol2col then
      -- A complex dance right here to convert between 0- and 1-based indexes.
      local start_col = vim.fn.virtcol2col(winid, line, col + 1) - 1
      local end_col = vim.fn.virtcol2col(winid, line, next_col + 1) - 1
      if 0 <= start_col and start_col < end_col then
        local space_hlgroups = blank_line and self.hlgroups_blankline_space or self.hlgroups_space
        reusable_spaces_extmark.hl_group = space_hlgroups[level % #space_hlgroups + 1]
        reusable_spaces_extmark.end_col = end_col
        vim.api.nvim_buf_set_extmark(bufnr, self.ns_id, row, start_col, reusable_spaces_extmark)
      end
    end

    col = next_col
  end
end

function self.decoration_provider.on_end(_, tick) end

function self.setup()
  vim.api.nvim_set_decoration_provider(self.ns_id, {
    on_start = function(...) return self.decoration_provider.on_start(...) end,
    on_win = function(...) return self.decoration_provider.on_win(...) end,
    on_line = function(...) return self.decoration_provider.on_line(...) end,
    on_end = function(...) return self.decoration_provider.on_end(...) end,
  })

  vim.cmd('hi def link IblIndent Whitespace')
  vim.cmd('hi def link IblWhitespace Whitespace')
  vim.cmd('hi def link IblScope LineNr')
end

return self
