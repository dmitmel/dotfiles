How (Neo)Vim configs are sorted:

- `init.vim` - put here only what is absolutely necessary for booting the editor.
- `plugin/` - **actual configuration scripts go here**.
- `dotfiles/` - my custom runtime folders, which will be checked in all entries of `&runtimepath`
  - `plugins-list.vim` - external plugin definitions, put the `Plug` commands here.
  - `vimspector/` - configurations and adapters for [vimspector](https://github.com/puremourning/vimspector).
  - `coc-languages/` - configurations for [coc.nvim](https://github.com/neoclide/coc.nvim).
- `after/` - customizations of scripts in `$VIMRUNTIME` and plugins. This folder will be put at the very end of `&runtimepath`.
  - `lsp/` - **Language Server definitions should go here**, so that they are overlayed on top of those in [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig).
  - `plugin/` - scripts that are deferred until `$VIMRUNTIME` and plugins are loaded. Do not abuse `VimEnter` for the purpose of patching other scripts, use this folder for this!

Sign priorities:

| Kind        | Priority |
| ----------- | -------- |
| git signs   | 3        |
| diagnostics | 4-8      |
| vimspector  | 9        |
