local M = require('dotfiles.autoload')('dotfiles.lsp_launcher', {})

local lsp = require('vim.lsp')
local utils = require('dotfiles.utils')

---@param client vim.lsp.Client
---@param config vim.lsp.ClientConfig
---@return boolean
function M.reuse_client(client, config)
  -- <https://github.com/neovim/neovim/blob/v0.11.0/runtime/lua/vim/lsp.lua#L146-L177>
  return client.name == config.name
end

---@class dotfiles.lsp.Config : vim.lsp.Config
---@field lazy_settings? elem_or_list<fun(config: vim.lsp.ClientConfig): lsp.LSPObject?>

---@param config dotfiles.lsp.Config
---@return dotfiles.lsp.Config
function M.patch_lsp_config(config)
  config.reuse_client = config.reuse_client or M.reuse_client
  local before_inits = utils.ensure_list(config.before_init)
  local lazy_settings = utils.ensure_list(config.lazy_settings)
  config.lazy_settings = nil

  ---@param init_params lsp.InitializeParams
  ---@param config vim.lsp.ClientConfig
  config.before_init = function(init_params, config)
    local capabilities = init_params.capabilities
    capabilities.textDocument.inlayHint = nil -- COMPLETELY disable inlay hints
    capabilities.textDocument.codeLens = nil -- COMPLETELY disable code lens
    utils.remove_all(capabilities.textDocument.semanticTokens.tokenTypes, function(type)
      return type == 'comment' --
    end)

    if lazy_settings ~= nil then
      for _, callback in ipairs(lazy_settings) do
        local extra_settings = callback(config)
        if extra_settings ~= nil then utils.inplace_merge(config.settings, extra_settings) end
      end
    end

    for _, callback in ipairs(before_inits) do
      callback(init_params, config)
    end
  end

  return config
end

---@param bufnr integer
---@return boolean
function M.should_attach(bufnr)
  local bo = vim.bo[bufnr]
  local lsp_enable = vim.b[bufnr].lsp_enable
  return (lsp_enable == nil or utils.is_truthy(lsp_enable))
    and (bo.buftype == '' or bo.buftype == 'acwrite')
    and vim.uri_from_bufnr(bufnr):match('^file:')
    and utils.get_inmemory_buf_size(bufnr) <= 1000000 -- 1MB
end

--- NOTE: I'm gonna stick to lspconfig as my Language Server launcher for now
--- because it handles workspace folders correctly[1], while `vim.lsp` as of
--- Neovim 0.11+ has not implemented that functionality yet. However, I want
--- to put my server configs in `lsp/*.lua` in runtimepath, just like in the
--- new system[2].
--- [1]: <https://github.com/neovim/nvim-lspconfig/blob/48f4475eb71638b69c984557169dc3826603d37e/lua/lspconfig/manager.lua#L7-L152>
--- [2]: <https://github.com/neovim/neovim/blob/v0.11.1/runtime/lua/vim/lsp.lua#L397-L408>
---@param servers string[]
function M.setup(servers)
  local LspManager = require('lspconfig.manager')
  local LspConfigs = require('lspconfig.configs')
  local has_blink_cmp, blink_cmp = pcall(require, 'blink.cmp')

  lsp._old_start = lsp._old_start or lsp.start
  ---@param config dotfiles.lsp.Config
  ---@param opts vim.lsp.start.Opts
  ---@return integer? client_id
  function lsp.start(config, opts) ---@diagnostic disable-line: duplicate-set-field
    opts.reuse_client = opts.reuse_client or M.reuse_client
    return lsp._old_start(M.patch_lsp_config(config), opts)
  end

  lsp._old_start_client = lsp._old_start_client or lsp.start_client
  ---@param config dotfiles.lsp.Config
  ---@return integer? client_id
  function lsp.start_client(config) ---@diagnostic disable-line: duplicate-set-field
    return lsp._old_start_client(M.patch_lsp_config(config))
  end

  ---@diagnostic disable-next-line: inject-field
  LspManager._old_try_add = LspManager._old_try_add or LspManager.try_add
  function LspManager:try_add(bufnr, ...)
    -- Got this trick from <https://www.reddit.com/r/neovim/comments/z85s1l/comment/iyfrgvb/>
    if M.should_attach(bufnr) then return self:_old_try_add(bufnr, ...) end
  end

  for _, name in ipairs(servers) do
    local config = {} ---@type dotfiles.lsp.Config
    for _, path in ipairs(vim.api.nvim_get_runtime_file('lsp/' .. name .. '.lua', true)) do
      local config_part = dofile(path) ---@type dotfiles.lsp.Config
      utils.inplace_merge(config, config_part)
    end

    if has_blink_cmp then
      config.capabilities = blink_cmp.get_lsp_capabilities(config.capabilities)
    end

    local root_markers = config.root_markers
    local cfg_root_dir = config.root_dir
    if root_markers and not cfg_root_dir then
      -- lspconfig's launcher does not support `root_markers`, this is a feature
      -- introduced by |vim.lsp|.
      vim.list_extend(root_markers, { '.vim', '.git', '.hg', '.projections.json' });
      (config --[[@as lspconfig.Config]]).root_dir = function(buf_path)
        return vim.fs.root(buf_path, root_markers)
      end
    elseif type(cfg_root_dir) == 'function' then
      -- lspconfig also uses a different signature for `root_dir`, and its
      -- `root_dir` is ran within an asynchronous coroutine, unlike |vim.lsp|'s
      -- `root_dir`, which receives a callback.
      (config --[[@as lspconfig.Config]]).root_dir = function(filename, bufnr)
        local path = utils.await(function(cb) cfg_root_dir(bufnr, cb) end)
        if vim.in_fast_event() then -- Re-enter the main loop of Neovim if necessary.
          utils.await(vim.schedule)
        end
        return path
      end
    end

    -- Translate this property into lspconfig's terms as well.
    (config --[[@as lspconfig.Config]]).single_file_support = not config.workspace_required

    -- HACK: Make lspconfig recognize the config exactly as it was supplied by me.
    if LspConfigs[name] ~= nil then LspConfigs[name] = nil end
    LspConfigs[name] = { default_config = config }
    LspConfigs[name].setup({})
  end
end

return M
