-- <https://github.com/neovim/nvim-lspconfig/blob/master/lsp/eslint.lua>
-- <https://github.com/neovim/nvim-lspconfig/blob/master/lua/lspconfig/configs/eslint.lua>

---@type dotfiles.lsp.Config
return {
  cmd = { 'vscode-eslint-language-server', '--stdio' },
  filetypes = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact' },
  -- <https://eslint.org/docs/user-guide/configuring/configuration-files#configuration-file-formats>
  root_markers = {
    '.eslintrc.js',
    '.eslintrc.cjs',
    '.eslintrc.yaml',
    '.eslintrc.yml',
    '.eslintrc.json',
    'package.json',
    '.git',
  },

  settings = {
    -- Disable registration of ESLint as a document formatter that applies auto
    -- fixes because running auto fixes is handled by my `:LspFixAll` command.
    -- This is also done because `conform.nvim` does not let me control the
    -- order in which formatters are run if multiple formatters are registered
    -- for a single file type.
    format = false,
  },

  build_settings = function(ctx)
    -- The ESLint language server actually handles its settings in a rather
    -- weird way. What is sent over the wire is not the settings you might
    -- typically find in `.vscode/settings.json`, but an object of this form:
    -- <https://github.com/microsoft/vscode-eslint/blob/release/3.0.16/%24shared/settings.ts#L166>.
    -- It needs to be constructed by the client from the user-visible settings:
    -- <https://github.com/microsoft/vscode-eslint/blob/release/3.0.16/client/src/client.ts#L676>.
    -- This is an undocumented implementation detail of the VSCode extension and
    -- its client-server model, but it more or less matches the publicly
    -- documented user settings, so I extract it from the `eslint` section of
    -- settings files. However, `nvim-lspconfig` provides the correct default
    -- values for all fields of this settings object, but without the `eslint`
    -- section, so settings coming from LSP configuration are merged as-is:
    -- <https://github.com/neovim/nvim-lspconfig/blob/5939928504f688f8ae52db30d481f6a077921f1c/lsp/eslint.lua#L87>.
    ctx.settings:merge(ctx.new_settings:get(ctx.step ~= 'lspconfig' and 'eslint' or ''))

    if ctx.step == 'generated' then
      local folder = (ctx.scope_uri and ctx.client)
        and require('dotfiles.lsp_extras').find_workspace_folder(ctx.scope_uri, ctx.client)
      ctx.settings:set('workspaceFolder', folder)
    end
  end,
}
