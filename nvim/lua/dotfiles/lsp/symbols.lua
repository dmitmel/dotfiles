--- See also:
--- <https://github.com/simrat39/symbols-outline.nvim>
--- <https://github.com/liuchengxu/vista.vim>
local M = require('dotfiles.autoload')('dotfiles.lsp.symbols')

local lsp = require('vim.lsp')
local lsp_utils = require('dotfiles.lsp.utils')
local lsp_global_settings = require('dotfiles.lsp.global_settings')
local vim_uri = require('vim.uri')
local utils = require('dotfiles.utils')
local lsp_progress = require('dotfiles.lsp.progress')


function M.request_document_symbols()
  local req_params = {
    textDocument = lsp.util.make_text_document_params(),
    workDoneToken = lsp_progress.random_token(),
  }
  local file_path = vim.fn.expand('%:.')
  return lsp.buf_request(
    0, 'textDocument/documentSymbol', req_params,
    lsp_utils.wrap_handler_compat(function(err, params, ctx, opts)
      ctx.source_file_path = file_path
      return M.handler(err, params, ctx, opts)
    end)
  )
end
lsp.buf.document_symbol = M.request_document_symbols


function M.request_workspace_symbols(query)
  vim.validate({
    query = {query, 'string'};
  })
  local req_params = {
    query = query,
    workDoneToken = lsp_progress.random_token(),
  }
  return lsp.buf_request(
    0, 'workspace/symbol', req_params,
    lsp_utils.wrap_handler_compat(function(err, params, ctx, opts)
      ctx.source_query = query
      return M.handler(err, params, ctx, opts)
    end)
  )
end
lsp.buf.workspace_symbol = M.request_workspace_symbols


function M.handler(err, params, ctx, opts)
  if err then
    lsp_utils.client_notify(ctx.client_id, err, vim.log.levels.ERROR)
    return
  end
  if not params or vim.tbl_isempty(params) then
    lsp_utils.client_notify(ctx.client_id, 'no symbols found', vim.log.levels.WARN)
    return
  end
  opts = opts or {}
  local client_name = lsp_utils.try_get_client_name(ctx.client_id)
  if ctx.source_file_path then
    opts.title = string.format('LSP[%s] symbols in %s', client_name, ctx.source_file_path)
  elseif ctx.source_query then
    opts.title = string.format('LSP[%s] search symbols: %s', client_name, ctx.source_query)
  else
    opts.title = string.format('LSP[%s] symbols', client_name)
  end
  opts.items = lsp.util.symbols_to_items(params, ctx.bufnr)
  vim.call('dotfiles#utils#push_qf_list', opts)
end
lsp.handlers['textDocument/documentSymbol'] = lsp_utils.wrap_handler_compat(M.handler)
lsp.handlers['workspace/symbol'] = lsp_utils.wrap_handler_compat(M.handler)


--[[
-- A replacement for <https://github.com/neovim/neovim/blob/v0.5.0/runtime/lua/vim/lsp/util.lua#L1640-L1645>.
-- See also: <https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#symbolKind>.
function lsp.util._get_symbol_kind_name(symbol_kind)
  return lsp_global_settings.SYMBOL_KIND_LABELS[symbol_kind] or lsp_global_settings.FALLBACK_SYMBOL_KIND_LABEL
end
--]]


-- A replacement for <https://github.com/neovim/neovim/blob/v0.5.0/runtime/lua/vim/lsp/util.lua#L1647-L1684>.
-- See also: <https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#textDocument_documentSymbol>.
function lsp.util.symbols_to_items(symbols, bufnr, opts)
  vim.g.dotfiles_lsp_symbols = symbols
  opts = opts or {}
  -- More on this one later...
  local use_alignment_hack = opts.use_dirty_qflist_text_alignment_hack or true
  local max_align_len = 0
  local items_align_lens = {}

  local items = {}

  local function render_node(prefix, sym, sym_range, sym_bufnr)
    local kind = lsp_global_settings.SYMBOL_KIND_LABELS[sym.kind] or lsp_global_settings.FALLBACK_SYMBOL_KIND_LABEL
    local text_parts = {prefix, '[', kind, '] ', sym.name}
    if sym.detail ~= nil and #sym.detail > 0 then
      table.insert(text_parts, ': ')
      table.insert(text_parts, sym.detail)
    end
    local linenr, colnr = lsp_utils.position_to_linenr_colnr(sym_bufnr, sym_range.start)
    local item = {
      bufnr = sym_bufnr,
      lnum = linenr + 1,
      col = colnr + 1,
      text = table.concat(text_parts),
    }
    table.insert(items, item)
    return item
  end

  local stack_prefix = {}
  local stack_depth = 0
  local function render_tree(tree_symbols)
    local tree_symbols_len, sorted_tree_symbols = #tree_symbols, vim.list_slice(tree_symbols)
    table.sort(sorted_tree_symbols, function(symbol_a, symbol_b)
      local pos_a, pos_b = symbol_a.selectionRange.start, symbol_b.selectionRange.start
      if pos_a.line ~= pos_b.line then
        return pos_a.line < pos_b.line
      end
      return pos_a.character < pos_b.character
    end)

    for symbol_idx, symbol in ipairs(sorted_tree_symbols) do
      if stack_depth > 0 then
        local junction_char = symbol_idx < tree_symbols_len and '├' or '└'
        stack_prefix[stack_depth] = junction_char .. '─'
      end

      local item = render_node(table.concat(stack_prefix), symbol, symbol.selectionRange, bufnr)
      -- HACK: Yes, indeed! To ensure that the tree is correctly aligned when
      -- browsing the qflist, we utilize the knowledge about our usage of the
      -- list and just do the formatting ourselves, to figure out the necessary
      -- padding for each item! Why use something like 'quickfixtextfunc' when
      -- can do some sprintfs ourselves? (Well, obviously, because it is a
      -- relatively new Vim feature, patches 8.2.0869, 8.2.0933 and 8.2.0959.)
      -- We are only interested in line and column numbers bit because that's
      -- the only thing that really changes on the left side between the
      -- entries, here's what happens under the hood:
      -- :clist/:llist <https://github.com/neovim/neovim/blob/v0.5.0/src/nvim/quickfix.c#L3109-L3116>
      -- :copen/:lopen <https://github.com/neovim/neovim/blob/v0.5.0/src/nvim/quickfix.c#L4007-L4016>
      if use_alignment_hack then
        local align_len = 0
        if item.lnum > 0 then
          align_len = align_len + utils.int_digit_length(item.lnum)  -- "%d"
          if item.col > 0 then
            align_len = align_len + 5 + utils.int_digit_length(item.col)  -- " col %d"
          end
        end
        if align_len > max_align_len then
          max_align_len = align_len
        end
        table.insert(items_align_lens, align_len)
      end


      if symbol.children ~= nil and not vim.tbl_isempty(symbol.children) then
        if stack_depth > 0 then
          local vertical_line_char = symbol_idx < tree_symbols_len and '│' or ' '
          stack_prefix[stack_depth] = vertical_line_char .. ' '
        end
        stack_depth = stack_depth + 1

        render_tree(symbol.children)

        stack_prefix[stack_depth] = nil
        stack_depth = stack_depth - 1
      end
    end
  end

  if not vim.tbl_isempty(symbols) then
    -- For reference, this check is the intended behavior defined by the
    -- specification.  SymbolInformations don't contain hierarchy information,
    -- unlike DocumentSymbol, and you are not allowed to mix the two in a
    -- single array, meaning that a) even the first element of the input array
    -- this function receives is enough for detecting the type of every
    -- element; b) once we step into a DocumentSymbol we can rest assured that
    -- all of the recursive children will be DocumentSymbols as well.
    if symbols[1].location then  -- SymbolInformation (most likely workspace symbols)
      use_alignment_hack = false  -- Not a tree-based structure.
      for _, symbol in ipairs(symbols) do
        render_node('', symbol, symbol.location.range, vim_uri.uri_to_bufnr(symbol.location.uri))
      end
    else  -- DocumentSymbol (probably document symbols)
      render_tree(symbols)
    end
  end

  -- HACK: Returning to the dirty hack above, now we can finally put the
  -- accumulated data to use.
  for item_idx, align_len in ipairs(items_align_lens) do
    local item = items[item_idx]
    -- A non-whitespace character is prepended to trick Vim into not removing
    -- the leading whitespace which we use for alignment.
    item.text = '-' .. string.rep(' ', max_align_len - align_len + 1) .. item.text
  end

  return items
end


return M
