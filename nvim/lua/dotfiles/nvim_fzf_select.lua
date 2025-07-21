local M = require('dotfiles.autoload')('dotfiles.nvim_fzf_select', {})

local utils = require('dotfiles.utils')

-- To test with the tmux integration, run:
-- $ tmux new-session nvim --cmd 'let fzf_prefer_tmux = 1'

---@alias dotfiles.ui_select_fn fun(items: any[],
---  opts: { prompt?: string, kind?: string, format_item?: fun(item: any): string },
---  on_choice: fun(item?: any, idx?: integer))

---@type dotfiles.ui_select_fn
function M.fzf_select(items, opts, on_choice)
  utils.check_type('items', items, 'table')
  utils.check_type('opts', opts, 'table', true)
  utils.check_type('on_choice', on_choice, 'function')
  opts = opts or {}

  local prompt = opts.prompt and tostring(opts.prompt) or 'Select'
  -- This will trim the leading and trailing whitespace, and remove the final
  -- semicolon if it was present in the given string.
  prompt = prompt:gsub('^%s*', ''):gsub(':?%s*$', '')
  prompt = prompt .. ': ' -- And now, append our own prompt ending.

  local choices = {}
  local format_item = opts.format_item or tostring
  local num_width = tostring(#items):len()
  local line_fmt = '%' .. num_width .. 'd. %s' -- This is terrible.
  for i = 1, #items do
    choices[i] = line_fmt:format(i, format_item(items[i]))
  end

  local fzf_exit_code = nil ---@type integer?
  local fzf_output_lines = {} ---@type string[]

  -- Okay, this is a bit of a HACK, but it exists due to fzf.vim not firing the
  -- callback functions consistently. Basically, the exit callback is always
  -- called, but the sink function may not always be executed if fzf is run
  -- asynchronusly in the Neovim terminal, namely, when the selection is
  -- canceled by the user by pressing <Esc> or similar. The exit is always
  -- called before the sink, so we get the following two possibilities:
  --
  -- 1. `vim.ui.select` --> FZF runs --> `exit` --> `sinklist` --> `on_choice`
  -- 2. `vim.ui.select` --> FZF runs --> `exit` -----------------> `on_choice`
  --
  -- Problem is, we need to ALWAYS call the `on_choice` callback, even when the
  -- selection is cancelled, we need to know the exit code of FZF, but we
  -- receive it before the sink is entered, which we also need to find which
  -- option got selected (if any). My solution is to schedule a function that
  -- will run on the next iteration of the event loop, and before that happens,
  -- collect the necessary information from both `exit` and `sinklist`.

  local done = false
  local function async_callback()
    if done then return end
    done = true

    if fzf_exit_code == 0 and #fzf_output_lines > 0 then
      local selected_str = fzf_output_lines[1]:match('^%s*(%d+)%.')
      if selected_str ~= nil then
        local selected = tonumber(selected_str, 10)
        if selected ~= nil and items[selected] ~= nil then
          on_choice(items[selected], selected)
          return
        end
      end
    end

    on_choice(nil, nil)
  end

  -- `fzf#wrap` adds the configuration from `g:fzf_colors` and such.
  vim.fn['fzf#run'](vim.fn['fzf#wrap']({
    name = 'vim.ui.select',

    options = {
      '--prompt=' .. prompt,
      -- Mimick the look of `inputlist()` -- the prompt is at the bottom, the
      -- list is shown in the natural order, increasing from top to bottom.
      '--layout=reverse-list',
      -- Disable the horizontal separator line between the prompt and the list.
      '--no-separator',
      -- Show the number of choices on the right hand side of the prompt.
      '--info=inline-right',
      -- The items are likely to contain special characters, so give the
      -- possibility of typing them literally in the search.
      '--no-extended',
      '--no-multi',
      '--cycle',
    },

    -- Put the FZF window at the bottom edge of the screen.
    down = math.min(1 + #choices, math.floor(vim.o.lines * 0.4)),

    source = choices,

    exit = function(code)
      fzf_exit_code = code
      vim.schedule(async_callback)
    end,

    sinklist = function(lines)
      fzf_output_lines = lines
      vim.schedule(async_callback)
    end,
  }))
end

---@type dotfiles.ui_select_fn
function M.popupmenu_select(items, opts, on_choice)
  local lsp_float = vim.b.lsp_floating_preview
  if lsp_float and vim.api.nvim_win_is_valid(lsp_float) then
    vim.api.nvim_win_close(lsp_float, true)
  end

  local function escape_menu_name(str) return vim.fn.escape(vim.fn.strtrans(str), ' .&\\') end

  local menu_name = ']DotfilesCodeActions'
  pcall(vim.cmd.aunmenu, menu_name)

  local var_name = 'dotfiles_selected_code_action'
  vim.g[var_name] = nil

  local num_padding = #tostring(#items)
  for i, item in ipairs(items) do
    local text = opts.format_item and opts.format_item(item) or tostring(item)
    vim.cmd.amenu({
      menu_name .. '.' .. escape_menu_name(('%' .. num_padding .. 'd. %s'):format(i, text)),
      ('<Cmd>let g:%s = %d<CR>'):format(var_name, i),
    })
  end

  -- NOTE: this command is synchronous. At least in Neovim.
  vim.cmd.popup(menu_name)

  local selected = vim.g[var_name]
  vim.g[var_name] = nil

  vim.cmd.aunmenu(menu_name)

  if selected ~= nil and items[selected] ~= nil then
    on_choice(items[selected], selected)
  else
    on_choice(nil, nil)
  end
end

return M
