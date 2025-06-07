if dotplug.has('gitsigns.nvim') then
  require('gitsigns').setup({
    signs_staged_enable = false,
    signs = {
      add = { text = vim.g.gitgutter_sign_added },
      delete = { text = vim.g.gitgutter_sign_removed },
      topdelete = { text = vim.g.gitgutter_sign_removed_first_line },
      change = { text = vim.g.gitgutter_sign_modified },
      changedelete = { text = vim.g.gitgutter_sign_modified_removed },
      untracked = { text = vim.g.gitgutter_sign_added },
    },
    sign_priority = vim.g.gitgutter_sign_priority,

    preview_config = {
      border = 'none',
      col = 0,
      row = 1,
    },
  })
end
