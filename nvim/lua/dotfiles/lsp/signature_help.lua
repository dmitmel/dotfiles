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
local lsp_ignition = require('dotfiles.lsp.ignition')

lsp_ignition.add_client_capabilities({
  -- <https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#signatureHelpClientCapabilities>
  signatureHelp = {
    signatureInformation = {
      activeParameterSupport = true,
      parameterInformation = {
        labelOffsetSupport = true,
      },
    },
  },
})

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
    local renderer, active_param_range = M.convert_signature_help_to_docblocks(
      params,
      filetype,
      trigger_chars
    )
    if not renderer:are_all_lines_empty() then
      local _, float_winid = renderer:open_in_floating_window(opts)
      if active_param_range then
        highlight_match.add_ranges(
          float_winid,
          { active_param_range },
          param_higroup,
          param_priority
        )
      end
      return
    end
  end
  lsp_utils.client_notify(ctx.client_id, 'signature help not available', vim.log.levels.WARN)
end
lsp.handlers['textDocument/signatureHelp'] = lsp_utils.wrap_handler_compat(M.handler)

-- Copied from <https://github.com/neovim/neovim/blob/v0.5.0/runtime/lua/vim/lsp/util.lua#L844-L910>,
-- with <https://github.com/neovim/neovim/pull/15018> backported on top. See
-- <https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#signatureHelp>.
---@param renderer dotfiles.MarkupRenderer
function M.convert_signature_help_to_docblocks(signature_help, syntax, trigger_chars, renderer)
  if trigger_chars == nil then
    trigger_chars = {}
  end
  if renderer == nil then
    renderer = lsp_markup.Renderer.new()
  end

  if not signature_help.signatures or vim.tbl_isempty(signature_help.signatures) then
    return renderer, nil
  end

  -- I have to mention that, as per specification, 0 is used both as the
  -- default value for `activeParameter` and `activeSignature`, and as a
  -- fallback for invalid indices (that fall outside of the array bounds).

  local active_signature_idx = signature_help.activeSignature or 0
  if not (0 <= active_signature_idx and active_signature_idx < #signature_help.signatures) then
    active_signature_idx = 0
  end
  -- <https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#signatureInformation>
  local active_sig = signature_help.signatures[active_signature_idx + 1]
  local active_sig_linenr = nil

  for idx, signature in ipairs(signature_help.signatures) do
    if idx == active_signature_idx + 1 then
      active_sig_linenr = renderer.linenr
    end
    renderer:parse_plaintext_block(signature.label, syntax)
    renderer:set_syntax_region_break()
  end

  local active_param_range = nil
  if active_sig and active_sig.parameters and not vim.tbl_isempty(active_sig.parameters) then
    local active_param_idx = active_sig.activeParameter or signature_help.activeParameter or 0
    if not (0 <= active_param_idx and active_param_idx < #active_sig.parameters) then
      -- TODO: Evaluate this: <https://github.com/neovim/neovim/pull/15032#issuecomment-877033754>
      active_param_idx = 0
    end
    -- <https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#parameterInformation>
    local active_param = active_sig.parameters[active_param_idx + 1]

    if active_param and active_param.label then
      local start_idx, end_idx
      if type(active_param.label) == 'string' then
        -- NOTE: See also: <https://github.com/neovim/neovim/pull/15032> and <https://github.com/neovim/neovim/issues/15022>.
        local search_offset = 1
        for _, char in ipairs(trigger_chars) do
          local char_offset = active_sig.label:find(char, 1, true)
          if char_offset and (search_offset == 1 or char_offset < search_offset) then
            search_offset = char_offset
          end
        end
        for param_idx, param in ipairs(active_sig.parameters) do
          local match_start, match_end = active_sig.label:find(param.label, search_offset, true)
          if not (match_start and match_end) then
            break
          end
          if param_idx == active_param_idx + 1 then
            start_idx, end_idx = match_start - 1, match_end
            break
          else
            search_offset = match_end + 1
          end
        end
      else
        start_idx, end_idx =
          lsp_utils.char_offset_to_byte_offset(active_param.label[1], active_sig.label),
          lsp_utils.char_offset_to_byte_offset(active_param.label[2], active_sig.label)
      end
      local start_line, start_col = lsp_utils.byte_offset_to_linenr_colnr_in_str(
        start_idx,
        active_sig.label
      )
      local end_line, end_col = lsp_utils.byte_offset_to_linenr_colnr_in_str(
        end_idx,
        active_sig.label
      )
      active_param_range = {
        start_line + active_sig_linenr,
        start_col,
        end_line + active_sig_linenr,
        end_col,
      }
    elseif #signature_help.signatures > 1 then
      local end_line, end_col = lsp_utils.byte_offset_to_linenr_colnr_in_str(
        #active_sig.label,
        active_sig.label
      )
      active_param_range = { active_sig_linenr, 0, end_line + active_sig_linenr, end_col }
    end

    if active_param and active_param.documentation then
      renderer:push_separator()
      renderer:parse_documentation_blocks(active_param.documentation)
    end
  end

  if active_sig and active_sig.documentation then
    renderer:push_separator()
    renderer:parse_documentation_blocks(active_sig.documentation)
  end

  return renderer, active_param_range
end

return M
