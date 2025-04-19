local M = require('dotfiles.autoload')('dotfiles.plugman')
local lazy = require('lazy')
local utils_vim = require('dotfiles.utils.vim')

M.DEBUG_LOAD_ORDER = false

---@type LazyConfig
M.lazy_config = {
  root = vim.g['dotfiles#plugman#plugins_dir'],
  git = {
    url_format = vim.g['dotfiles#plugman#url_format'],
  },
  spec = {},
  performance = {
    reset_packpath = false,
    rtp = {
      reset = false,
    },
  },
  install = {
    colorscheme = { 'dotfiles', 'habamax' },
  },
}

---@param name string
---@return LazyPlugin|nil
function M.find_plugin(name)
  for _, spec in pairs(lazy.plugins()) do
    if spec.name == name then
      return spec
    end
  end
  return nil
end

---@return string[]
function M.plugin_names_completion()
  ---@type string[]
  local names = {}
  for _, spec in pairs(lazy.plugins()) do
    names[#names + 1] = spec.name
  end
  return names
end

---@param spec LazySpec
function M.register(spec)
  local specs = M.lazy_config.spec
  specs[#specs + 1] = spec
end

--- <https://github.com/junegunn/vim-plug#plug-options>
--- <https://github.com/junegunn/vim-plug/blob/baa66bcf349a6f6c125b0b2b63c112662b0669e1/plug.vim#L716-L752>
---@class VimplugSpec
---@field branch string
---@field tag string
---@field commit string
---@field rtp string
---@field dir string
---@field as string
---@field do string|function
---@field on string|string[]
---@field for string|string[]
---@field frozen any
---@field requires string|string[] <-- my addition
---@field priority number

---@param repo string
---@param old_spec VimplugSpec
function M.register_vimplug(repo, old_spec)
  local specs = M.lazy_config.spec

  ---@type LazyPluginSpec
  local spec = {
    repo,
    lazy = false,
  }

  local opt_err = "Unexpected value of option '%s', expected %s"

  -- <https://github.com/junegunn/vim-plug/blob/baa66bcf349a6f6c125b0b2b63c112662b0669e1/plug.vim#L716-L752>
  for key, value in pairs(old_spec) do
    if key == 'do' then
      if type(value) ~= 'string' and type(value) ~= 'function' then
        error(opt_err:format(key, 'string or function'))
      end
      spec.build = value
    elseif key == 'branch' or key == 'tag' or key == 'commit' then
      if type(value) ~= 'string' then
        error(opt_err:format(key, 'a string'))
      end
      spec[key] = value --[[@as any]]
    elseif key == 'as' then
      if type(value) ~= 'string' then
        error(opt_err:format(key, 'a string'))
      end
      spec.name = value
    elseif key == 'frozen' then
      spec.pin = utils_vim.is_truthy(value)
    elseif key == 'requires' then
      if type(value) == 'string' then
        spec.dependencies = { value }
      elseif
        vim.tbl_islist(value)
        and not vim.tbl_contains(value, function(elem) return type(elem) ~= 'string' end)
      then
        spec.dependencies = value
      else
        error(opt_err:format(key, 'string or list of strings'))
      end
    elseif key == 'priority' then
      if type(value) ~= 'number' then
        error(opt_err:format(key, 'a number'))
      end
      spec.priority = value
    else
      error(string.format("Plugin option '%s' is not supported", key))
    end
  end

  specs[#specs + 1] = spec
end

function M.end_setup()
  -- HACK: We have to poke the internals a little bit.
  local Config = require('lazy.core.config')
  local Loader = require('lazy.core.loader')

  -- Starting from v4.0.0, lazy.nvim performs the startup sequence by itself,
  -- including the sourcing of all Vimscript and Lua files in the `plugin`,
  -- `after/plugin` and `ftdetect` directories. This is done to enable
  -- lazy-loading and to be able to measure the startup times of the plugin
  -- scripts. However, this also introduces incompatibilities with my dotfiles
  -- because it messes up the script loading order, so I will use lazy.nvim
  -- only as a plugin manager, and fall back to Vim's built-in plugin loader.
  local old_loadplugins = vim.go.loadplugins
  -- Stub out this function so that lazy.nvim does not perform sourcing.
  local old_packadd = Loader.packadd
  Loader.packadd = function(path)
    if M.DEBUG_LOAD_ORDER then
      print(path)
    end
  end

  lazy.setup(M.lazy_config)

  -- lazy.nvim automatically installs the missing plugins for us, but does not
  -- clean up the unused plugins by itself.
  if not vim.tbl_isempty(Config.to_clean) then
    lazy.clean({ wait = true })
  end

  Loader.packadd = old_packadd
  vim.go.loadplugins = old_loadplugins
end

return M
