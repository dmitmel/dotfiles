--- The venerable indentLine plugin, but re-implemented in a slightly saner
--- way. Options are compatibile with the original.
---
--- Based on:
--- <https://github.com/bfredl/bfredl.github.io/blob/ed438742f0a1d8a36669bcd4ccb019f5dca9fac2/nvim/lua/bfredl/miniguide.lua>
--- <https://github.com/lukas-reineke/indent-blankline.nvim/blob/0a98fa8dacafe22df0c44658f9de3968dc284d20/lua/indent_blankline/init.lua>
--- <https://github.com/Yggdroot/indentLine/blob/5617a1cf7d315e6e6f84d825c85e3b669d220bfa/after/plugin/indentLine.vim>
local M = require('dotfiles.autoload')('dotfiles.sane_indentline')

local utils = require('dotfiles.utils')

M.ns_id = M.ns_id or vim.api.nvim_create_namespace(M.__module.name)
M.decorations_provider = M.decorations_provider or {}

function M.decorations_provider:reset()
  ---@type string[]
  self.chars = nil
  ---@type number[]
  self.char_widths = nil
  ---@type string
  self.blankline_char = nil
  ---@type string[]
  self.hlgroups = nil
  ---@type string[]
  self.hlgroups_space = nil
  ---@type string[]
  self.hlgroups_space_blankline = nil
  ---@type number
  self.max_indent_level = nil
  ---@type boolean
  self.add_one_more_indent_on_blanklines = nil
  ---@type boolean
  self.show_first_indent_level = nil
  ---@type boolean
  self.disable_with_nolist = nil
  ---@type table<string, boolean>
  self.filetypes_include = nil
  ---@type table<string, boolean>
  self.filetypes_exclude = nil
  ---@type table<string, boolean>
  self.buftype_exclude = nil
  ---@type table<string, boolean>
  self.bufname_exclude = nil
  ---@type table<number, table>
  self.bufs_info = nil
  ---@type table<number, table>
  self.wins_info = nil
end

function M.decorations_provider:on_start(tick)
  self:reset()

  if
    not utils.is_truthy(
      utils.first_non_nil(vim.g.indent_blankline_enabled, vim.g.indentLine_enabled, true)
    )
  then
    return false
  end

  -- stylua: ignore
  self.chars = utils.first_non_nil(vim.g.indent_blankline_char_list, vim.g.indentLine_char_list, {})
  if #self.chars == 0 then
  -- stylua: ignore
    self.chars = {utils.first_non_nil(vim.g.indent_blankline_char, vim.g.indentLine_char, '|')}
  end
  self.char_widths = {}
  for i = 1, #self.chars do
    self.char_widths[i] = vim.fn.strdisplaywidth(self.chars[i])
  end
    -- stylua: ignore
  self.blankline_char = utils.first_non_nil(vim.g.indent_blankline_space_char_blankline, ' ')

    -- stylua: ignore
  self.hlgroups = utils.first_non_nil(vim.g.indent_blankline_char_highlight_list, {})
  if #self.hlgroups == 0 then
    self.hlgroups = { 'IndentBlanklineChar' }
  end
    -- stylua: ignore
  self.hlgroups_space = utils.first_non_nil(vim.g.indent_blankline_space_char_highlight_list, {})
  if #self.hlgroups_space == 0 then
    self.hlgroups_space = { 'IndentBlanklineChar' }
  end
    -- stylua: ignore
  self.hlgroups_space_blankline = utils.first_non_nil(vim.g.indent_blankline_space_char_blankline_highlight_list, {})
  if #self.hlgroups_space_blankline == 0 then
    self.hlgroups_space_blankline = { 'IndentBlanklineSpaceCharBlankline' }
  end

    -- stylua: ignore
  self.max_indent_level = utils.first_non_nil(vim.g.indentLine_indentLevel, vim.g.indent_blankline_indent_level, 20)
    -- stylua: ignore
  self.add_one_more_indent_on_blanklines = utils.is_truthy(utils.first_non_nil(vim.g.indent_blankline_show_trailing_blankline_indent, true))
    -- stylua: ignore
  self.show_first_indent_level = utils.is_truthy(utils.first_non_nil(vim.g.indent_blankline_show_first_indent_level, vim.g.indentLine_showFirstIndentLevel, true))
    -- stylua: ignore
  self.show_on_folded_lines = utils.is_truthy(utils.first_non_nil(vim.g.indent_blankline_show_foldtext, false))

    -- stylua: ignore
  self.disable_with_nolist = utils.is_truthy(utils.first_non_nil(vim.g.indent_blankline_disable_with_nolist, false))
    -- stylua: ignore
  self.filetypes_include = utils.tbl_to_set(utils.first_non_nil(vim.g.indent_blankline_filetype, vim.g.indentLine_fileType, {}))
    -- stylua: ignore
  self.filetypes_exclude = utils.tbl_to_set(utils.first_non_nil(vim.g.indent_blankline_filetype_exclude, vim.g.indentLine_fileTypeExclude, {}))
    -- stylua: ignore
  self.buftype_exclude = utils.tbl_to_set(utils.first_non_nil(vim.g.indent_blankline_buftype_exclude, vim.g.indentLine_bufTypeExclude, {}))
    -- stylua: ignore
  self.bufname_exclude = utils.first_non_nil(vim.g.indent_blankline_bufname_exclude, vim.g.indentLine_bufNameExclude, {})

  self.bufs_info = {}
  self.wins_info = {}
end

-- function M.decorations_provider:on_buf(_, bufnr, tick)
-- end

function M.decorations_provider:on_win(winid, bufnr, topline, botline_guess)
  if self.disable_with_nolist and not vim.wo[winid].list then
    return false
  end

  -- Warning: on_buf is not triggered on every redraw (or at all???), so we
  -- have to perform the buffer checks in on_win.
  local buf_info = self.bufs_info[bufnr]
  if buf_info == nil then
    vim.api.nvim_win_call(winid, function()
      if self:check_disabled_for_buf(winid, bufnr) then
        buf_info = { excluded = true }
      else
        -- Collect buffer info.
        buf_info = {
          excluded = false,
          shiftwidth = vim.fn.shiftwidth(),
        }
      end
      self.bufs_info[bufnr] = buf_info
    end)
  end
  if buf_info.excluded then
    return false
  end

  vim.api.nvim_win_call(winid, function()
    -- Collect window info.
    local win_info = {
      leftcol = vim.fn.winsaveview().leftcol,
      space_char = ' ',
      leading_space_char = ' ',
      trailing_space_char = ' ',
    }

    if vim.wo.list then
      local listchars = vim.opt.listchars:get()
      win_info.space_char = listchars.space or ' '
      win_info.leading_space_char = listchars.lead or win_info.space_char
      win_info.trailing_space_char = listchars.trail or win_info.space_char
    end

    self.wins_info[winid] = win_info
  end)
end

--- Replicates the logic in <https://github.com/Yggdroot/indentLine/blob/5617a1cf7d315e6e6f84d825c85e3b669d220bfa/after/plugin/indentLine.vim#L286-L306>
--- and <https://github.com/lukas-reineke/indent-blankline.nvim/blob/0a98fa8dacafe22df0c44658f9de3968dc284d20/lua/indent_blankline/utils.lua#L50-L101>.
function M.decorations_provider:check_disabled_for_buf(winid, bufnr)
  if
    not utils.is_truthy(
      utils.first_non_nil(vim.b.indent_blankline_enabled, vim.b.indentLine_enabled, true)
    )
  then
    return true
  end
  local ft = vim.bo.filetype
  if self.filetypes_exclude[ft] then
    return true
  end
  if self.buftype_exclude[vim.bo.buftype] then
    return true
  end
  if not vim.tbl_isempty(self.filetypes_include) and not self.filetypes_include[ft] then
    return true
  end
  local bufname = vim.fn.bufname()
  for _, name in ipairs(self.bufname_exclude) do
    -- This check actually has a logic flaw, in that it will always exclude
    -- buffers with empty string as the name. But you know, it is done for
    -- compatibility or whatever, of course.
    if vim.fn.matchstr(bufname, name) == bufname then
      return true
    end
  end
  return false
end

function M.decorations_provider:on_line(winid, bufnr, row)
  local win_info = self.wins_info[winid]
  local buf_info = self.bufs_info[bufnr]

  local shiftwidth = buf_info.shiftwidth
  local indent = 0
  local space_char = win_info.leading_space_char
  local space_hlgroups = self.hlgroups_space
  -- NOTE: nvim_win_call also switches the buffer, and folds are window-local.
  vim.api.nvim_win_call(winid, function()
    if self.show_on_folded_lines or vim.fn.foldclosed(row + 1) < 0 then
      indent = vim.fn.indent(row + 1)
      if indent == 0 then
        indent = math.min(
          vim.fn.indent(vim.fn.prevnonblank(row + 1)),
          vim.fn.indent(vim.fn.nextnonblank(row + 1))
        )
        space_char = self.blankline_char
        space_hlgroups = self.hlgroups_space_blankline
        if self.add_one_more_indent_on_blanklines then
          indent = indent + shiftwidth
        end
      end
    end
  end)

  local chunks = {}
  local left_offset = -win_info.leftcol
  local curr_indent_level = 0
  -- What the hell is up with the logic inside this loop? Anyway, keep these
  -- two things in mind:
  -- 1. Negative left_offset means that the character is off-screen.
  -- 2. We must support indent characters wider than 1 column, but the space
  -- char is assumed to be 1-column wide.
  for _ = 0, indent - shiftwidth, shiftwidth do
    if curr_indent_level >= self.max_indent_level then
      break
    end

    local char = self.chars[curr_indent_level % #self.chars + 1]
    local char_width = self.char_widths[curr_indent_level % #self.char_widths + 1]

    local unrendered_char_cols = 0
    if curr_indent_level > 0 or self.show_first_indent_level then
      if left_offset >= 0 then
        chunks[#chunks + 1] = { char, self.hlgroups[curr_indent_level % #self.hlgroups + 1] }
      else
        unrendered_char_cols = math.max(char_width + left_offset, 0)
      end
    else
      unrendered_char_cols = char_width
    end
    left_offset = left_offset + char_width

    local space_width = math.max(0, shiftwidth - char_width)
    local space = string.rep(
      space_char,
      space_width + unrendered_char_cols + math.min(left_offset, 0)
    )
    if #space > 0 then
      chunks[#chunks + 1] = { space, space_hlgroups[curr_indent_level % #space_hlgroups + 1] }
    end
    left_offset = left_offset + space_width

    curr_indent_level = curr_indent_level + 1
  end

  if #chunks > 0 then
    vim.api.nvim_buf_set_extmark(bufnr, M.ns_id, row, 0, {
      ephemeral = true,
      hl_mode = 'combine',
      virt_text = chunks,
      virt_text_pos = 'overlay',
      -- TODO: Use virt_text_hide when <https://github.com/neovim/neovim/issues/14050>
      -- and <https://github.com/neovim/neovim/issues/14929> are fixed.
      -- virt_text_hide = true,
    })
  end
end

function M.decorations_provider:on_end(tick)
  self:reset()
end

-- stylua: ignore start
vim.api.nvim_set_decoration_provider(M.ns_id, {
  on_start = function(_, ...) return M.decorations_provider:on_start(...) end,
  -- on_buf = function(_, ...) return M.decorations_provider:on_buf(...) end,
  on_win = function(_, ...) return M.decorations_provider:on_win(...) end,
  on_line = function(_, ...) return M.decorations_provider:on_line(...) end,
  on_end = function(_, ...) return M.decorations_provider:on_end(...) end,
})
-- stylua: ignore end

return M
