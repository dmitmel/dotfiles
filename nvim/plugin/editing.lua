local utils = require('dotfiles.utils')

vim.treesitter._really_start = vim.treesitter._really_start or vim.treesitter.start
function vim.treesitter.start(bufnr, lang) ---@diagnostic disable-line: duplicate-set-field
  -- I really don't like that Treesitter is being shoved in my face without an
  -- option to turn it off, mainly because it is still far from a silver-bullet
  -- solution: as of Neovim 0.11 it is still slower than the old regexp engine
  -- (try scrolling with the mouse wheel with Treesitter on), and still exhibits
  -- some nasty bugs such as flickering while the text is being edited (see
  -- <https://github.com/neovim/neovim/issues/32660>) -- those are deal-breakers
  -- for me, in this regard I want the syntax highlighting in my editor to just
  -- work(tm). Until the situation improves I am going to disable highlighting
  -- with Treesitter via configuration in plugins that offer options for this,
  -- and forcibly disable it with a patch to `vim.treesitter.start` in plugins
  -- that don't.
  if not utils.is_truthy(vim.g.dotfiles_treesitter_highlighting) then
    -- `start()` can be called without arguments, in which case `bufnr` refers to the current buffer.
    local bo = vim.bo[bufnr or 0]
    if bo.filetype == 'snacks_picker_preview' then -- This should be self-descriptive
      -- This is designed to throw off this check:
      -- <https://github.com/folke/snacks.nvim/blob/bc0630e43be5699bb94dadc302c0d21615421d93/lua/snacks/picker/core/preview.lua#L281>
      error('snacks.nvim must catch this error')
    end
    -- `S` requests the source path, `f` requests reference to the function.
    local caller = debug.getinfo(2, 'Sf')
    -- `open_floating_preview` was changed to use Treesitter in Nvim 0.10:
    -- <https://github.com/neovim/neovim/commit/cfd4a9dfaf5fd900264a946ca33c4a4f26f66a49>,
    -- <https://github.com/neovim/neovim/pull/25073> -- which is actually pretty
    -- cool since treesitter offers superior parsing of Markdown to any of the
    -- regex-based syntax plugins for Markdown. However, there is a problem with
    -- this approach: the code snippets sent back by the Language Servers
    -- usually contain incomplete and/or syntactically invalid code, such as
    -- just the signature of a function without its full body -- LuaLS is a
    -- great example of this (it also inserts type names into the signature,
    -- which Lua obviously lacks the syntax for), and despite the marketing
    -- claims, Treesitter grammars don't handle those well. Hence, for now I
    -- will rely on the good old <https://github.com/plasticboy/vim-markdown>
    -- plugin to handle syntax highlighting in the LSP floating windows.
    if caller.func == vim.lsp.util.open_floating_preview then
      vim.api.nvim_buf_call(bufnr or 0, function()
        -- Run this autocommand manually:
        -- <https://github.com/preservim/vim-markdown/blob/8f6cb3a6ca4e3b6bcda0730145a0b700f3481b51/ftplugin/markdown.vim#L905>.
        -- It is not run because of the logic in the `open_floating_preview`
        -- function: it first creates a floating window and assigns an empty
        -- buffer to it, and only afterwards begins populating the settings of
        -- the said buffer, so `BufWinEnter` is triggered too early, before the
        -- `markdown` filetype is set. Also, the |<buffer=N>| notation does not
        -- make `doautocmd` switch to the specified buffer, so `nvim_buf_call`
        -- is necessary.
        vim.cmd('doautocmd <nomodeline> BufWinEnter <buffer>')
      end)
      return -- And now, just skip this call: <https://github.com/neovim/neovim/blob/v0.11.2/runtime/lua/vim/lsp/util.lua#L1647>
    end
    -- Since v0.10.0 Lua files are always highlighted with Treesitter. This also
    -- means that I cannot easily turn it off for large files, for example. Not
    -- a nice practice at all. I will patch the plain `vim.highlighter.start()`
    -- call out of the default ftplugin and let the nvim-treesitter plugin
    -- manage highlighting of Lua files just like the rest of filetypes. See
    -- <https://github.com/neovim/neovim/commit/f69658bc355e130fc2845a8e0edc8baa4f256329>
    -- <https://github.com/nvim-treesitter/nvim-treesitter/issues/6681> and
    -- <https://github.com/neovim/neovim/pull/26347>.
    -- `$VIMRUNTIME/ftplugin/help.lua` and `$VIMRUNTIME/ftplugin/query.lua` also
    -- enable Treesitter for their respective filetypes, but that is fine by me,
    -- since those give vastly better results than the regexp engine, and don't
    -- suffer from performance issues as much.
    if caller.source == '@' .. vim.fs.normalize('$VIMRUNTIME/ftplugin/lua.lua') then return end
  end
  -- No exit route was taken -- we can start Treesitter.
  return vim.treesitter._really_start(bufnr, lang)
end
