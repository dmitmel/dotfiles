-- See the complementary code in ../autoload/dotplug.vim

local M, module = require('dotfiles.autoload')('dotplug', _G.dotplug)
_G.dotplug = M

if vim.g['dotplug#implementation'] ~= 'lazy.nvim' then
  -- Divert the public API to the Vimscript code

  ---@type fun(name: string): boolean
  function M.has(name) return vim.call('dotplug#has', name) end

  ---@type fun(name: string): string
  function M.plugin_dir(name) return vim.call('dotplug#plugin_dir', name) end

  ---@type fun(names: string[])
  function M.load(names) return vim.fn['dotplug#load'](unpack(names)) end

  ---@type fun(repo: string, old_spec: VimplugSpec)
  function M.vimplug(repo, old_spec) return vim.call(repo, old_spec) end

  return M
end

local utils = require('dotfiles.utils')
local lazy = require('lazy')

---@type LazyConfig
M.lazy_config = {
  root = vim.g['dotplug#plugins_dir'],
  git = {
    url_format = vim.g['dotplug#url_format'],
  },
  spec = {
    { import = 'dotfiles.plugins' },
  },
  performance = {
    reset_packpath = false,
    rtp = { reset = false },
  },
  install = {
    missing = utils.is_truthy(vim.g['dotplug#autoinstall']),
    colorscheme = { 'default' },
  },
  change_detection = {
    enabled = false, -- I will do that myself.
    notify = false,
  },
  ui = {
    backdrop = 100,
    -- border = 'none',
    border = utils.border_styles.outset,
  },
}

---@param name string
---@return LazyPlugin|nil
function M.find_plugin(name)
  utils.check_type('name', name, 'string')
  for _, spec in pairs(lazy.plugins()) do
    if spec.name == name then return spec end
  end
  return nil
end

---@param name string
---@return boolean
function M.has(name) return M.find_plugin(name) ~= nil end

---@param name string
---@return string
function M.plugin_dir(name) return M.find_plugin(name).dir end

---@param names string[]
function M.load(names)
  utils.check_type('names', names, utils.is_list(names), 'list')
  if utils.is_empty(names) then error('expected one or more plugin names') end
  lazy.load({ plugins = names, wait = true })
end

---@return string
function M.plugin_names_completion()
  ---@type string[]
  local names = {}
  for _, spec in pairs(lazy.plugins()) do
    names[#names + 1] = spec.name
  end
  return table.concat(names, '\n')
end

---@param spec LazySpec
function M.plug(spec)
  local specs = M.lazy_config.spec
  specs[#specs + 1] = spec
end

--- <https://github.com/junegunn/vim-plug#plug-options>
--- <https://github.com/junegunn/vim-plug/blob/baa66bcf349a6f6c125b0b2b63c112662b0669e1/plug.vim#L716-L752>
--- <https://lazy.folke.io/spec>
---@class VimplugSpec
---@field branch?   string           = |LazyPluginSpec.branch|
---@field tag?      string           = |LazyPluginSpec.tag|
---@field commit?   string           = |LazyPluginSpec.commit|
---@field version?  string           = |LazyPluginSpec.version|
---@field rtp?      string           unsupported
---@field dir?      string           unsupported
---@field as?       string           = |LazyPluginSpec.name|
---@field do?       string|function  = |LazyPluginSpec.build|
---@field on?       string|string[]  unsupported
---@field for?      string|string[]  unsupported
---@field frozen?   integer|boolean  = |LazyPluginSpec.pin|
---@field requires? string|string[]  = |LazyPluginSpec.dependencies|
---@field priority? integer          = |LazyPluginSpec.priority|
---@field if?       integer|boolean  = |LazyPluginSpec.enabled|
---@field lazy?     integer|boolean  = |LazyPluginSpec.lazy|
---@field setup?    string           = |LazyPluginSpec.config|

---@param repo string
---@param old_spec VimplugSpec
function M.vimplug(repo, old_spec)
  utils.check_type('repo', repo, 'string')
  utils.check_type('old_spec', old_spec, 'table')

  local specs = M.lazy_config.spec

  ---@type LazyPluginSpec
  local spec = {
    repo,
    lazy = false,
  }

  -- <https://github.com/junegunn/vim-plug/blob/baa66bcf349a6f6c125b0b2b63c112662b0669e1/plug.vim#L716-L752>
  for key, value in pairs(old_spec) do
    if key == 'do' then
      if type(value) == 'string' or type(value) == 'function' then
      else
        error(string.format('%s: expected string or function, got %s', key, type(value)))
      end
      spec.build = value
    elseif key == 'branch' or key == 'tag' or key == 'commit' or key == 'version' then
      utils.check_type('key', value, 'string')
      spec[key] = value --[[@as any]]
    elseif key == 'as' then
      utils.check_type('key', value, 'string')
      spec.name = value
    elseif key == 'frozen' then
      spec.pin = utils.is_truthy(value)
    elseif key == 'if' then
      spec.enabled = utils.is_truthy(value)
    elseif key == 'lazy' then
      spec.lazy = utils.is_truthy(value)
    elseif key == 'requires' then
      if type(value) == 'string' then
        spec.dependencies = { value }
      elseif
        utils.is_list(value)
        and not vim.tbl_contains(value, function(elem) return type(elem) ~= 'string' end)
      then
        spec.dependencies = value
      else
        error(string.format('%s: expected string or list of strings', key))
      end
    elseif key == 'priority' then
      utils.check_type('key', value, 'number')
      spec.priority = value
    elseif key == 'setup' then
      utils.check_type('key', value, 'string')
      spec.config = function() vim.cmd(value) end
    else
      error(string.format("Plugin option '%s' is not supported", key))
    end
  end

  specs[#specs + 1] = spec
end

function M.end_setup()
  -- HACK: We have to poke the internals a little bit.
  local LazyConfig = require('lazy.core.config')
  local LazyLoader = require('lazy.core.loader')

  -- Starting from v4.0.0, lazy.nvim performs the startup sequence by itself,
  -- including the sourcing of all Vimscript and Lua files in the `plugin`,
  -- `after/plugin` and `ftdetect` directories. This is done to enable
  -- lazy-loading and to be able to measure the startup times of the plugin
  -- scripts. However, this also introduces incompatibilities with my dotfiles
  -- because it messes up the script loading order, so I will use lazy.nvim
  -- only as a plugin manager, and fall back to Vim's built-in plugin loader.
  local old_loadplugins = vim.o.loadplugins
  -- Stub out this function so that lazy.nvim does not perform sourcing.
  local old_packadd = LazyLoader.packadd

  local let_lazy_do_its_thing = utils.is_truthy(vim.g['dotplug#use_lazynvim_plugin_loader'])

  if not let_lazy_do_its_thing then
    local debug_load_order = utils.is_truthy(vim.g['dotplug#debug_load_order'])
    LazyLoader.packadd = function(path)
      if debug_load_order then print(path) end
    end
  end

  lazy.setup(M.lazy_config)

  -- lazy.nvim automatically installs the missing plugins for us, but does not
  -- clean up the unused plugins by itself.
  if utils.is_truthy(vim.g['dotplug#autoclean']) and not utils.is_empty(LazyConfig.to_clean) then
    lazy.clean({ wait = true })
  end

  if not let_lazy_do_its_thing then
    LazyLoader.packadd = old_packadd
    vim.o.loadplugins = old_loadplugins
  end

  vim.api.nvim_create_autocmd('BufWritePost', {
    group = vim.api.nvim_create_augroup(module.name, { clear = true }),
    pattern = vim.fn.escape(utils.script_relative('../lua/dotfiles/plugins'), '*?,{}[]\\')
      .. '/*.lua',
    -- Do schedule() beforehand so that if multiple files get changed, reload is called just once.
    callback = utils.schedule_once_per_tick(
      function() require('lazy.manage.reloader').reload() end
    ),
  })
end

return M
