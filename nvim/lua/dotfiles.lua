local M = require('dotfiles.autoload')('dotfiles', _G.dotfiles, {
  autoload = ..., ---@module 'dotfiles.autoload'
  colorscheme = ..., ---@module 'dotfiles.colorscheme'
  lsp_extras = ..., ---@module 'dotfiles.lsp_extras'
  lsp_launcher = ..., ---@module 'dotfiles.lsp_launcher'
  lsp_ignition = ..., ---@module 'dotfiles.lsp_ignition'
  utils = ..., ---@module 'dotfiles.utils'
  nvim_lua_dev = ..., ---@module 'dotfiles.nvim_lua_dev'
  nvim_fzf_select = ..., ---@module 'dotfiles.nvim_fzf_select'
  augroup = ..., ---@module 'dotfiles.augroup'
  sane_indentline = ..., ---@module 'dotfiles.sane_indentline'
})
_G.dotfiles = M

local function dump_impl(opts, ...)
  local len = select('#', ...)
  if len == 0 then len = 1 end -- Print at least one argument
  local strs = {}
  for i = 1, len do
    strs[i] = vim.inspect((select(i, ...)), opts)
  end
  return print(unpack(strs, 1, len))
end

function _G.dump(...) return dump_impl(nil, ...) end
function _G.dump_compact(...) return dump_impl({ newline = ' ', indent = '' }, ...) end

function _G.printf(...) return print(string.format(...)) end

function _G.measure_time(fn, ...)
  local start_time = vim.uv.hrtime()
  local function measure_time_results_handler(...)
    local end_time = vim.uv.hrtime()
    return (end_time - start_time) / 1e9, ...
  end
  return measure_time_results_handler(fn(...))
end

-- TODO: This looks useful (probably a knockoff implementation of hyperfine):
-- <https://github.com/nvim-lua/plenary.nvim/blob/master/lua/plenary/benchmark/init.lua>
function _G.benchmark(runs, fn, ...)
  local start_time = vim.uv.hrtime()
  for i = 1, runs do
    fn(i, ...)
  end
  local end_time = vim.uv.hrtime()
  return (end_time - start_time) / 1e9 / runs
end

-- Taken from <https://github.com/nvim-lua/plenary.nvim/blob/15c3cb9e6311dc1a875eacb9fc8df69ca48d7402/lua/plenary/profile.lua#L7-L18>.
function _G.profile_start(out, opts)
  out = out or 'profile.log'
  opts = opts or { flame = true }
  -- Description of profiler options: <https://github.com/LuaJIT/LuaJIT/blob/v2.1/src/jit/p.lua#L22-L38>.
  local popts = '10,i1,s,m0'
  if opts.flame then popts = popts .. ',G' end
  require('jit.p').start(popts, out)
end

function _G.profile_stop() require('jit.p').stop() end

return M
