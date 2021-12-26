-- TODO: Update this comment

--- NOTE: The remote plugins are registered here in such a way that does not
--- require regenerating a manifest each time with `:UpdateRemotePlugins` (the
--- downside to this is that we must define the function/command/autocommand
--- specs by hand here). For this they also must live in some non-standard
--- directory, so that `:UpdateRemotePlugins` itself doesn't pick them up. I
--- got this idea from:
--- <https://github.com/neovim/neovim/blob/v0.5.0/runtime/autoload/remote/host.vim#L56-L65>
--- <https://github.com/tweekmonster/deoplete-clang2/blob/master/plugin/clang2.vim#L7-L20>
--- <https://github.com/zchee/nvim-go/blob/main/plugin/nvim-go.vim#L13-L68>
---
--- Anyway. I use remote plugins for integrating tools written in languages
--- like JS or Python (which have rplugin hosts) to avoid having to spawn
--- subprocesses every time (when saving the file which needs to be formatted,
--- for example).  Why use specifically remote plugins for this and not spawn a
--- subprocess with `jobstart({'rpc':1})`? Well, mostly because of the
--- convenient access to the nvim API and the fact that other plugins may use
--- rplugins themselves, so one host can be shared between my stuff and other
--- potential plugins. Also, paths to the rplugin files are saved for
--- performing direct `rpcnotify()` calls from Lua, this bypasses the need to
--- enter the Vimscript layer and allows direct conversion of Lua values into
--- msgpack structures instead of, again, a middle layer (i.e. Vimscript).
local M = require('dotfiles.autoload')('dotfiles.rplugin_bridge')

-- TODO comment about format of RPC methods unlikely to change

local utils = require('dotfiles.utils')
local utils_vim = require('dotfiles.utils.vim')
assert(utils_vim.has('nvim'), M.__module.name .. ' is currently only supported in neovim!')

M.FUNCTION_NAME_PREFIX = '_dotfiles_rplugin_'

M.rplugins_dir = vim.fn.fnamemodify(utils.script_path(), ':p:h:h:h') .. '/dotfiles/rplugin'
M.rplugins = {
  python3 = {
    -- NOTE: The directory itself must be specified here and not a path to
    -- `__init__.py` or something for imports to work correctly.
    main_file = 'dotfiles',
    public_specs = {},
  },
  node = {
    main_file = 'rplugin_main.js',
    public_specs = {},
  },
}

for rplugin_host, rplugin in pairs(M.rplugins) do
  vim.validate({
    host = { rplugin_host, 'string' },
    main_file = { rplugin.main_file, 'string' },
    specs = { rplugin.public_specs, vim.tbl_islist, 'list' },
  })
  rplugin.full_path = M.rplugins_dir .. '/' .. rplugin_host .. '/' .. rplugin.main_file
  rplugin.channel = nil
  for i, spec in ipairs(rplugin.public_specs) do
    vim.validate({
      [string.format('specs[%d].type', i)] = { spec.type, 'string' },
      [string.format('specs[%d].name', i)] = { spec.name, 'string' },
      [string.format('specs[%d].sync', i)] = { spec.sync, 'boolean', true },
      [string.format('specs[%d].opts', i)] = { spec.opts, 'table', true },
    })
    spec.sync = spec.sync or false
    spec.opts = spec.opts or vim.empty_dict()
  end
  vim.call('remote#host#RegisterPlugin', rplugin_host, rplugin.full_path, rplugin.public_specs)
end

function M.ensure_running(host)
  vim.validate({
    host = { host, 'string' },
  })
  local rplugin = assert(M.rplugins[host], 'unknown host')
  rplugin.channel = rplugin.channel or vim.call('remote#host#Require', host)
  return rplugin
end

function M.notify(host, method, ...)
  vim.validate({
    host = { host, 'string' },
    method = { method, 'string' },
  })
  local rplugin = M.ensure_running(host)
  return vim.rpcnotify(
    rplugin.channel,
    rplugin.full_path .. ':function:' .. M.FUNCTION_NAME_PREFIX .. method,
    ...
  )
end

function M.request(host, method, ...)
  vim.validate({
    host = { host, 'string' },
    method = { method, 'string' },
  })
  local rplugin = M.ensure_running(host)
  return vim.rpcrequest(
    rplugin.channel,
    rplugin.full_path .. ':function:' .. M.FUNCTION_NAME_PREFIX .. method,
    ...
  )
end

function M.request_async(host, method, ...)
  vim.validate({
    host = { host, 'string' },
    method = { method, 'string' },
  })
  local rplugin = M.ensure_running(host)
  local async_call_ctx = {}
  return vim.rpcnotify(
    rplugin.channel,
    async_call_ctx,
    rplugin.full_path .. ':function:' .. M.FUNCTION_NAME_PREFIX .. method,
    ...
  )
end

return M
