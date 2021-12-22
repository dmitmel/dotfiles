local M = require('dotfiles.autoload')('dotfiles.completion')

-- TODO: Dot repeat @. optimization
-- TODO: Contribute a configuration for disabling undo breaks
-- TODO: Rewrite cmp.matcher in C++ for SPEED
-- TODO: dedup in both directions

-- TODO: vim.regex
-- match()
-- matchend()
-- matchlist()
-- matchstr()
-- matchstrpos()
-- split()
-- substitute()

local cmp = require('cmp')
local utils_vim = require('dotfiles.utils.vim')
local utils = require('dotfiles.utils')
local lsp_global_settings = require('dotfiles.lsp.global_settings')

-- """"""Polyfills"""""" {{{
if cmp.get_selected_entry == nil then
  function cmp.get_selected_entry()
    return cmp.core.view:get_selected_entry()
  end
end
if cmp.get_active_entry == nil then
  function cmp.get_active_entry()
    return cmp.core.view:get_active_entry()
  end
end
-- }}}

--[[
function cmp.core.view.custom_entries_view.entries_win:has_scrollbar()
  return false
end
--]]

cmp.setup({
  experimental = {
    -- The new floating window menu breaks undo history when <CR> is pressed.
    -- <https://github.com/neovim/neovim/issues/11439>
    native_menu = true,
  },

  sources = {
    {
      name = 'nvim_lsp',
      menu_label = function(source)
        local result = 'LS'
        local client = source and source.source and source.source.client
        if client then
          local label = client.config and client.config.completion_menu_label
          if label then
            result = result .. '/' .. label
          end
        end
        return result
      end,
    },

    {
      name = 'vsnip',
      menu_label = 'Snip',
    },

    {
      name = 'path',
      menu_label = 'Path',
    },

    {
      -- In case our buffer word source is ever desired, see:
      -- <https://github.com/neovim/neovim/blob/v0.5.0/src/nvim/charset.c#L831-L843>
      -- <https://github.com/neovim/neovim/blob/v0.5.0/src/nvim/charset.c#L83-L262>
      -- <https://github.com/neoclide/coc.nvim/blob/03c9add7cd867a013102dcb45fb4e75304d227d7/src/model/document.ts>
      -- <https://github.com/neoclide/coc.nvim/blob/03c9add7cd867a013102dcb45fb4e75304d227d7/src/model/chars.ts>
      name = 'buffer',
      menu_label = 'Buf',
      option = {
        -- NOTE: This pattern is actually faster than the default one because
        -- of its syntactical simplificty.
        keyword_pattern = [[\k\+]],
        -- NOTE: This function is invoked every time the (auto-)completion menu
        -- is opened! Don't do anything slow here. Also, as another note,
        -- despite the constant API calls here, rewriting this function in
        -- Vimscript won't help (I have already tried).
        get_bufnrs = function()
          local current_bufnr = vim.api.nvim_get_current_buf()
          local visible_bufs = {}
          local cmp_menu_win = cmp.core.view.custom_entries_view.entries_win.win
          for _, winid in ipairs(vim.api.nvim_list_wins()) do
            if winid ~= cmp_menu_win then
              visible_bufs[vim.api.nvim_win_get_buf(winid)] = true
            end
          end
          local result = {}
          -- TODO: Merge this logic with `lsp_ignition.should_attach(bufnr)`.
          for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
            if not vim.api.nvim_buf_is_loaded(bufnr) then
              goto continue
            end
            if not visible_bufs[bufnr] then
              if not vim.api.nvim_buf_get_option(bufnr, 'buflisted') then
                goto continue
              end
            end
            local bt = vim.api.nvim_buf_get_option(bufnr, 'buftype')
            if bt == 'help' or bt == 'quickfix' or bt == 'terminal' or bt == 'prompt' then
              goto continue
            end
            if vim.api.nvim_buf_get_option(bufnr, 'binary') then
              goto continue
            end
            if lsp_global_settings.MAX_FILE_SIZE then
              local file_size = utils_vim.buf_get_inmemory_text_byte_size(bufnr)
              if file_size > lsp_global_settings.MAX_FILE_SIZE then
                goto continue
              end
            end
            table.insert(result, bufnr)
            ::continue::
          end
          return result
        end,
      },
    },
  },

  mapping = {
    ['<Tab>'] = cmp.mapping(function(fallback)
      local selected_entry = cmp.get_selected_entry()
      if not selected_entry and utils_vim.is_truthy(vim.call('vsnip#available', 1)) then
        vim.fn.feedkeys(utils_vim.replace_keys('<Plug>(vsnip-jump-next)'), '')
      elseif cmp.visible() then
        cmp.select_next_item()
      else
        fallback()
      end
    end, { 'i', 's' }),

    ['<S-Tab>'] = cmp.mapping(function(fallback)
      local selected_entry = cmp.get_selected_entry()
      if not selected_entry and utils_vim.is_truthy(vim.call('vsnip#available', -1)) then
        vim.fn.feedkeys(utils_vim.replace_keys('<Plug>(vsnip-jump-prev)'), '')
      elseif cmp.visible() then
        cmp.select_prev_item()
      else
        fallback()
      end
    end, { 'i', 's' }),

    ['<C-Space>'] = cmp.mapping.complete(),
    ['<CR>'] = cmp.mapping.confirm(),
    ['<C-y>'] = cmp.mapping.confirm(),
    ['<C-e>'] = cmp.mapping.abort(),
    ['<Esc>'] = cmp.mapping.close(),
  },

  snippet = {
    expand = function(args)
      vim.call('vsnip#anonymous', args.body)
    end,
  },

  completion = {
    keyword_pattern = [[\k\+]],

    -- Currently this doesn't work nicely under nvim-cmp, but coc.nvim actually
    -- does roughly the same. Taken from <https://github.com/timbedard/dotfiles/blob/089422aad4705e029d33729079ab5e685e2ebe1a/config/nvim/lua/plugins.lua#L316>
    -- keyword_length = 0;

    -- Use whatever I have configured in `nvim/plugin/completion.vim`.
    completeopt = vim.o.completeopt,
  },

  preselect = cmp.PreselectMode.None,

  confirmation = {
    -- What to do when the cursor is positioned inside an existing word.
    -- Beware: <https://www.youtube.com/watch?v=wCllU4YkxBk&t=107s>.
    default_behavior = cmp.ConfirmBehavior.Replace,
  },

  -- Reduce distractions.
  documentation = false,

  sorting = {
    comparators = {
      cmp.config.compare.offset,
      cmp.config.compare.exact,
      cmp.config.compare.score,
      -- cmp.config.compare.kind,
      cmp.config.compare.sort_text,
      -- cmp.config.compare.length,
      cmp.config.compare.order,
    },
  },

  formatting = {
    -- Remove strikethroughs of deprecated items because, apparently, those are
    -- implemented with goddamn modifier characters:
    -- <https://github.com/hrsh7th/nvim-cmp/blob/24406f995ea20abba816c0356ebff1a025c18a72/lua/cmp/utils/str.lua#L58-L73>.
    deprecated = false,

    -- See `:h complete-items` and:
    -- <https://github.com/neoclide/coc.nvim/blob/30a46412ebc66c0475bca7e49deb119fb14f0f00/src/sources/source-language.ts#L248-L308>
    -- <https://github.com/hrsh7th/nvim-cmp/blob/405581e7405da53924fd9723e3e42411b66d545d/lua/cmp/entry.lua#L188-L255>
    format = function(entry, vim_item)
      local comp_item = entry.completion_item
      local kind = entry:get_kind()
      local source_opts = entry.source:get_config()

      -- A short code archeology moment: the addition of the question mark to
      -- "optional" properties determined with a heuristic check of
      -- `completion_item.data.optional` like in coc.nvim here:
      -- <https://github.com/neoclide/coc.nvim/blob/30a46412ebc66c0475bca7e49deb119fb14f0f00/src/sources/source-language.ts#L306>,
      -- is not necessary. Well, first of all, the `data` property is supposed
      -- to be server-specific, so we can't do much with it in the general
      -- case, but what's more interesting is why the linked snippet was
      -- introduced in the first place. After some digging through quite a
      -- chain git blames I have found the responsible commit:
      -- <https://github.com/neoclide/coc.nvim/commit/a05484d1d4434e803ccb2d81f4974a73369823b8>.
      -- Among other things it moves the actual addition of that question mark
      -- from the (at that time) integrated TSServer adapter code into the
      -- common completion code, while making the adapter set the mentioned
      -- before `optional` flag. This probably got into that commit as a short
      -- unrelated refactor because the version of the HTML language server
      -- from `yarn.lock` doesn't even contain the word `optional`. However,
      -- both the modern coc-tsserver extension and the TS language server
      -- append the question mark on their side to `completion_item.label`:
      -- <https://github.com/neoclide/coc-tsserver/blob/66ae279b1a3441ad5ca77d47934f99f039cd1e0b/src/server/utils/completionItem.ts#L75-L78>,
      -- <https://github.com/typescript-language-server/typescript-language-server/blob/3c457111969899d7cd72291db1e6dddb5ac68cf6/src/completion.ts#L59-L65>,
      -- and given that that heuristic was added for the TS language provider,
      -- it is now basically obsolete.

      -- <https://github.com/neoclide/coc.nvim/blob/30a46412ebc66c0475bca7e49deb119fb14f0f00/src/sources/source-language.ts#L257>
      -- <https://github.com/hrsh7th/nvim-cmp/blob/405581e7405da53924fd9723e3e42411b66d545d/lua/cmp/entry.lua#L242>
      vim_item.kind = lsp_global_settings.COMPLETION_KIND_LABELS[kind]
        or lsp_global_settings.FALLBACK_COMPLETION_KIND_LABEL

      local menu_labels = {}

      -- <https://github.com/neoclide/coc.nvim/blob/30a46412ebc66c0475bca7e49deb119fb14f0f00/src/sources/source-language.ts#L256>
      if type(source_opts.menu_label) == 'string' then
        table.insert(menu_labels, '[' .. source_opts.menu_label .. ']')
      elseif type(source_opts.menu_label) == 'function' then
        table.insert(menu_labels, '[' .. source_opts.menu_label(entry.source) .. ']')
      end

      -- <https://github.com/neoclide/coc.nvim/blob/30a46412ebc66c0475bca7e49deb119fb14f0f00/src/sources/source-language.ts#L275-L285>
      if not utils.is_nil(comp_item.detail) then
        table.insert(menu_labels, comp_item.detail)
      end
      -- From LSP 3.17:
      if not utils.is_nil(comp_item.labelDetails) then
        if not utils.is_nil(comp_item.labelDetails.detail) then
          table.insert(menu_labels, comp_item.labelDetails.detail)
        end
        if not utils.is_nil(comp_item.labelDetails.description) then
          table.insert(menu_labels, comp_item.labelDetails.description)
        end
      end

      vim_item.menu = table.concat(menu_labels, ' ')

      return vim_item
    end,
  },
})

return M
