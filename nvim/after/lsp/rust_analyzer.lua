-- <https://github.com/neovim/nvim-lspconfig/blob/master/lsp/rust_analyzer.lua>

---@type dotfiles.lsp.Config
local config = {
  cmd = { 'rust-analyzer' },
  filetypes = { 'rust' },
  -- TODO: nvim-lspconfig's configuration for rust_analyzer contains a long and
  -- convoluted function for detection of root_dir, apparently to support
  -- multi-crate (Cargo workspace) projects. I'll figure that out later.
  root_markers = { 'rust-project.json', 'Cargo.toml' },
}

return config
