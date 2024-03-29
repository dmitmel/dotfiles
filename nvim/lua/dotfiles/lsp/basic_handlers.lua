local M = require('dotfiles.autoload')('dotfiles.lsp.basic_handlers')

-- TODO: callHierarchy/incomingCalls and callHierarchy/outgoingCalls

-- TODO: links in case I continue work on this:
-- <https://github.com/ray-x/navigator.lua/tree/c3f6b142330303d5db7ec34b9362afe604369b7b>
-- <https://github.com/RishabhRD/popfix/tree/f3571e676739208871bd38f9fa0fddf554b6a7a8>
-- <https://github.com/RishabhRD/nvim-lsputils/tree/aaaf8c12771e905e5abf68470d8bda3e80536a0d>

local lsp = require('vim.lsp')
local lsp_utils = require('dotfiles.lsp.utils')
local utils = require('dotfiles.utils')
local lsp_progress = require('dotfiles.lsp.progress')
local utils_vim = require('dotfiles.utils.vim')

-- Basically <https://github.com/neovim/neovim/blob/v0.5.0/runtime/lua/vim/lsp/handlers.lua#L282-L316>,
-- but N i c e r.
function M._create_simple_location_list_handler(meta_opts)
  local the_handler = function(err, params, ctx, opts)
    if err then
      lsp_utils.client_notify(ctx.client_id, err, vim.log.levels.ERROR)
      return
    end
    if not params or vim.tbl_isempty(params) then
      lsp_utils.client_notify(ctx.client_id, meta_opts.not_found_message, vim.log.levels.WARN)
      return
    end
    opts = opts or {}
    local client_name = lsp_utils.try_get_client_name(ctx.client_id)
    local source = ctx.source
    if source then
      opts.title = string.format(
        'LSP[%s] %s of %s from %s:%s:%s',
        client_name,
        meta_opts.list_title,
        source.identifier,
        source.file_path,
        source.linenr,
        source.colnr
      )
      opts.current_position_params = source.text_doc_pos_params
    else
      opts.title = string.format('LSP[%s] %s', client_name, meta_opts.list_title)
    end
    lsp_utils.jump_to_location_maybe_many(params, opts)
  end

  local smarter_request = function(...)
    local req_params = lsp.util.make_position_params()
    req_params.workDoneToken = lsp_progress.random_token()
    if meta_opts.tweak_request_params then
      meta_opts.tweak_request_params(req_params, ...)
    end
    local source = {
      file_path = vim.fn.expand('%:.'),
      linenr = vim.fn.line('.'),
      colnr = vim.fn.col('.'),
      identifier = vim.fn.expand('<cword>'),
      text_doc_pos_params = req_params,
    }
    return lsp.buf_request(
      0,
      meta_opts.method,
      req_params,
      lsp_utils.wrap_handler_compat(function(err, params, ctx, opts)
        ctx.source = source
        return the_handler(err, params, ctx, opts)
      end)
    )
  end

  return the_handler, smarter_request
end

-- <https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#textDocument_declaration>
M.declaration_handler, M.request_declaration = M._create_simple_location_list_handler({
  method = 'textDocument/declaration',
  not_found_message = 'declaration not found',
  list_title = 'declarations',
})
lsp.handlers['textDocument/declaration'] = M.declaration_handler
lsp.buf.declaration = M.request_declaration

-- <https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#textDocument_definition>
M.definition_handler, M.request_definition = M._create_simple_location_list_handler({
  method = 'textDocument/definition',
  not_found_message = 'definition not found',
  list_title = 'definitions',
})
lsp.handlers['textDocument/definition'] = M.definition_handler
lsp.buf.definition = M.request_definition

-- <https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#textDocument_typeDefinition>
M.type_definition_handler, M.request_type_definition = M._create_simple_location_list_handler({
  method = 'textDocument/typeDefinition',
  not_found_message = 'type definition not found',
  list_title = 'type definitions',
})
lsp.handlers['textDocument/typeDefinition'] = M.type_definition_handler
lsp.buf.type_definition = M.request_type_definition

-- <https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#textDocument_implementation>
M.implementation_handler, M.request_implementation = M._create_simple_location_list_handler({
  method = 'textDocument/implementation',
  not_found_message = 'implementation not found',
  list_title = 'implementations',
})
lsp.handlers['textDocument/implementation'] = M.implementation_handler
lsp.buf.implementation = M.request_implementation

-- <https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#textDocument_references>
M.references_handler, M.request_references = M._create_simple_location_list_handler({
  method = 'textDocument/references',
  not_found_message = 'references not found',
  list_title = 'references',
  tweak_request_params = function(req_params, opts)
    utils.check_type('opts', opts, 'table', true)
    req_params.context = {
      includeDeclaration = utils.if_nil(opts.includeDeclaration, true),
    }
  end,
})
lsp.handlers['textDocument/references'] = M.references_handler
lsp.buf.references = M.request_references

-- Backport of <https://github.com/neovim/neovim/pull/15121>. All code was
-- taken from that PR.
if not utils_vim.has('nvim-0.5.2') then
  function M._code_action_request(params)
    local bufnr = vim.api.nvim_get_current_buf()
    local method = 'textDocument/codeAction'
    return vim.lsp.buf_request_all(bufnr, method, params, function(results)
      local actions = {}
      for client_id, r in pairs(results) do
        if r.error then
          lsp_utils.client_notify(client_id, r.error, vim.log.levels.ERROR)
        elseif r.result then
          vim.list_extend(actions, r.result)
        end
      end
      lsp_utils.call_handler_compat(vim.lsp.handlers[method], nil, actions, {
        method = method,
        bufnr = bufnr,
      })
    end)
  end

  function lsp.buf.code_action(context)
    utils.check_type('context', context, 'table', true)
    context = context or { diagnostics = lsp.diagnostic.get_line_diagnostics() }
    local params = lsp.util.make_range_params()
    params.context = context
    M._code_action_request(params)
  end

  function lsp.buf.range_code_action(context, start_pos, end_pos)
    utils.check_type('context', context, 'table', true)
    context = context or { diagnostics = lsp.diagnostic.get_line_diagnostics() }
    local params = lsp.util.make_given_range_params(start_pos, end_pos)
    params.context = context
    M._code_action_request(params)
  end
end

return M
