-- <https://github.com/neovim/nvim-lspconfig/blob/master/lsp/clangd.lua>
-- <https://github.com/clangd/vscode-clangd/blob/master/src/clangd-context.ts>
-- <https://github.com/clangd/coc-clangd/blob/master/src/ctx.ts>

---@type dotfiles.lsp.Config
return {
  cmd = {
    'clangd',
    -- Enables `.clangd` configuration files, see <https://clangd.llvm.org/config>.
    '--enable-config',
    -- Which binaries of compilers clangd is allowed to run to determine the system
    -- include paths and other such details about the compiler.
    '--query-driver=/usr/bin/*',
    '--query-driver=/usr/local/bin/*',
    '--header-insertion=never',
    '--log=error',
    '--offset-encoding=utf-8',
  },
  filetypes = { 'c', 'cpp', 'objc', 'objcpp' },
  root_markers = {
    '.clangd',
    '.clang-tidy',
    '.clang-format',
    'compile_commands.json',
    'compile_flags.txt',
    '.git',
  },
  settings_sections = { 'clangd' },
}
