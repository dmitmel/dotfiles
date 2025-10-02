local utils = require('dotfiles.utils')

-- The set of all mouse keycodes recognized and handled by Neovim's terminal.
-- <https://github.com/neovim/neovim/blob/v0.11.4/src/nvim/terminal.c#L853-L872>
local MOUSE_KEYCODES = {} ---@type table<string, boolean>
do
  local function add_keycodes(...)
    for _, str in ipairs({ ... }) do
      local code = vim.api.nvim_replace_termcodes(str, true, true, true)
      MOUSE_KEYCODES[code] = true
    end
  end
  -- These have always been supported, ever since the terminal was first introduced:
  -- <https://github.com/neovim/neovim/commit/cdedd89d228a016a4e433968702e9e3ce5165e7d#diff-4907c58e1fe9c69151d51cefc836d3746a91b6a1ad58b33276ee959d2a5d9167R396-R406>
  add_keycodes('<LeftMouse>', '<LeftDrag>', '<LeftRelease>')
  add_keycodes('<MiddleMouse>', '<MiddleDrag>', '<MiddleRelease>')
  add_keycodes('<RightMouse>', '<RightDrag>', '<RightRelease>')
  add_keycodes('<ScrollWheelUp>', '<ScrollWheelDown>') -- used to be called <MouseUp> and <MouseDown>
  -- <https://github.com/neovim/neovim/commit/51403d6d411ca9bc8b4e8d66003a52781e5c698e>
  if utils.has('nvim-0.5.0') then add_keycodes('<MouseMove>') end
  -- <https://github.com/neovim/neovim/commit/21d466c1b985bcb0b80cd71d3b33eef6c24004f1>
  if utils.has('nvim-0.10.0') then add_keycodes('<ScrollWheelRight>', '<ScrollWheelLeft>') end
  -- <https://github.com/neovim/neovim/commit/06a1f82f1cc37225b6acc46e63bd2eb36e034b1a>
  if utils.has('nvim-0.11.0') then
    add_keycodes('<X1Mouse>', '<X1Drag>', '<X1Release>', '<X2Mouse>', '<X2Drag>', '<X2Release>')
  end
end

local got_backslash = false
function dotfiles.reset_terminal_state() got_backslash = false end

local function in_stopped_terminal()
  return vim.fn.mode() == 't'
    and vim.bo.buftype == 'terminal'
    -- This line checks whether the job running in the current terminal buffer has exited or not.
    and vim.fn.jobwait({ vim.bo.channel }, 0)[1] ~= -1
end

local ns_id = vim.api.nvim_create_namespace('dotfiles_fix_terminal_closing')

--- This is a really, really horrible HACK that changes the way `:terminal`
--- buffers are closed when the process running within the terminal terminates.
--- By default, Neovim will not hide the buffer immediately, it will print the
--- exit code of the process, keep the buffer with the process' final output on
--- screen, and keep the user in the TERMINAL mode. However, pressing any keys
--- in the TERMINAL mode now that the process is gone will cause the buffer to
--- be closed with `:bwipeout!`, and if the terminal was opened in a split, this
--- will, of course, close its window. This is known behavior and was complained
--- about countless times since the very dawn of Neovim (e.g. here:
--- <https://github.com/neovim/neovim/issues/5176>), and it is particularly
--- annoying to me since I work with the screen split in two vertical windows
--- all the time. What my hack does is that it catches any key that is pressed
--- within a terminal window with a dead process, and "overtakes" Neovim by
--- closing the window using my `:Bwipeout` command instead of the built-in
--- `:bwipeout`, which does not disrupt the window layout.
---
--- Catching all key presses is possible with the |vim.on_key()| API which was
--- added in Nvim v0.5.0 and briefely existed under a different name before it
--- got renamed in v0.5.1. However, it is too indiscriminate for my use-case
--- (e.g. the callback cannot be registered to only listen for events in a
--- specific window or buffer), so the code needs some extra checks to work
--- correctly.
---
--- This whole function is invoked in an autocommand below on the `TermClose`
--- event, which is triggered when the job in the terminal exits, but it might
--- be triggered when the terminal is not focused, e.g. if the terminal job has
--- ended while the user was editing another buffer, so we *must* check if the
--- cursor is currently within a terminal with a finished job before activating
--- the hack. Also, it is still possible to leave the TERMINAL mode in such a
--- stopped terminal with <C-\><C-N> and return to it again by pressing `i`, and
--- the hack needs to handle closing the buffer in this case as well, so it is
--- also invoked on the `TermEnter` event, which is triggered when entering the
--- TERMINAL mode. Lastly, we watch for the `TermLeave` event too, to unregister
--- the key listener once a terminal buffer gets closed.
function dotfiles.fix_terminal_closing()
  local on_key = vim.on_key or vim.register_keystroke_callback

  if not in_stopped_terminal() then
    -- Passing `nil` unregisters the callback associated with the given namespace ID.
    on_key(nil, ns_id)
    return
  end

  -- Activate the hack! The callback roughly needs to handle all possible paths
  -- within Nvim's terminal state handler function:
  -- <https://github.com/neovim/neovim/blob/v0.11.4/src/nvim/terminal.c#L847-L933>
  on_key(function(key, _typed)
    -- Double-check that the user is still within a stopped terminal. This might
    -- not be the case if a plugin used the `TermClose` autocommand to
    -- immediately close the terminal buffer, for instance fzf does that.
    if not in_stopped_terminal() then
      on_key(nil, ns_id)
      return
    end

    -- The internal encodings of keycodes are guaranteed to be stable:
    -- <https://github.com/vim/vim/issues/1810>,
    -- <https://github.com/vim/vim/commit/8858498516108432453526f07783f14c9196e112>,
    -- <https://github.com/neovim/neovim/commit/0fb695df8ae75b69e4c72ef75e943f4d454a38ef>.
    -- These constants were taken from:
    -- <https://github.com/neovim/neovim/blob/v0.11.4/src/nvim/keycodes.h>.
    local K_SPECIAL = 0x80
    local KS_MODIFIER = 252
    local KS_EXTRA = 253
    local KE_LUA = 103
    local KE_COMMAND = 104
    local MOD_MASK_CTRL = 0x04

    -- Unpack the modifiers like Ctrl or Shift and strip them from the `key`,
    -- which are encoded into a byte string here:
    -- <https://github.com/neovim/neovim/blob/v0.11.4/src/nvim/keycodes.c#L388-L393>.
    local modifiers = nil
    if key:byte(1) == K_SPECIAL and key:byte(2) == KS_MODIFIER then
      modifiers = key:byte(3)
      key = key:sub(4)
    end

    -- Ignore all mouse-related keycodes and let the C code in Nvim process
    -- those. Neither of them will cause the terminal to be closed, even if the
    -- process has stopped.
    if MOUSE_KEYCODES[key] then return end
    -- Also ignore the special keycodes that <Cmd> and Lua mappings use.
    if key == string.char(K_SPECIAL, KS_EXTRA, KE_COMMAND) then return end
    if key == string.char(K_SPECIAL, KS_EXTRA, KE_LUA) then return end

    local ctrl = modifiers == MOD_MASK_CTRL
    -- Normalize the short forms of CTRL+[A-Z] keys to make the rest of the code
    -- more straightforward, by doing the reverse of what this function does:
    -- <https://github.com/neovim/neovim/blob/v0.11.4/src/nvim/getchar.c#L1521>.
    -- To give you an idea, the key combination CTRL+A can be represented as
    -- either a byte string `K_SPECIAL KS_MODIFIER MOD_MASK_CTRL <41>` (the
    -- ASCII code for the letter A is 0x41), or as just the byte `<01>`. Usually
    -- terminals produce the shorter form for CTRL plus a letter (CTRL+A
    -- produces <01>, CTRL+B produces <02>, CTRL+C -- <03> and so on, and so
    -- on), but it is necessary to correctly handle both forms, since we receive
    -- the longer one in Kitty after Nvim added support for the Kitty Keyboard
    -- Protocol in v0.11.0: <https://github.com/neovim/neovim/pull/32038>.
    if #key == 1 and key:byte(1) < 0x20 then
      key = string.char(0x40 + key:byte(1))
      ctrl = true
    end

    if not got_backslash then
      if ctrl and key == '\\' then
        got_backslash = true
        return
      end
    else
      got_backslash = false
      if ctrl and key == 'N' then return end
      -- <C-\><C-O> was added only in v0.8.0:
      -- <https://github.com/neovim/neovim/commit/9092540315bef8a685a06825073d05c394bf6575>
      if ctrl and key == 'O' and utils.has('nvim-0.8.0') then return end
    end

    -- If this point has been reached, we are sure that letting Nvim process
    -- this key will cause the terminal buffer to be wiped out. So, we must beat
    -- Neovim to it -- we close the buffer ourselves first! And yes, Nvim will
    -- literally `eval()` a line of Vimscript code to wipe out the buffer:
    -- <https://github.com/neovim/neovim/blob/v0.11.4/src/nvim/terminal.c#L774-L781>

    if utils.has('nvim-0.6.0') and not utils.has('nvim-0.8.0') then
      -- Unfortunately, a nasty use-after-free bug was introduced in v0.6.0[1]
      -- and has existed for some time until v0.8.0[2], due to which wiping out
      -- a closing terminal buffer would cause an immediate segfault. To work
      -- around it, I only perform the first half of what `:Bwipeout` does: hide
      -- the buffer from every window which was showing it, so that deleting
      -- the buffer does not take down the windows with it, and then let the C
      -- code in the Nvim core execute `:bwipeout` on the terminal buffer as it
      -- would normally do.
      -- [1]: <https://github.com/neovim/neovim/commit/14def4d2271a5bc5e6e6e774d291a9e0fd2477e0>
      -- [2]: <https://github.com/neovim/neovim/commit/ff6b8f54359037790b300cb06a025f84f11d829a>
      local term_buf = vim.api.nvim_get_current_buf()
      vim.cmd('setlocal bufhidden=hide') -- Ensure that the terminal buffer stays loaded
      vim.call('dotfiles#bufclose#hide', term_buf)

      -- The C also code expects the terminal buffer to be the currently focused
      -- one when running `:bwipeout!`, but we have already hidden it
      -- everywhere! The solution? Create and focus a sacrificial floating
      -- window (floats were added in v0.4.0) that will house the terminal for a
      -- brief moment before its imminent deletion.
      local tmp_win = vim.api.nvim_open_win(term_buf, --[[ enter ]] true, {
        relative = 'cursor',
        row = 0,
        col = 0,
        style = 'minimal',
        width = 1,
        height = 1,
      })

      vim.schedule(function()
        -- Sometimes `:bwipeout!` will not take down the sacrificial window with
        -- the buffer, so close the window on the next event loop tick if it is
        -- still around.
        if vim.api.nvim_win_is_valid(tmp_win) then
          vim.api.nvim_win_close(tmp_win, --[[ force ]] true)
        end
      end)
    else
      -- In versions before 0.6.0 and after 0.8.0 this is only a matter of
      -- calling a single trusty command.
      vim.cmd('Bwipeout!')
    end
  end, ns_id)
end

-- This hack is designed to work in Nvim versions as old as v0.5.0, in which
-- the API for adding Lua autocommands has not been added yet, so unfortunately
-- I have to use a bit of inline Vimscript here.
vim.cmd([[
  augroup dotfiles_fix_terminal_closing
    autocmd!
    autocmd TermEnter * lua dotfiles.reset_terminal_state()
    autocmd TermClose,TermEnter,TermLeave * lua dotfiles.fix_terminal_closing()
  augroup END
]])
