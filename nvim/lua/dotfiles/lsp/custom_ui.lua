--- Overrides to <https://github.com/neovim/neovim/blob/v0.6.0/runtime/lua/vim/ui.lua>
--- which don't fit into any other module.
local M = require('dotfiles.autoload')('dotfiles.lsp.custom_ui')

local vim_ui = require('vim.ui')
local utils = require('dotfiles.utils')

local fzf_buf_marker_counter = 0

--- Overrides <https://github.com/neovim/neovim/blob/v0.6.0/runtime/lua/vim/ui.lua#L21-L38>
--- to use FZF as the picker. NOTE that some choices on the appearance and
--- behavior of the select list were made based on the assumption that most
--- (if not all) it will be used for is LSP code actions.
function vim_ui.select(items, opts, on_choice)
  utils.check_type('items', items, 'table')
  utils.check_type('opts', opts, 'table', true)
  utils.check_type('on_choice', on_choice, 'function')
  opts = opts or {}

  local prompt = opts.prompt or 'Select one of: '
  if not string.match(prompt, '%s$') then
    prompt = prompt .. ' '
  end

  local choices = {}
  local format_item = opts.format_item or tostring
  local number_align_len = utils.int_digit_length(#items)
  for i = 1, #items do
    local padding = string.rep(' ', number_align_len - utils.int_digit_length(i))
    -- The first column of the output is for reliably determining the index
    -- of the returned result, the rest may be formatted however my heart
    -- desires.
    choices[i] = string.format('%d,%s%d: %s', i, padding, i, format_item(items[i]))
  end

  local on_choice_called = false
  local function on_choice_once(...)
    if not on_choice_called then
      on_choice_called = true
      on_choice(...)
    end
  end

  fzf_buf_marker_counter = fzf_buf_marker_counter + 1
  -- Use this variable and not the counter!
  local buf_marker = fzf_buf_marker_counter

  local original_bufnr = vim.api.nvim_get_current_buf()

  local immediately_returned_lines = vim.call('fzf#run', {
    name = 'vim.ui.select',
    _dotfiles_lsp_custom_ui_marker = buf_marker,

    source = choices,
    sinklist = function(lines)
      if vim.tbl_isempty(lines) then
        -- Can happen if the choice was cancelled, see comment below.
        on_choice_once(nil, nil)
        return
      end
      local picked_index = tonumber(lines[1]:match('^%d+'))
      assert(items[picked_index] ~= nil, 'fzf returned an invalid result')
      on_choice_once(items[picked_index], picked_index)
    end,
    _dotfiles_lsp_custom_ui_on_exit = function()
      -- Under normal circumstances this callback gets invoked before the sink
      -- callback (see hacks below), so we have to give the `sinklist` function
      -- a chance to run first. `set_timeout` with 0ms is used instead of
      -- simply `vim.schedule` on purpose: it seems that `vim.schedule`d
      -- callbacks can run in between autocommands. The way `set_timeout` is
      -- implemented ensures that this function will really be called on the
      -- next event loop tick.
      utils.set_timeout(0, function()
        on_choice_once(nil, nil)
      end)
    end,

    options = {
      -- Don't display the first column.
      '--with-nth=2..',
      '--delimiter=,',
      -- Mimick the appearance of the default `inputlist()`: prompt at the
      -- bottom of the screen (near the command line), items above it, in the
      -- order from top to bottom.
      '--layout=reverse-list',
      -- Self-descriptive.
      '--prompt=' .. prompt,
      -- Disable the total and filtered items counters.
      '--no-info',
      -- Disable the extended search syntax (see the section "EXTENDED SEARCH
      -- MODE" in the manpage) as there won't be that many items (to need an
      -- advanced query to navigate), but they are likely contain special
      -- characters.
      '--no-extended',
      -- Disallow selecting multiple items.
      '--no-multi',
      -- Make the arrow keys wrap around the list - this mimicks the behavior
      -- of coc, plus arrows will be used most of the time for navigating
      -- these lists.
      '--cycle',
    },
    -- A crude estimate of the height of the window. Note that fzf removes
    -- newline characters when rendering the prompt and the items, so they
    -- don't need to be taken into account.
    down = 1 + #choices,
  })

  -- What follows is definitely very fragile logic for detecting cancellation
  -- of the picker because fzf itself doesn't expose any callbacks for when the
  -- window is closed (or if the underlying fzf process fails). It is written
  -- for this commit:
  -- <https://github.com/junegunn/fzf/blob/ce9af687bcc58b2005c5d3f92bbaa08e77755bb8/plugin/fzf.vim>
  --
  -- We need to handle several possible modes of operation of fzf: some of them
  -- synchronous, some asynchronous. Note that the `fzf#run` function also
  -- returns the resulting lines received from the subprocess - I think this is
  -- the sort of "legacy" API which was created before async facilities were
  -- introduced in Neovim and, later, Vim. However, if an asynchronous code
  -- path is chosen, then instead of a list of lines an empty list is returned,
  -- so I can pretty easily tell apart the sync and async modes.
  --
  -- Anyway, the cases that need to be handled are:
  -- 1. Legacy invocation mode through `:!`: works only in regular Vim (because
  -- it relies on the direct terminal control given by `:!` in Vim),
  -- synchronous, implemented in `s:execute`. Nowadays unused.
  -- 2. Invocation within a tmux pane via `fzf-tmux`: synchronous, works the
  -- same in Vim and Nvim, implemented in `s:execute_tmux`, useful.
  -- 3. Invocation in a terminal buffer: works in Neovim and modern Vim (8.1+),
  -- inherently asynchronous, implemented in `s:execute_term`. In both editors
  -- creates a buffer which we can then exploit for autocommands.
  -- 4. HOWEVER, the first scenario also can be performed asynchronously, in
  -- particular under Windows and Nvim, the editor will open a new `cmd.exe`
  -- window with the fzf. Unclear why this exists, probably was added in a
  -- brief period of time when Nvim didn't have a terminal emulator yet.
  --
  -- Now, here's the thing: in the "normal" scenario (#3) we don't get any
  -- indication of whether the picker window has been closed, 4 doesn't even
  -- create a window we can attach to, but we don't need to do that at all
  -- because those code paths still invoke the sink callback with an empty list
  -- of lines, even in the case of an error (fzf exiting with an error code).
  -- So the only case we really need to care about is 3. The bottomline is that
  -- the code in #3 does not invoke the sink callback if fzf exits with a
  -- non-zero exit code - this is what I have to work around.

  -- To test the tmux integration, run:
  -- $ tmux new-session nvim --cmd 'let fzf_prefer_tmux = 1'

  if on_choice_called then
    -- My work here is done (most likely was one of the synchronous modes).
    return
  end

  if vim.api.nvim_get_current_buf() == original_bufnr then
    -- The 4th path has been taken (because no new terminal buffer has been
    -- created), it will call the callback with an empty lines list in case of
    -- failure (as expected), but it's not like I can do anything about it
    -- (since it uses `jobstart`).
    return
  end

  -- By this point we are most likely on the code path 3, and, more
  -- importantly, within the terminal buffer which is created and switched to
  -- inside the `s:execute_term` function, but I must verify this assumption.
  assert(vim.api.nvim_eval([[ &filetype ==# 'fzf' && exists('b:fzf') ]]) ~= 0)
  -- Vimscript eval is used ot avoid copying the b:fzf dictionary which
  -- contains funcrefs.
  assert(
    vim.api.nvim_eval([[ get(b:fzf, '_dotfiles_lsp_custom_ui_marker', v:null) ]]) == buf_marker
  )

  -- That's it, we are in the fzf buffer!
  vim.cmd([[
    autocmd TermClose <buffer> ++once ++nested call b:fzf._dotfiles_lsp_custom_ui_on_exit()
  ]])
end

return M
