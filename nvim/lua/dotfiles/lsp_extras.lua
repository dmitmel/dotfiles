local M, module = require('dotfiles.autoload')('dotfiles.lsp_extras', {})

local lsp = require('vim.lsp')
local utils = require('dotfiles.utils')

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

---@param client_id integer
---@param message string
---@param level? vim.log.levels
---@param opts? table
function M.client_notify(client_id, message, level, opts)
  local client = lsp.get_client_by_id(client_id)
  local client_name = client and client.name or ('id=' .. client_id)
  vim.notify(('LSP[%s]: %s'):format(client_name, message), level, opts)
  vim.cmd('redraw')
end

-- List of events that will end or cancel actions that depend on the current cursor position.
M.CURSOR_MOVE_EVENTS = {
  'CursorMoved', -- This is obvious. It is also triggered when moving to another buffer or window.
  'CursorMovedI', -- CursorMoved in the Insert mode.
  'InsertCharPre', -- This is for actions that are triggered from Insert mode,
  'InsertEnter', -- such as `textDocument/signatureHelp`. Entering and leaving the Insert mode
  'InsertLeave', -- may also move the cursor and are also treated as reasons for cancelling.
}

--- Makes a request that may be cancelled by `CURSOR_MOVE_EVENTS` or if another
--- cancellable request is made. This idea was kindly stolen from
--- <https://github.com/neoclide/coc.nvim/blob/ce52303daf1eef8902d83e2b38a2d72567b035a8/src/handler/index.ts#L83-L88>.
---@param bufnr integer
---@param method vim.lsp.protocol.Method
---@param params? table | fun(client: vim.lsp.Client, bufnr: integer): table?
---@param handler fun(errors: table<integer, lsp.ResponseError>, results: table<integer, any>, context: lsp.HandlerContext, config?: table): ...
function M.cancellable_request(bufnr, method, params, handler)
  local augroup = utils.augroup(module.name .. '.cancellable_request', { clear = false })
  -- This will cancel any other requests that were already in progress.
  augroup:exec_autocmds(M.CURSOR_MOVE_EVENTS[1], { modeline = false })

  local cancelled = false
  local autocmd_id

  local cancel_requests = lsp.buf_request_all(bufnr, method, params, function(responses, ...)
    -- It sometimes may happen that even though the LSP request was cancelled,
    -- the callback is still entered. Probably when cancellation occurs after
    -- the request was received and parsed, but before the response callback is
    -- executed after `vim.schedule()`, although I'm not sure.
    if cancelled then return end
    vim.api.nvim_del_autocmd(autocmd_id)

    local errors = {} ---@type table<integer, lsp.ResponseError>
    local results = {} ---@type table<integer, any>

    for client_id, r in pairs(responses) do
      if r.err then
        errors[client_id] = r.err
        lsp.log.error(module.name, r.err)
        M.client_notify(client_id, tostring(r.err), vim.log.levels.ERROR)
      elseif r.result then
        results[client_id] = r.result
      end
    end

    return handler(errors, results, ...)
  end)

  autocmd_id = augroup:autocmd(M.CURSOR_MOVE_EVENTS, function()
    -- I cannot use the `once` flag in this instance: when an autocommand is
    -- registered for multiple events and one of them is triggered and caught,
    -- then the autocommand is deleted only from that one event and not from
    -- every event it was listening for. On the other hand, `nvim_del_autocmd()`
    -- unregisteres it from all registered events.
    vim.api.nvim_del_autocmd(autocmd_id)
    cancelled = true
    -- The cancellation callback returned by `lsp.buf_request_all()` may
    -- sometimes fail, in particular if the client disappears between sending
    -- the request and cancelling it, but I'm too lazy to submit a PR to Neovim
    -- to fix this.
    local ok, err = xpcall(cancel_requests, debug.traceback)
    if not ok then vim.notify(err, vim.log.levels.WARN) end
  end)
end

---@param method vim.lsp.protocol.Method
---@param list_type string
---@param opts { context?: table, exclude_current?: boolean }
function M.jump(method, list_type, opts)
  local symbol = vim.fn.expand('<cword>')
  local short_path = vim.fn.expand('%:.') -- Reduce to relative path if possible
  local full_path = vim.api.nvim_buf_get_name(0)
  local current_win = vim.api.nvim_get_current_win()
  local line, col = vim.fn.line('.'), vim.fn.col('.')

  local function make_params(client) ---@param client vim.lsp.Client
    local params = lsp.util.make_position_params(current_win, client.offset_encoding)
    params.context = opts.context
    return params
  end

  ---@param results table<integer, lsp.Location|lsp.Location[]|lsp.LocationLink[]>
  M.cancellable_request(0, method, make_params, function(_, results)
    local items = {} ---@type vim.quickfix.entry[]
    local clients = {} ---@type vim.lsp.Client[]
    for client_id, result in pairs(results) do
      local client = assert(lsp.get_client_by_id(client_id))
      local locations = not utils.is_list(result) and { result } or result
      vim.list_extend(items, lsp.util.locations_to_items(locations, client.offset_encoding))
      table.insert(clients, client)
    end

    if #items == 0 then
      vim.notify(
        ('%s: no %s found: %s'):format(module.name, list_type, symbol),
        vim.log.levels.WARN
      )
      return
    end

    local function is_current_item(item) ---@param item vim.quickfix.entry
      return item.filename == full_path
        and (line > item.lnum or (line == item.lnum and col >= item.col))
        and (line < item.end_lnum or (line == item.end_lnum and col < item.end_col))
    end

    local current_index ---@type number?
    if opts.exclude_current then
      -- This idea was taken from <https://github.com/folke/snacks.nvim/blob/bc0630e43be5699bb94dadc302c0d21615421d93/lua/snacks/picker/source/lsp/init.lua#L201-L218>.
      utils.remove_all(items, is_current_item)
    else
      _, current_index = utils.find(items, is_current_item)
    end

    -- if dotplug.has('fzf-lua') then
    --   return M.pick_locations_with_fzf(list_type, items)
    -- elseif dotplug.has('snacks.nvim') then
    --   return M.pick_locations_with_snacks(list_type, items)
    -- end

    vim.api.nvim_set_current_win(current_win)
    vim.cmd('lclose')
    if #items == 1 and #clients == 1 then
      local location = items[1].user_data --[[@as lsp.Location | lsp.LocationLink]]
      lsp.util.show_document(location, clients[1].offset_encoding, { focus = true })
      vim.cmd('normal! zz')
    else
      vim.fn.setloclist(current_win, {}, ' ', {
        title = ("[LSP] %s of '%s' from %s:%d"):format(list_type, symbol, short_path, line),
        items = items,
        idx = current_index,
      })
      if utils.is_truthy(vim.g.qf_auto_resize) then
        vim.call('qf#OpenLoclist')
      else
        vim.cmd('botright lwindow')
      end
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

-- `nvim_get_option_value()` with `filetype` creates a temporary buffer and runs
-- the ftplugins to obtain the value of the option, it is evaluated lazily and
-- only once.
local markdown_formatlistpat = utils.once(function() ---@return string
  return vim.api.nvim_get_option_value('formatlistpat', { filetype = 'markdown' })
end)

--- Based on <https://github.com/neovim/neovim/blob/v0.11.2/runtime/lua/vim/lsp/buf.lua#L31-L147>.
---@param opts vim.lsp.buf.hover.Opts?
function M.hover(opts)
  opts = opts or {}
  opts.close_events = M.CURSOR_MOVE_EVENTS
  opts.focus_id = module.name .. '.hover'

  local src_buf = vim.api.nvim_get_current_buf()
  local src_win = vim.api.nvim_get_current_win()

  -- This logic was extracted from `lsp.util.open_floating_preview()` so that we
  -- don't waste time waiting for a second request when the intent is to just
  -- jump into the popup window. And also because `open_floating_preview()` does
  -- not update the contents of the preview if it was opened already and just
  -- needs to be focused, which breaks my markdown highlighter. This can be
  -- fixed properly, but this is better because it makes the UX snappier.
  if opts.focusable ~= false and opts.focus ~= false then
    local existing_win = utils.find(vim.api.nvim_list_wins(), function(winid) --
      return vim.w[winid][opts.focus_id] == src_buf
    end)
    if existing_win then
      vim.api.nvim_set_current_win(existing_win)
      vim.cmd('stopinsert')
      return
    end
  end

  local augroup = utils.augroup(module.name .. '.hover', { clear = false })
  -- Clear any previous hover highlights.
  augroup:exec_autocmds(M.CURSOR_MOVE_EVENTS[1], { modeline = false })

  local function make_params(client) ---@param client vim.lsp.Client
    return lsp.util.make_position_params(src_win, client.offset_encoding)
  end

  ---@param results table<integer, lsp.Hover>
  M.cancellable_request(src_buf, 'textDocument/hover', make_params, function(_, results)
    local highlight_ids = {} ---@type integer[]

    for client_id, hover in pairs(results) do
      local client = assert(lsp.get_client_by_id(client_id))

      ---@param pos lsp.Position
      ---@return [integer,integer]
      local function lsp2vim(pos)
        local line = vim.api.nvim_buf_get_lines(src_buf, pos.line, pos.line + 1, false)[1] or ''
        return { pos.line, vim.str_byteindex(line, client.offset_encoding, pos.character, false) }
      end

      if hover.range then
        -- Highlighting is done with my own helper function that uses
        -- `matchaddpos()` instead of extmarks because this way the hover
        -- selection is correctly rendered over `linehl` backgrounds of signs.
        highlight_ids[#highlight_ids + 1] = M.highlight_range(
          src_win,
          lsp2vim(hover.range.start),
          lsp2vim(hover.range['end']),
          'LspReferenceTarget',
          vim.hl.priorities.user
        )
      end
    end

    local autocmd_ids ---@type integer[]
    local function clear_highlights()
      for _, id in ipairs(autocmd_ids) do
        vim.api.nvim_del_autocmd(id)
      end
      if vim.api.nvim_win_is_valid(src_win) then
        for _, id in ipairs(highlight_ids) do
          vim.fn.matchdelete(id, src_win)
        end
      end
    end

    -- The logic for clearing highlights is a fucking spaghetti mess.
    local allowed_bufs = { [src_buf] = true }
    autocmd_ids = {
      augroup:autocmd(M.CURSOR_MOVE_EVENTS, clear_highlights, { buffer = src_buf }),
      augroup:autocmd('BufEnter', function(event)
        if not allowed_bufs[event.buf] then clear_highlights() end
      end),
    }

    local renderer = require('dotfiles.markdown').renderer.new()

    local many_clients = #vim.tbl_keys(results) > 1
    for client_id, result in pairs(results) do
      renderer:ensure_separator()
      local client = assert(lsp.get_client_by_id(client_id))
      if many_clients then renderer:add_section_heading(1, client.name) end
      renderer:parse_documentation_sections(result.contents)
    end

    if renderer:is_empty() then
      if opts.silent then
        return
      else
        renderer:push_text_with_hl('LSP: no information available', 'WarningMsg')
      end
    end

    opts.focus = false
    local syntax = '' -- I am doing the highlighting myself
    local float_buf, float_win = lsp.util.open_floating_preview(renderer:get_lines(), syntax, opts)

    allowed_bufs[float_buf] = true
    autocmd_ids[#autocmd_ids + 1] =
      augroup:autocmd('WinClosed', tostring(float_win), clear_highlights, { once = true })

    local wo = vim.wo[float_win]
    wo.wrap = true
    wo.linebreak = true
    wo.breakindent = true
    wo.breakindentopt = 'list:-1'
    wo.showbreak = 'NONE'
    wo.smoothscroll = true
    wo.virtualedit = 'none'
    wo.winfixbuf = true
    wo.foldenable = false
    wo.spell = false
    wo.conceallevel = 0

    local bo = vim.bo[float_buf]
    bo.formatlistpat = markdown_formatlistpat()

    -- Add some pager-like mappings. `d` and `u` are normally used for editing
    -- text, so they are perfect for remapping. `<nowait>` is necessary because
    -- vim-surround maps `ds`.
    vim.keymap.set('n', 'd', '<C-d>', { buffer = float_buf, nowait = true })
    vim.keymap.set('n', 'u', '<C-u>', { buffer = float_buf })

    renderer:highlight_markdown(float_buf, vim.api.nvim_win_get_width(float_win))
    if utils.is_truthy(vim.g.syntax_on) then renderer:highlight_code_blocks(float_buf) end
  end)
end

---@param winid integer
---@param start [integer,integer]
---@param finish [integer,integer]
---@param hlgroup string
---@param priority integer
---@return integer match_id
function M.highlight_range(winid, start, finish, hlgroup, priority)
  local positions = {}

  local start_line, start_char, end_line, end_char = start[1], start[2], finish[1], finish[2]
  for line = start_line, end_line do
    local slice_start = line == start_line and start_char or 0
    local slice_end = line == end_line and end_char or vim.fn.col({ line + 1, '$' }, winid)
    if slice_end > slice_start then
      table.insert(positions, { line + 1, slice_start + 1, slice_end - slice_start })
    end
  end

  return vim.fn.matchaddpos(hlgroup, positions, priority, -1, { window = winid } --[[@as any]])
end

return M
