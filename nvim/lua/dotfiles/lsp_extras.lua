local M, module = require('dotfiles.autoload')('dotfiles.lsp_extras', {})

local lsp = require('vim.lsp')
local utils = require('dotfiles.utils')

local augroup = utils.augroup(module.name)

local vscode_install_paths = {} ---@type string[]
if utils.has('macunix') then
  vim.list_extend(vscode_install_paths, {
    '/Applications/Visual Studio Code - Insiders.app/Contents/Resources/app',
    '/Applications/Visual Studio Code.app/Contents/Resources/app',
  })
elseif utils.has('unix') then
  vim.list_extend(vscode_install_paths, {
    '/opt/visual-studio-code-insiders/resources/app', -- Arch Linux <https://aur.archlinux.org/packages/visual-studio-code-insiders-bin/>
    '/opt/visual-studio-code/resources/app', -- Arch Linux <https://aur.archlinux.org/packages/visual-studio-code-bin/>
    '/usr/lib/code/extensions', -- Arch Linux <https://archlinux.org/packages/community/x86_64/code/>
    '/usr/share/code/resources/app', -- Debian/Ubuntu <https://code.visualstudio.com/docs/setup/linux#_debian-and-ubuntu-based-distributions>
  })
end

---@param opts { archlinux_exe: string, npm_exe: string, vscode_script: string, args: string[] }
---@return string[]
function M.find_vscode_server(opts)
  for _, exe in ipairs({ opts.npm_exe, opts.archlinux_exe }) do
    if vim.fn.executable(exe) ~= 0 then return vim.list_extend({ exe }, opts.args) end
  end
  for _, vscode_dir in ipairs(vscode_install_paths) do
    local script = vscode_dir .. '/' .. opts.vscode_script
    if vim.fn.filereadable(script) ~= 0 then
      return vim.list_extend({ 'node', script }, opts.args)
    end
  end
  return vim.list_extend({ opts.npm_exe }, opts.args)
end

function M.cancel_last_jump()
  if M._cancel_jump_cb ~= nil then
    M._cancel_jump_cb()
    M._cancel_jump_cb = nil
  end
end

augroup:autocmd(
  { 'CursorMoved', 'CursorMovedI', 'InsertEnter', 'InsertLeave' },
  M.cancel_last_jump,
  { desc = 'cancel_last_jump' }
)

---@param method vim.lsp.protocol.Method
---@param list_type string
---@param opts { context?: table, exclude_current?: boolean }
function M.jump(method, list_type, opts)
  M.cancel_last_jump()

  local symbol = vim.fn.expand('<cword>')
  local src_file = vim.fn.expand('%:.') -- Reduce to relative path if possible
  local src_full_path = vim.api.nvim_buf_get_name(0)
  local current_win = vim.api.nvim_get_current_win()
  local cursor_pos = vim.api.nvim_win_get_cursor(current_win)

  local function make_params(client) ---@param client vim.lsp.Client
    local params = lsp.util.make_position_params(current_win, client.offset_encoding)
    params.context = opts.context
    return params
  end

  M._cancel_jump_cb = lsp.buf_request_all(0, method, make_params, function(responses)
    M._cancel_jump_cb = nil

    local items = {} ---@type vim.quickfix.entry[]
    local clients = {} ---@type vim.lsp.Client[]
    for client_id, r in vim.spairs(responses) do
      local client = lsp.get_client_by_id(client_id) or {}
      if r.err then
        -- lsp.log.error(r.err.code, r.err.message)
        local client_name = client.name or ('id=' .. client_id)
        local message = ('[LSP][%s] %s: %s'):format(client_name, r.err.code, r.err.message)
        vim.notify(message, vim.log.levels.ERROR)
        vim.cmd('redraw')
      elseif r.result and client then
        ---@type lsp.Location[]
        local locations = utils.is_list(r.result) and r.result or { r.result }
        vim.list_extend(items, lsp.util.locations_to_items(locations, client.offset_encoding))
        table.insert(clients, client)
      end
    end

    -- This idea was taken from <https://github.com/folke/snacks.nvim/blob/bc0630e43be5699bb94dadc302c0d21615421d93/lua/snacks/picker/source/lsp/init.lua#L201-L218>.
    if opts.exclude_current then
      utils.remove_all(items, function(item) --
        local line, col = cursor_pos[1], cursor_pos[2]
        return item.filename == src_full_path
          and (line > item.lnum or (line == item.lnum and col >= item.col))
          and (line < item.end_lnum or (line == item.end_lnum and col < item.end_col))
      end)
    end

    if next(items) == nil then
      vim.notify(('[LSP] no %s found'):format(list_type))
    elseif dotplug.has('fzf-lua') and false then
      M.pick_locations_with_fzf(list_type, items)
    elseif dotplug.has('snacks.nvim') and false then
      M.pick_locations_with_snacks(list_type, items)
    elseif #items == 1 and #clients == 1 then
      lsp.util.show_document(items[1].user_data, clients[1].offset_encoding)
    else
      vim.fn.setloclist(current_win, {}, ' ', {
        title = ("[LSP] %s of '%s' from %s:%d"):format(list_type, symbol, src_file, cursor_pos[2]),
        items = items,
      })
      vim.api.nvim_set_current_win(current_win)
      vim.call('qf#OpenLoclist')
    end
  end)
end

--- Based on <https://github.com/ibhagwan/fzf-lua/blob/70a1c1d266af2ea4d1d9c16e09c60d3fc8c5aa5f/lua/fzf-lua/providers/lsp.lua>,
--- but this is severely unfinished.
---@param locations vim.quickfix.entry[]
function M.pick_locations_with_fzf(title, locations)
  local Fzf = require('fzf-lua')

  local opts = { cwd = vim.uv.cwd() }
  opts = Fzf.config.normalize_opts(opts, 'lsp')
  opts = Fzf.core.set_fzf_field_index(opts)

  Fzf.fzf_exec(
    utils.map(locations, function(item) --
      return Fzf.make_entry.file(Fzf.make_entry.lcol(item, opts), opts)
    end),
    opts
  )
end

--- Based on <https://github.com/folke/snacks.nvim/blob/bc0630e43be5699bb94dadc302c0d21615421d93/lua/snacks/picker/source/lsp/init.lua#L174-L240>.
---@param list_type string
---@param locations vim.quickfix.entry[]
function M.pick_locations_with_snacks(list_type, locations)
  local max_height = (vim.o.lines - vim.o.cmdheight)
    - (vim.o.laststatus ~= 0 and 1 or 0)
    - (vim.o.showtabline ~= 0 and 1 or 0)
  local list_height = math.min(8, #locations, max_height) + 2 -- +1 for prompt, +1 for border
  local preview_height = math.min(13, utils.round((max_height - list_height) * 0.5))

  require('snacks.picker').pick({
    auto_confirm = true,
    jump = { tagstack = true, reuse_win = false },

    layout = {
      preset = 'dotfiles_coclist',
      layout = { height = list_height + preview_height },
    },

    win = {
      list = { min_height = list_height, max_height = list_height },
      preview = { min_height = preview_height, max_height = preview_height },
    },

    title = 'LSP ' .. list_type,
    -- <https://github.com/folke/snacks.nvim/blob/bc0630e43be5699bb94dadc302c0d21615421d93/lua/snacks/picker/source/qf.lua#L44-L61>
    items = utils.map(locations, function(loc)
      return { ---@type snacks.picker.finder.Item
        file = loc.filename,
        pos = { loc.lnum, loc.col - 1 },
        end_pos = { loc.end_lnum, loc.end_col - 1 },
        text = loc.filename .. ' ' .. loc.text,
        line = loc.text,
        item = loc,
      }
    end),
  })
end

return M
