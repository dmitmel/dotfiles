local utils = require('dotfiles.utils')

---@type LazySpec
return {
  'https://github.com/nvim-treesitter/nvim-treesitter',
  build = ':TSUpdate',

  enabled = utils.has('nvim-0.9.0'),

  config = function()
    -- vim.g._ts_force_sync_parsing = true

    local cfg = {
      ensure_installed = {
        'c',
        'lua',
        'vim',
        'vimdoc',
        'query',
        'regex',
        'markdown',
        'markdown_inline',
        'comment',

        'cpp',
        'asm',
        'cmake',
        'css',
        'html',
        'javascript',
        'typescript',
        'tsx',
        'python',
      },

      highlight = {
        enable = false,
      },
    }

    require('nvim-treesitter.configs').setup(cfg)

    local ts_utils = require('nvim-treesitter.ts_utils')
    local ns_id = vim.api.nvim_create_namespace('dotfiles_link_under_cursor')

    -- TODO: <https://github.com/neovim/neovim/blob/master/runtime/lua/vim/ui.lua#L176-L236>

    local function get_captures_at_pos(bufnr, row, col)
      local buf_highlighter = vim.treesitter.highlighter.active[bufnr]

      if not buf_highlighter then return {} end

      local matches = {}

      buf_highlighter.tree:for_each_tree(function(tstree, tree)
        if not tstree then return end

        local root = tstree:root()
        local root_start_row, _, root_end_row, _ = root:range()

        -- Only worry about trees within the line range
        if root_start_row > row or root_end_row < row then return end

        local q = buf_highlighter:get_query(tree:lang())

        -- Some injected languages may not have highlight queries.
        if not q:query() then return end

        local iter = q:query():iter_captures(root, buf_highlighter.bufnr, row, row + 1)

        for id, node, metadata, match in iter do
          if vim.treesitter.is_in_node_range(node, row, col) then
            ---@diagnostic disable-next-line: invisible
            local capture = q._query.captures[id] -- name of the capture in the query
            if capture ~= nil then
              local _, pattern_id = match:info()
              table.insert(matches, {
                capture = capture,
                metadata = metadata,
                lang = tree:lang(),
                id = id,
                pattern_id = pattern_id,
                node = node,
              })
            end
          end
        end
      end)
      return matches
    end

    local function clear_underlined_urls() vim.api.nvim_buf_clear_namespace(0, ns_id, 0, -1) end

    local function underline_url_at_cursor()
      clear_underlined_urls()

      local winnr = vim.api.nvim_get_current_win()
      local bufnr = vim.api.nvim_win_get_buf(winnr)
      local row, col = unpack(vim.api.nvim_win_get_cursor(winnr), 1, 2)

      -- TODO nvim-0.8.0
      -- <https://github.com/neovim/neovim/pull/18232>
      -- <https://github.com/neovim/neovim/pull/18232>
      local captures = get_captures_at_pos(bufnr, row - 1, col)

      for _, capture in ipairs(captures) do
        if capture.capture:match('.*[_.%%]url$') then
          local start_row, start_col, end_row, end_col = capture.node:range()
          vim.api.nvim_buf_set_extmark(bufnr, ns_id, start_row, start_col, {
            end_row = end_row,
            end_col = end_col,
            hl_group = 'TheUnderlined',
          })
        end
      end
    end

    if utils.has('nvim-0.10.0') then
      local group = utils.augroup('dotfiles_link_under_cursor')
      group:autocmd({ 'CursorMoved', 'CursorMovedI', 'BufEnter' }, underline_url_at_cursor)
      group:autocmd({ 'BufLeave' }, clear_underlined_urls)
    end
  end,
}
