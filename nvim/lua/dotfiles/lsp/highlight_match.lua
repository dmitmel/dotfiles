--- Largely a port of `coc#highlight#match_ranges` and friends:
--- <https://github.com/neoclide/coc.nvim/blob/c49acf35d8c32c16e1f14ab056a15308e0751688/autoload/coc/highlight.vim#L341-L468>.
--- How is this better than `nvim_buf_add_highlight` and `vim.region`?
--- Apparently, `matchaddpos` can be displayed over concealed text, which, in
--- my case, means indentation guides.
local M = require('dotfiles.autoload')('dotfiles.lsp.highlight_match')

local utils = require('dotfiles.utils')
local utils_vim = require('dotfiles.utils.vim')
local lsp_utils = require('dotfiles.lsp.utils')

local CAN_ADD_MATCHES_TO_OTHER_WINDOWS = utils_vim.has('nvim-0.4.0')
  or utils_vim.has('patch-8.1.0218')
local CAN_DELETE_MATCHES_FROM_OTHER_WINDOWS = utils_vim.has('nvim-0.5.0')
  or utils_vim.has('patch-8.1.1084')
-- implementation-defined?
-- <https://github.com/neovim/neovim/blob/1c416892879de6b78038f2cc2f1487eff46abb60/src/nvim/buffer_defs.h#L1013-L1014>
-- <https://github.com/vim/vim/blob/53ba05b09075f14227f9be831a22ed16f7cc26b2/src/structs.h#L3298-L3299>
local MAX_MATCHADDPOS_BATCH_SIZE = 8

function M.compute_slices(ranges, bufnr, offset_encoding)
  utils.check_type('ranges', ranges, 'table')
  utils.check_type('bufnr', bufnr, 'number')
  utils.check_type('offset_encoding', offset_encoding, 'string', true)
  offset_encoding = offset_encoding or 'utf-8'

  local buf_line_count = vim.api.nvim_buf_line_count(bufnr)
  assert(buf_line_count > 0, "buffer isn't loaded")

  local slices = {}

  for _, range in ipairs(ranges) do
    local start_line, start_char, end_line, end_char, user_data = utils.unpack5(range)
    assert(
      start_line >= 0 and start_char >= 0 and end_line >= 0 and end_char >= 0,
      'invalid range'
    )
    start_line = utils.clamp(start_line, 0, buf_line_count - 1)
    end_line = utils.clamp(end_line, 0, buf_line_count - 1)
    assert(start_line <= end_line, 'invalid range')
    if start_line == end_line then
      assert(start_char <= end_char, 'invalid range')
    end

    local lines = vim.api.nvim_buf_get_lines(bufnr, start_line, end_line + 1, true)
    for linenr = start_line, end_line do
      local line = lines[linenr - start_line + 1]
      assert(line ~= nil)
      -- One byte past the line is added to account for the case when the user
      -- (i.e. me) has `listchars` enabled for newlines (i.e. always).
      local slice_start, slice_end = 0, #line + 1
      if linenr == start_line then
        slice_start = lsp_utils.char_offset_to_byte_offset(start_char, line, offset_encoding)
      end
      if linenr == end_line then
        slice_end = lsp_utils.char_offset_to_byte_offset(end_char, line, offset_encoding)
      end
      if slice_end > slice_start then
        table.insert(slices, { linenr + 1, slice_start + 1, slice_end - slice_start, user_data })
      end
    end
  end

  return slices
end

-- Re-implementation of `coc#highlight#match_ranges`.
function M.add_ranges(winid, ranges, hlgroup, priority, offset_encoding)
  utils.check_type('winid', winid, 'number')
  utils.check_type('ranges', ranges, 'table')
  utils.check_type('hlgroup', hlgroup, 'string')
  utils.check_type('priority', priority, 'number')

  winid = utils_vim.normalize_winid(winid)
  local slices = M.compute_slices(ranges, vim.api.nvim_win_get_buf(winid), offset_encoding)

  local slices_len = #slices
  local match_ids = {}
  if slices_len > 0 then
    local function do_the_job()
      for i = 1, slices_len, MAX_MATCHADDPOS_BATCH_SIZE do
        local batch = {}
        for j = 1, math.min(MAX_MATCHADDPOS_BATCH_SIZE, slices_len - (i - 1)) do
          batch[j] = slices[(i - 1) + j]
        end
        local match_id
        if CAN_ADD_MATCHES_TO_OTHER_WINDOWS then
          match_id = vim.call('matchaddpos', hlgroup, batch, priority, -1, { window = winid })
        else
          match_id = vim.call('matchaddpos', hlgroup, batch, priority, -1)
        end
        table.insert(match_ids, match_id)
      end
    end

    if CAN_ADD_MATCHES_TO_OTHER_WINDOWS then
      do_the_job()
    else
      vim.api.nvim_win_call(winid, do_the_job)
    end
  end

  return match_ids
end

-- Re-implementation of `coc#highlight#clear_match_group`.
function M.clear_by_predicate(winid, predicate)
  utils.check_type('winid', winid, 'number')
  utils.check_type('predicate', predicate, 'function')

  if winid == 0 then
    winid = vim.api.nvim_get_current_win()
  end
  local _ = vim.api.nvim_win_get_buf(winid)

  if CAN_DELETE_MATCHES_FROM_OTHER_WINDOWS then
    for _, match in ipairs(vim.call('getmatches', winid)) do
      if predicate(match, winid) then
        vim.call('matchdelete', match.id, winid)
      end
    end
  else
    vim.api.nvim_win_call(winid, function()
      for _, match in ipairs(vim.call('getmatches')) do
        if predicate(match, winid) then
          vim.call('matchdelete', match.id)
        end
      end
    end)
  end
end

-- Re-implementation of `coc#highlight#clear_matches`.
function M.clear_by_ids(winid, match_ids)
  utils.check_type('winid', winid, 'number')
  utils.check_type('match_ids', match_ids, 'table')

  if winid == 0 then
    winid = vim.api.nvim_get_current_win()
  end
  local _ = vim.api.nvim_win_get_buf(winid)

  if vim.tbl_isempty(match_ids) then
    return
  end

  if CAN_DELETE_MATCHES_FROM_OTHER_WINDOWS then
    for _, match_id in ipairs(match_ids) do
      vim.call('matchdelete', match_id, winid)
    end
  else
    vim.api.nvim_win_call(winid, function()
      for _, match_id in ipairs(match_ids) do
        vim.call('matchdelete', match_id)
      end
    end)
  end
end

return M
