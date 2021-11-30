--- See also:
--- <https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#textDocument_signatureHelp>
local M = require('dotfiles.autoload')('dotfiles.lsp.signature_help')

local lsp = require('vim.lsp')
local lsp_utils = require('dotfiles.lsp.utils')
local lsp_global_settings = require('dotfiles.lsp.global_settings')
local utils = require('dotfiles.utils')
local lsp_markup = require('dotfiles.lsp.markup')
local highlight_match = require('dotfiles.lsp.highlight_match')
local lsp_progress = require('dotfiles.lsp.progress')


-- Based on <https://github.com/neovim/neovim/blob/v0.5.0/runtime/lua/vim/lsp/buf.lua#L93-L98>.
function M.request()
  local params = lsp.util.make_position_params()
  params.workDoneToken = lsp_progress.random_token()
  lsp.buf_request(0, 'textDocument/signatureHelp', params)
end
lsp.buf.signature_help = M.request


-- Based on <https://github.com/neovim/neovim/blob/v0.5.0/runtime/lua/vim/lsp/handlers.lua#L318-L348>.
function M.handler(err, params, ctx, opts)
  if err then
    lsp_utils.client_notify(ctx.client_id, err, vim.log.levels.ERROR)
    return
  end
  opts = opts or {}
  opts.max_width = lsp_global_settings.SIGNATURE_WINDOW_MAX_WIDTH
  opts.max_height = lsp_global_settings.SIGNATURE_WINDOW_MAX_HEIGHT
  opts.focus_id = ctx.method
  local param_higroup = opts.dotfiles_active_param_highlight_group or 'LspSignatureActiveParameter'
  local param_priority = opts.dotfiles_active_param_highlight_priority or 99
  if params and params.signatures and not vim.tbl_isempty(params.signatures) then
    local filetype = utils.npcall(vim.api.nvim_buf_get_option, ctx.bufnr, 'filetype')
    local client = lsp.get_client_by_id(ctx.client_id)
    local trigger_chars = client and client.resolved_capabilities.signature_help_trigger_characters
    local parsing_ctx, active_param_range =
      M.convert_signature_help_to_docblocks(params, filetype, trigger_chars)
    -- Faster replacement for `vim.tbl_isempty(lsp.util.trim_empty_lines(markdown_lines))`
    local are_all_markdown_lines_empty = true
    for _, line in ipairs(parsing_ctx.lines) do
      if #line > 0 then
        are_all_markdown_lines_empty = false
        break
      end
    end
    if not are_all_markdown_lines_empty then
      opts.dotfiles_markup_parsing_ctx = parsing_ctx
      local _, float_winid = lsp.util.open_floating_preview(parsing_ctx.lines, 'markdown', opts)
      if active_param_range then
        highlight_match.add_ranges(float_winid, {active_param_range}, param_higroup, param_priority)
      end
      return
    end
  end
  lsp_utils.client_notify(ctx.client_id, 'signature help not available', vim.log.levels.WARN)
end


-- Copied from <https://github.com/neovim/neovim/blob/v0.5.0/runtime/lua/vim/lsp/util.lua#L844-L910>,
-- with <https://github.com/neovim/neovim/pull/15018> backported on top. See
-- <https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#signatureHelp>.
function M.convert_signature_help_to_docblocks(signature_help, syntax, trigger_chars, parsing_ctx)
  if trigger_chars == nil then trigger_chars = {} end
  if parsing_ctx == nil then parsing_ctx = lsp_markup.ParsingContext.new() end

  if not signature_help.signatures or vim.tbl_isempty(signature_help.signatures) then
    return parsing_ctx, nil
  end

  -- I have to mention that, as per specification, 0 is used both as the
  -- default value for `activeParameter` and `activeSignature`, and as a
  -- fallback for invalid indices (that fall outside of the array bounds).

  local active_signature_idx = signature_help.activeSignature or 0
  if not (0 <= active_signature_idx and active_signature_idx < #signature_help.signatures) then
    active_signature_idx = 0
  end
  -- <https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#signatureInformation>
  local active_signature = signature_help.signatures[active_signature_idx + 1]
  if not active_signature then
    return parsing_ctx, nil
  end

  lsp_markup.parse_plaintext_block(active_signature.label, syntax, parsing_ctx)

  local active_param_range = nil
  if active_signature.parameters and not vim.tbl_isempty(active_signature.parameters) then
    local active_param_idx = active_signature.activeParameter or signature_help.activeParameter or 0
    if not (0 <= active_param_idx and active_param_idx < #active_signature.parameters) then
      -- TODO: Evaluate this: <https://github.com/neovim/neovim/pull/15032#issuecomment-877033754>
      active_param_idx = 0
    end
    -- <https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#parameterInformation>
    local active_param = active_signature.parameters[active_param_idx + 1]

    if active_param then
      if active_param.label then
        local start_idx, end_idx
        if type(active_param.label) == 'string' then
          -- NOTE: See also: <https://github.com/neovim/neovim/pull/15032> and <https://github.com/neovim/neovim/issues/15022>.
          local search_offset = 1
          for _, char in ipairs(trigger_chars) do
            local char_offset = active_signature.label:find(char, 1, true)
            if char_offset and (search_offset == 1 or char_offset < search_offset) then
              search_offset = char_offset
            end
          end
          for param_idx, param in ipairs(active_signature.parameters) do
            local match_start, match_end = active_signature.label:find(param.label, search_offset, true)
            if not (match_start and match_end) then
              break
            end
            if param_idx == active_param_idx + 1 then
              start_idx, end_idx = match_start - 1, match_end - 1
              break
            else
              search_offset = match_end + 1
            end
          end
        else
          start_idx, end_idx =
            lsp_utils.char_offset_to_byte_offset(active_param.label[1], active_signature.label),
            lsp_utils.char_offset_to_byte_offset(active_param.label[2], active_signature.label)
        end
        local start_line, start_col =
          lsp_utils.byte_offset_to_linenr_colnr_in_str(start_idx, active_signature.label)
        local end_line, end_col =
          lsp_utils.byte_offset_to_linenr_colnr_in_str(end_idx, active_signature.label)
        active_param_range = {start_line, start_col, end_line, end_col}
      end

      if active_param.documentation then
        parsing_ctx:push_separator()
        lsp_markup.parse_documentation_blocks(active_param.documentation, parsing_ctx)
      end
    end
  end

  if active_signature.documentation then
    parsing_ctx:push_separator()
    lsp_markup.parse_documentation_blocks(active_signature.documentation, parsing_ctx)
  end

  return parsing_ctx, active_param_range
end


return M
