local utils = require('dotfiles.utils')
local treesitter = require('vim.treesitter')

treesitter._old_start = treesitter._old_start or treesitter.start
---@param bufnr integer?
---@param lang string?
function treesitter.start(bufnr, lang) ---@diagnostic disable-line: duplicate-set-field
  if utils.is_truthy(vim.g.dotfiles_treesitter_highlighter_enabled) then
    return treesitter._old_start(bufnr, lang)
  else
    local bo = vim.bo[bufnr or 0]
    if bo.filetype == '' or bo.filetype == 'snacks_picker_preview' then
      -- This is designed to throw off checks like this:
      -- <https://github.com/folke/snacks.nvim/blob/bc0630e43be5699bb94dadc302c0d21615421d93/lua/snacks/picker/core/preview.lua#L281>
      error('the filetype has not been decided yet')
    end
    bo.syntax = 'on'
  end
end
