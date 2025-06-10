local utils = require('dotfiles.utils')

if dotplug.has('nvim-bqf') then
  -- setting a Vim variable is equivalent to |:unlet|
  vim.g.qf_mapping_ack_style = nil -- the mappings will be added by bqf
  vim.g.qf_auto_resize = false -- auto-resizing will be done by bqf

  ---@diagnostic disable-next-line: missing-fields
  require('bqf').setup({
    auto_enable = true,
    auto_resize_height = true,

    -- The list of default keybindings: <https://github.com/kevinhwang91/nvim-bqf#function-table>
    func_map = {
      prevfile = '(',
      nextfile = ')',
      prevhist = '<C-p>',
      nexthist = '<C-n>',
      openc = '<CR>',
      open = 'o',
      pscrollup = '<C-u>',
      pscrolldown = '<C-d>',
    },

    ---@diagnostic disable-next-line: missing-fields
    preview = {
      win_height = 13,
      win_vheight = 13,
      delay_syntax = 0,
      border = 'single',

      should_preview_cb = function(bufnr, qwinid)
        return utils.get_inmemory_buf_size(bufnr) <= 100 * 1000 -- 100 kB
          and not vim.api.nvim_buf_get_name(bufnr):match('^fugitive://')
          and not vim.bo[bufnr].binary
      end,
    },
  })
end

local has_vim_ui, vim_ui = pcall(require, 'vim.ui')
if has_vim_ui then
  vim_ui._lua_open = vim_ui._lua_open or vim_ui.open

  function vim_ui.open(path, opt) ---@diagnostic disable-line: duplicate-set-field
    if utils.is_truthy(vim.g['dotutils#use_lua_for_open_uri']) and vim_ui._lua_open ~= nil then
      local netrw_cmd = vim.g.netrw_browsex_viewer
      opt = vim.tbl_extend('keep', opt, {
        cmd = netrw_cmd and vim.split(netrw_cmd, '%s') or nil,
      })
      return vim_ui._lua_open(path, opt)
    end

    vim.call('dotutils#open_uri', path)
    local fake_system = {} --[[@cast fake_system vim.SystemObj]]
    function fake_system:wait()
      local fake_completed = {} --[[@cast fake_completed vim.SystemCompleted]]
      fake_completed.code = 0
      return fake_completed
    end
    return fake_system
  end

  function vim_ui.select(...) ---@diagnostic disable-line: duplicate-set-field
    return require('dotfiles.nvim_fzf_select').select(...)
  end
end

if dotplug.has('fzf-lua') then
  local FzfLua = require('fzf-lua')

  FzfLua.win._old_redraw_preview = FzfLua.win._old_redraw_preview or FzfLua.win.redraw_preview
  FzfLua.win.redraw_preview = utils.schedule_once_per_frame(FzfLua.win._old_redraw_preview)

  FzfLua.win._old_update_preview_title = FzfLua.win._old_update_preview_title
    or FzfLua.win.update_preview_title
  function FzfLua.win:update_preview_title(title)
    self:_old_update_preview_title(title)
    vim.fn.win_execute(self.fzf_winid, 'redrawstatus')
  end

  FzfLua.setup({
    'fzf-vim',

    fzf_opts = {
      ['--layout'] = 'default',
    },

    keymap = {
      builtin = {
        ['<C-/>'] = 'toggle-preview',
      },
    },

    fzf_colors = true,

    winopts = {
      backdrop = 100,
      split = function() vim.cmd(string.format('botright %dnew', vim.o.lines * 0.4)) end,

      preview = {
        hidden = false,
        border = utils.border_styles.left,
        horizontal = 'right:border-left:60%',
        winopts = {
          -- this helps by adding some padding between line numbers in the preview and the border
          signcolumn = 'yes',
        },
      },

      treesitter = { enabled = utils.is_truthy(vim.g.dotfiles_treesitter_highlighting) },

      ---@param params { winid: integer, bufnr: integer }
      on_create = function(params)
        local fzf_win, fzf_buf = params.winid, params.bufnr
        vim.w[fzf_win].fzf_lua_win = true
        vim.bo[fzf_buf].buflisted = false

        local src_buf = FzfLua.utils.fzf_winobj().src_bufnr

        -- Integration with vim.lsp -- vim.lsp.util.open_floating_preview should
        -- close our windows, and we should also close floats opened by it.
        -- <https://github.com/neovim/neovim/blob/v0.11.1/runtime/lua/vim/lsp/util.lua#L1554-L1559>
        local lsp_float = vim.b[src_buf].lsp_floating_preview
        if lsp_float and lsp_float ~= fzf_win and vim.api.nvim_win_is_valid(lsp_float) then
          vim.api.nvim_win_close(lsp_float, true)
        end
        -- <https://github.com/neovim/neovim/blob/v0.11.1/runtime/lua/vim/lsp/util.lua#L1615-L1616>
        vim.b[src_buf].lsp_floating_preview = fzf_win
        vim.w[fzf_win].lsp_floating_bufnr = src_buf
      end,
    },

    lines = {
      fzf_opts = { ['--layout'] = 'reverse-list' },
      winopts = { preview = { hidden = true } },
    },

    blines = {
      fzf_opts = { ['--layout'] = 'reverse-list' },
      winopts = { preview = { hidden = true } },
    },

    manpages = {
      previewer = 'man_native',
      -- The width of the preview window is specified in columns here.
      winopts = { preview = { horizontal = 'right:border-left:80' } },
    },

    lsp = {
      async_or_timeout = true,
      fzf_opts = {
        ['--layout'] = 'reverse-list',
      },
      winopts = {
        preview = {
          border = utils.border_styles.bottom,
          vertical = 'up:border-bottom:60%',
          layout = 'vertical',
        },
      },

      code_actions = {
        fzf_opts = {
          ['--layout'] = 'reverse-list',
          ['--info'] = 'hidden',
          ['--scrollbar'] = '█',
          ['--cycle'] = true,
        },

        fzf_colors = {
          ['fg'] = { 'fg', 'Pmenu' },
          ['bg'] = { 'bg', 'Pmenu' },
          ['gutter'] = { 'bg', 'Pmenu' },
          ['scrollbar'] = { 'bg', 'PmenuThumb' },
        },

        winopts = {
          split = false,
          relative = 'cursor',
          row = 1,
          col = 1,
          border = 'none',
          preview = { hidden = true },
        },
      },

      symbols = {
        fzf_opts = { ['--layout'] = 'reverse-list' },
        symbol_style = 2, -- Show just the icon
        symbol_hl = function(kind) return 'BlinkCmpKind' .. kind end,
        symbol_fmt = function(icon) return icon end,
      },
    },

    diagnostics = {
      fzf_opts = {
        ['--layout'] = 'reverse-list',
        ['--no-bold'] = true,
        ['--wrap'] = true,
      },
      fzf_colors = {
        ['fg+'] = { 'fg', 'Normal' },
      },
      color_headings = false,
    },

    previewers = {
      builtin = {
        title_fnamemodify = function(s) return vim.fn.fnamemodify(s, ':~:.') end,
        treesitter = {
          -- This will either return `true` to enable treesitter in previews for
          -- all filetypes, or a list of allowed filetypes.
          enabled = utils.is_truthy(vim.g.dotfiles_treesitter_highlighting) or {
            -- NOTE: Treesitter is too slow for the `help` filetype, which
            -- really bugs me when searching the manual with <F1>. For `query`
            -- the regex syntax highlighting sucks, so Treesitter is a must-have,
            -- and they are usually pretty small anyway and can be parsed quickly.
            'query',
          },
        },
      },
    },

    files = {
      git_icons = false,
      file_icons = false,
    },
  })

  FzfLua.deregister_ui_select(--[[ opts = ]] nil, --[[ silent = ]] true)
  FzfLua.register_ui_select(
    ---@generic T
    ---@param items T[]
    ---@param opts { prompt?: string, kind?: string, format_item?: fun(item: T): string }
    function(opts, items)
      local num_width = string.format('%d. ', #items):len()
      local item_width = 0
      for _, item in ipairs(items) do
        local text = opts.format_item and opts.format_item(item) or tostring(item)
        item_width = math.max(item_width, vim.api.nvim_strwidth(text))
      end
      return {
        winopts = {
          height = utils.clamp(#items - 1, 2, vim.o.pumheight - 2),
          width = utils.clamp(
            num_width + item_width + 1,
            math.max(2, vim.o.pumwidth),
            vim.o.columns * 0.4
          ),
        },
      }
    end
  )
end

if not dotplug.has('snacks.nvim') then return end

local Snacks = require('snacks')
local SnacksWin = require('snacks.win') ---@class snacks.win
local SnacksList = require('snacks.picker.core.list') ---@class snacks.picker.list
local SnacksInput = require('snacks.picker.core.input') ---@class snacks.picker.input
local SnacksPreview = require('snacks.picker.core.preview') ---@class snacks.picker.Preview

SnacksWin._old_redraw = SnacksWin._old_redraw or SnacksWin.redraw
function SnacksWin:redraw() ---@diagnostic disable-line: duplicate-set-field
  if self.first_draw_complete == nil then
    vim.schedule(function() self.first_draw_complete = true end)
    self.first_draw_complete = false
  elseif self.first_draw_complete then
    self:_old_redraw()
  end
end

---@param ... string | table<string, string>
---@return string
local function patch_winhl(...)
  local merged = {} ---@type string[]
  local key_to_index = {} ---@type table<string, integer>

  local function set(key, str)
    local idx = key_to_index[key]
    if idx == nil then
      idx = #merged + 1
      key_to_index[key] = idx
    end
    merged[idx] = str
  end

  for i = 1, select('#', ...) do
    local item = select(i, ...)
    if type(item) == 'string' then
      for pair in vim.gsplit(item, ',') do
        set(pair:match('^(.-):'), pair) -- `-` in Lua patterns is the non-greedy qualifier
      end
    else
      for k, v in pairs(item) do
        set(k, string.format('%s:%s', k, v))
      end
    end
  end

  return table.concat(merged, ',')
end

SnacksList._old_update_cursorline = SnacksList._old_update_cursorline
  or SnacksList.update_cursorline
function SnacksList:update_cursorline() ---@diagnostic disable-line: duplicate-set-field
  self:_old_update_cursorline()
  if self.win:win_valid() and self.picker.init_opts.source == 'select' then
    local wo = vim.wo[self.win.win]
    wo.winhighlight = patch_winhl(wo.winhighlight, {
      NormalFloat = 'Pmenu',
      CursorLine = 'PmenuSel',
    })
  end
end

SnacksPreview._old_loc = SnacksPreview._old_loc or SnacksPreview.loc
function SnacksPreview:loc() ---@diagnostic disable-line: duplicate-set-field
  local item = self.item
  if not item then
    self:_old_loc()
    return
  end

  local old_search = item.search
  item.search = nil
  self:_old_loc()
  item.search = old_search

  if item and not item.pos and item.search and item.search:match('^/') then
    local pattern = self.item.search:sub(2)
    -- TODO: contribute this to the upstream
    vim.api.nvim_win_call(self.win.win, function()
      -- cursor() does not affect the jumplist
      vim.fn.cursor(1, 1)
      -- search() starts searching at the cursor position and will move the
      -- cursor to the position of the first match. Unlike the `/` command, it
      -- does not pollute the search history or the jumplist.
      if vim.fn.search(pattern) ~= 0 then
        vim.cmd('normal! zt') -- I don't like the default `normal! zz`.
      end
    end)
  end
end

SnacksInput._old_new = SnacksInput._old_new or SnacksInput.new
---@param picker snacks.Picker
---@return snacks.picker.input
function SnacksInput.new(picker) ---@diagnostic disable-line: duplicate-set-field
  local self = SnacksInput._old_new(picker)
  local position = picker.opts.layout.layout.position
  if position ~= nil and position ~= 'float' then
    local opts = self.win.opts
    opts.wo.winhighlight = patch_winhl(opts.wo.winhighlight, { NormalFloat = 'Normal' })
  end
  return self
end

-- For use by `titlestring` and `statusline`.
function dotfiles.snacks_picker_info(what)
  local picker = Snacks.picker.get()[1]
  if picker ~= nil then
    if what == 'title' then
      return picker.title
    elseif what == 'pos' then
      return picker.list.cursor
    elseif what == 'list' then
      return #picker.list.items
    elseif what == 'selected' then
      return #picker.list.selected
    elseif what == 'found' then
      return picker.finder:count()
    elseif what == 'file' then
      local item = picker:current({ resolve = false })
      if not item then return nil end
      if item.buf and vim.api.nvim_buf_is_loaded(item.buf) then
        return vim.api.nvim_buf_get_name(item.buf)
      else
        return Snacks.picker.util.path(item)
      end
    end
  end
end

-- This function simply discards the return value of `Snacks.picker()` and
-- exists to be called from Vimscript because the returned `snacks.Picker`
-- cannot be converted into a Vimscript value.
function dotfiles.snacks_picker(...) Snacks.picker.pick(...) end

---@type snacks.Config
local snacks_config = {
  image = {
    enabled = true,
  },

  input = {
    enabled = false,
    icon = '',
    expand = true, -- NOTE: `expand=true` is too laggy. TODO: fix this.

    win = {
      relative = 'cursor',
      border = 'none',
      row = 1,
      col = -1,
      title_pos = 'left',

      on_buf = function(win) ---@param win snacks.win
        local min_width = 0
        win.opts.width = function()
          local width = vim.api.nvim_strwidth(win:text())
          if min_width == 0 then min_width = width end
          local borders_width = 2
          return math.max(min_width, width) + borders_width
        end
      end,

      wo = { virtualedit = 'none' },

      keys = {
        n_esc = {
          '<esc>',
          vim.schedule_wrap(function(win) ---@param win snacks.win
            win:execute('cancel')
          end),
          mode = 'n',
        },

        i_cr = {
          '<cr>',
          vim.schedule_wrap(function(win) ---@param win snacks.win
            win:execute('confirm')
          end),
          mode = { 'i', 'n' },
        },

        i_esc = false, -- In insert mode <Esc> should exit to Normal mode
        i_tab = false,
      },
    },
  },

  picker = {
    enabled = not dotplug.has('fzf-lua'),
    ui_select = true,
    prompt = '> ',

    layout = {
      preset = 'dotfiles_fzf',
      cycle = false,
      layout = {
        backdrop = false, -- no transparent blending
        position = 'bottom',
        height = 0.4, -- 40% of height
        width = 0, -- full width
      },
    },

    win = {
      input = {
        keys = {
          -- <Esc> in the filter input should close the list immediately.
          ['<Esc>'] = { 'close', mode = { 'n', 'i' } },
          -- Revert the behavior of <C-u> and <C-d> in the Insert mode to
          -- normal. These two only work in the Normal mode.
          ['<c-u>'] = { 'list_scroll_up', mode = { 'n' } },
          ['<c-d>'] = { 'list_scroll_down', mode = { 'n' } },
          ['<F1>'] = { 'toggle_help_list', mode = { 'n', 'i' } },
        },

        wo = { virtualedit = 'none' },
        bo = { iskeyword = vim.o.iskeyword .. ',.' },
      },

      preview = {
        wo = { signcolumn = 'auto', fillchars = 'eob: ' },
      },
    },

    icons = { ---@type any
      files = {
        enabled = false,
      },
      -- diagnostics = {
      --   Error = ' ERRR ',
      --   Warn = ' WARN ',
      --   Info = ' INFO ',
      --   Hint = ' HINT ',
      -- },
    },

    formatters = {
      severity = { icons = true },
    },

    config = function(opts) ---@param opts snacks.picker.Config
      if opts.title == 'Snacks Profiler' then opts.layout.reverse = false end
    end,

    ---@param picker snacks.Picker
    ---@param _ snacks.picker.Item
    on_change = function(picker, _)
      local root = picker.layout.root
      if
        utils.is_truthy(vim.g.loaded_airline)
        and (root:valid() and not root:is_floating())
        and picker.list.win.first_draw_complete
      then
        vim.fn.win_execute(root.win, 'redrawstatus')
      end
    end,

    sources = {
      lsp_declarations = { layout = { preset = 'dotfiles_coclist' }, focus = 'list' },
      lsp_definitions = { layout = { preset = 'dotfiles_coclist' }, focus = 'list' },
      lsp_implementations = { layout = { preset = 'dotfiles_coclist' }, focus = 'list' },
      lsp_references = { layout = { preset = 'dotfiles_coclist' }, focus = 'list' },
      lsp_type_definitions = { layout = { preset = 'dotfiles_coclist' }, focus = 'list' },

      select = {
        focus = 'list',
        prompt = 'filter> ',
        layout = { cycle = true },

        config = function(config) ---@param config snacks.picker.Config
          local max_item_width = 0
          for _, item in ipairs(config.items) do
            local text = {} ---@type string[]
            local fake_picker = nil ---@cast fake_picker snacks.Picker
            for i, extmark in ipairs(config.format(item, fake_picker)) do
              text[i] = extmark[1]
            end
            local whole_text = string.gsub(table.concat(text, ''), '\n', ' ')
            max_item_width = math.max(max_item_width, vim.api.nvim_strwidth(whole_text))
          end

          -- This works better than `screencol()` and `screenrow()` for some
          -- reason. Notably, in Neovide those functions return wrong results.
          -- <https://github.com/ibhagwan/fzf-lua/blob/1cc70fb29e63ff26acba1e0cbca04705f8a485f1/lua/fzf-lua/win.lua#L482-L491>
          local winid = vim.api.nvim_get_current_win()
          local curpos = vim.api.nvim_win_get_cursor(winid)
          ---@type { row: integer, col: integer, endcol: integer, curscol: integer }
          local screenpos = vim.fn.screenpos(winid, curpos[1], curpos[2])

          config.layout.preset = 'custom'
          config.layout.layout = {
            backdrop = false,
            position = 'float',
            height = math.min(utils.round(vim.o.lines * 0.4), #config.items + 1),
            width = max_item_width + 2,
            min_width = vim.o.pumwidth,
            row = screenpos.row,
            col = screenpos.col,
            box = 'vertical',
            { win = 'list' },
            { win = 'input', height = 1 },
          }
        end,
      },

      help = { prompt = ':help ' },
      man = { prompt = ':Man ' },
      buffers = { prompt = ':buf ' },

      lines = { layout = { preset = 'dotfiles_fzf', preview = 'main', reverse = false } },
      grep_buffers = { layout = { reverse = false, preview = false } },

      files = {
        hidden = true,
        follow = true,
        config = function(config) ---@param config snacks.picker.files.Config
          config.exclude = vim.opt.wildignore:get()
        end,
      },

      diagnostics = {
        layout = { preset = 'dotfiles_coclist' },
        focus = 'list',
        format = function(item, picker)
          local ret = {} ---@type snacks.picker.Highlight[]
          local diag = item.item ---@type vim.Diagnostic

          vim.list_extend(ret, Snacks.picker.format.severity(item, picker))
          vim.list_extend(ret, Snacks.picker.format.filename(item, picker))

          local severity_hl = nil
          if type(item.severity) == 'number' then
            local severity_name = vim.diagnostic.severity[item.severity]
            if type(severity_name) == 'string' then
              local hl_name = severity_name:sub(1, 1):upper() .. severity_name:sub(2):lower()
              severity_hl = 'Diagnostic' .. hl_name
            end
          end

          if diag.source then
            table.insert(ret, { diag.source, 'SnacksPickerDiagnosticSource' })
            table.insert(ret, { ' ' })
          end

          if diag.code then
            table.insert(ret, { '[' .. diag.code .. ']', severity_hl })
            table.insert(ret, { ' ' })
          end

          local message = diag.message
          table.insert(ret, { message })
          Snacks.picker.highlight.markdown(ret)

          return ret
        end,
      },
    },

    layouts = {
      dotfiles_fzf = {
        reverse = true,
        layout = {
          box = 'horizontal',
          {
            box = 'vertical',
            { win = 'list' },
            { win = 'input', height = 1 },
          },
          { win = 'preview', width = 0.6, border = 'left' },
        },
      },

      dotfiles_coclist = {
        reverse = false,
        layout = {
          box = 'vertical',
          { win = 'preview', height = 0.4, border = 'bottom' },
          { win = 'list' },
          { win = 'input', height = 1 },
        },
      },
    },
  },

  profiler = {
    filter_mod = {
      ['^vim%.'] = true,
      ['gitsigns.signs'] = false,
    },
    filter_fn = {
      ['^.*%._[^%.]*$'] = true,
    },
  },
}

Snacks.config.merge(Snacks.config, snacks_config)
if not Snacks.did_setup then Snacks.setup() end
