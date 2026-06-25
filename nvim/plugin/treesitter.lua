if vim.treesitter == nil then return end

local utils = require('dotfiles.utils')
local augroup = utils.augroup('dotfiles.treesitter')

if vim.show_pos and vim.treesitter.inspect_tree then
  vim.api.nvim_create_user_command('HLT', 'Inspect', {})
  vim.keymap.set('n', '<leader>hlt', vim.show_pos)
  vim.keymap.set('n', '<F12>', vim.treesitter.inspect_tree)
end

---@param bufnr integer?
---@param lang string?
---@return vim.treesitter.LanguageTree?
---@return string?
function dotfiles.maybe_get_treesitter_parser(bufnr, lang)
  if utils.has('nvim-0.11.0') then
    return vim.treesitter.get_parser(bufnr, lang, { error = false })
  else
    local ok, parser_or_error = pcall(vim.treesitter.get_parser, bufnr, lang)
    if ok then
      return parser_or_error, nil
    else
      return nil, parser_or_error --[[@as string]]
    end
  end
end

---@param bufnr integer?
---@param lang string?
---@return boolean
function dotfiles.treesitter_parser_exists(bufnr, lang)
  local _, err = dotfiles.maybe_get_treesitter_parser(bufnr, lang)
  return err == nil
end

if vim.treesitter.start and vim.treesitter.stop and vim.treesitter.highlighter then
  -- Toggle treesitter highlighting for the current buffer.
  vim.keymap.set('n', '<leader>ht', function()
    local bufnr = vim.api.nvim_get_current_buf()
    if vim.treesitter.highlighter.active[bufnr] then
      vim.treesitter.stop(bufnr)
    else
      local _, err_msg = dotfiles.maybe_get_treesitter_parser(bufnr)
      if err_msg then
        vim.notify(('[vim.treesitter] %s'):format(err_msg), vim.log.levels.ERROR)
      else
        vim.treesitter.start(bufnr)
      end
    end
  end)
end

vim.treesitter._really_start = vim.treesitter._really_start or vim.treesitter.start
function vim.treesitter.start(bufnr, lang)
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
    if caller.source == '@' .. vim.fs.normalize('$VIMRUNTIME/ftplugin/markdown.lua') then return end
  end
  -- No exit route was taken -- we can start Treesitter.
  return vim.treesitter._really_start(bufnr, lang)
end

---@return vim.treesitter.LanguageTree?
local function parse_current_buffer()
  local parser, parser_error = dotfiles.maybe_get_treesitter_parser(0)
  if parser then
    parser:parse({ vim.fn.line('w0') - 1, vim.fn.line('w$') })
    return parser
  else
    vim.notify(parser_error, vim.log.levels.ERROR)
    return nil
  end
end

if dotplug.has('nvim-treesitter') then
  if vim.fn.executable('tree-sitter') == 0 then
    vim.notify(
      'tree-sitter CLI must be installed for building parsers downloaded with nvim-treesitter!',
      vim.log.levels.ERROR
    )
  else
    -- NOTE: Keep this list sorted, please.
    local ensure_installed = {
      'bash',
      'c',
      'cmake',
      'comment',
      'cpp',
      'css',
      'html',
      'ini',
      'javascript',
      'jq',
      'jsdoc',
      'json',
      'lua',
      'luadoc',
      'luap',
      'make',
      'markdown',
      'markdown_inline',
      'perl',
      'printf',
      'python',
      'query',
      'regex',
      'rust',
      'scss',
      'toml',
      'tsx',
      'typescript',
      'typst',
      'vim',
      'vimdoc',
      'xml',
      'yaml',
      'zsh',
    }

    require('nvim-treesitter').install(ensure_installed, {
      max_jobs = vim.uv.available_parallelism() * 2,
    })
  end

  augroup:autocmd('FileType', function(event)
    local filetype = event.match
    if
      utils.is_truthy(vim.g.dotfiles_treesitter_highlighting)
      or (filetype == 'query' or filetype == 'nix')
    then
      if dotfiles.treesitter_parser_exists(event.buf, filetype) then
        vim.treesitter.start(event.buf, filetype)
      end
    end
  end, { desc = 'start Treesitter highlighting in the current buffer' })

  augroup:autocmd('FileType', function(event)
    local bo = vim.bo[event.buf]
    local lang = vim.treesitter.language.get_lang(bo.filetype)
    if lang and vim.treesitter.query.get(lang, 'indents') then
      bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
  end, { desc = 'enable indentation with Treesitter for the current buffer (if supported)' })

  require('nvim-ts-autotag').setup()

  require('nvim-treesitter-textobjects').setup({
    select = { lookahead = true, include_surrounding_whitespace = false },
    move = { set_jumps = true },
  })

  for lhs, query in pairs({
    ['af'] = '@function.outer',
    ['if'] = '@function.inner',
    ['ac'] = '@class.outer',
    ['ic'] = '@class.inner',
    ['ab'] = '@block.outer',
    ['ib'] = '@block.inner',
  }) do
    vim.keymap.set({ 'x', 'o' }, lhs, function()
      if parse_current_buffer() then
        require('nvim-treesitter-textobjects.select').select_textobject(query, 'textobjects')
      end
    end)
  end
end

if utils.has('nvim-0.10.0') and utils.is_truthy(vim.g.dotfiles_highlight_url_under_cursor) then
  local clear_underlined_urls ---@type function|nil

  augroup:autocmd({ 'CursorMoved', 'CursorMovedI', 'WinEnter', 'BufEnter' }, function()
    if clear_underlined_urls ~= nil then
      clear_underlined_urls()
      clear_underlined_urls = nil
    end

    local winnr = vim.api.nvim_get_current_win()
    local bufnr = vim.api.nvim_win_get_buf(winnr)
    local line, col = unpack(vim.api.nvim_win_get_cursor(winnr))
    local row = line - 1

    -- Terminology of Treesitter, as far as I understand it:
    -- 1. highlighter -- applies queries to the document to find what to highlight
    -- 2. language tree -- a tree with the root language of the document and injected languages
    -- 3. tree -- the structure representing the abstract syntax tree
    -- 4. matches -- results of applying queries to the tree
    -- 5. captures -- nodes of the tree collected in a match, which can be highlighted together

    local buf_highlighter = vim.treesitter.highlighter.active[bufnr]
    if not buf_highlighter then return end

    local cursor_range = { row, col, row, col + 1 }
    local lang_tree = buf_highlighter.tree:language_for_range(cursor_range)
    local query = vim.treesitter.query.get(lang_tree:lang(), 'highlights')
    if not query then return end

    local tree = lang_tree:tree_for_range(cursor_range)
    if not tree then return end

    local ns_id = vim.api.nvim_create_namespace('dotfiles_url_under_cursor')
    local extmarks = {} ---@type integer[]

    for id, node, _metadata, _match in query:iter_captures(tree:root(), bufnr, row, row + 1) do
      local name = query.captures[id]
      if vim.treesitter.node_contains(node, cursor_range) and name:match('[._]url$') then
        local start_row, start_col, end_row, end_col = node:range()
        extmarks[#extmarks + 1] = vim.api.nvim_buf_set_extmark(bufnr, ns_id, start_row, start_col, {
          end_row = end_row,
          end_col = end_col,
          hl_group = 'ReallyUnderlined',
        })
      end
    end

    clear_underlined_urls = function()
      for _, id in ipairs(extmarks) do
        vim.api.nvim_buf_del_extmark(bufnr, ns_id, id)
      end
    end
  end, { desc = 'highlight the URL under the cursor' })
end

do
  ---@type table<integer, table<TSNode|nil>>
  local selections = {}
  -- TODO: check bufnr and changedtick
  -- TODO: fails when you start visual mode, don't select anything and press <C-space>
  -- TODO: doesn't increase selection when a node which ends with a Unicode character is selected

  -- Get the range of the current visual selection.
  --
  -- The range starts with 1 and the ending is inclusive.
  ---@return integer, integer, integer, integer
  local function visual_selection_range()
    local _, cursor_row, corsor_col, _ = unpack(vim.fn.getpos('.'))
    local _, other_row, other_col, _ = unpack(vim.fn.getpos('v'))
    if other_row < cursor_row or (other_row == cursor_row and other_col <= corsor_col) then
      return other_row, other_col, cursor_row, corsor_col
    else
      return cursor_row, corsor_col, other_row, other_col
    end
  end

  ---@param node TSNode
  local function get_vim_range(node)
    local start_row, start_col, end_row, end_col = node:range()
    start_row = start_row + 1
    start_col = start_col + 1
    end_row = end_row + 1

    -- TODO: what?
    -- <https://github.com/nvim-treesitter/nvim-treesitter/commit/e4c56e691a56dfb25ead19aad7fa6b08879b569f>
    if end_col == 0 then
      end_row = end_row - 1
      -- Use the value of the last col of the previous row instead.
      end_col = vim.fn.col({ end_row, '$' }) - 1
      end_col = math.max(end_col, 1)
    end

    return start_row, start_col, end_row, end_col
  end

  --- Based on <https://github.com/nvim-treesitter/nvim-treesitter-textobjects/blob/b54cec389e98c5b0babbe618773acec927437cab/lua/nvim-treesitter-textobjects/select.lua#L5-L33>.
  ---@param node TSNode
  local function select_node(node)
    if vim.api.nvim_get_mode().mode ~= 'v' then vim.cmd('normal! v') end

    local start_row, start_col, end_row, end_col = get_vim_range(node)
    if vim.o.selection == 'exclusive' then end_col = end_col + 1 end

    vim.fn.cursor(start_row, start_col)
    vim.cmd('normal! o')
    vim.fn.cursor(end_row, end_col)
  end

  local function start_selection()
    if not parse_current_buffer() then return end

    local node = vim.treesitter.get_node({ ignore_injections = false, include_anonymous = false })
    if not node then return end

    local buf = vim.api.nvim_get_current_buf()
    selections[buf] = { [1] = node }
    select_node(node)
  end

  local function expand_selection()
    local lang_tree = parse_current_buffer()
    if not lang_tree then return end

    local buf = vim.api.nvim_get_current_buf()
    local nodes = selections[buf]

    local csrow, cscol, cerow, cecol = visual_selection_range()
    local visual_ts_range = { csrow - 1, cscol - 1, cerow - 1, cecol }

    local srow, scol, erow, ecol = get_vim_range(nodes[#nodes])
    local range_matches = srow == csrow and scol == cscol and erow == cerow and ecol == cecol

    -- Initialize incremental selection with current selection
    if not nodes or #nodes == 0 or not range_matches then
      local node = lang_tree:named_node_for_range(visual_ts_range, { ignore_injections = false })
      if node then
        select_node(node)
        if nodes and #nodes > 0 then
          table.insert(selections[buf], node)
        else
          selections[buf] = { [1] = node }
        end
      end
      return
    end

    -- Find a node that changes the current selection.
    local node = nodes[#nodes] ---@type TSNode
    while true do
      local parent = node:parent()

      if not parent then
        local current_parser = lang_tree:language_for_range(visual_ts_range)
        local parent_parser = current_parser:parent()
        if not parent_parser then return end
        parent = parent_parser:named_node_for_range(visual_ts_range)
        if not parent then return end
      end
      node = parent

      local srow, scol, erow, ecol = get_vim_range(node)
      local same_range = (srow == csrow and scol == cscol and erow == cerow and ecol == cecol)
      if not same_range then
        if node ~= nodes[#nodes] then table.insert(nodes, node) end
        select_node(node)
        return
      end
    end
  end

  local function shrink_selection()
    local buf = vim.api.nvim_get_current_buf()
    local nodes = selections[buf]
    if not nodes or #nodes < 2 then return end

    table.remove(selections[buf])
    local node = nodes[#nodes] ---@type TSNode
    select_node(node)
  end

  vim.keymap.set('n', '<C-space>', start_selection, { desc = 'start incremental selection' })
  vim.keymap.set('x', '<C-space>', expand_selection, { desc = 'expand selection to parent node' })
  vim.keymap.set('x', '<BS>', shrink_selection, { desc = 'shrink selection to an inner node' })

  augroup:autocmd('BufLeave', function() end)
end

if dotplug.has('nvim-ts-autotag') then require('nvim-ts-autotag').setup() end
