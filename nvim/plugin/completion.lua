-- TODO: Make a PR to neovim for vim.regex improvements:
-- match() matchend() matchlist() matchstr() matchstrpos() split() substitute()

local utils = require('dotfiles.utils')

if not dotplug.has('blink.cmp') then return end

if dotplug.has('LuaSnip') then
  require('luasnip.loaders.from_snipmate').lazy_load()
  utils.augroup('dotfiles_snippets'):autocmd({ 'InsertEnter', 'InsertLeave' }, function()
    local LuaSnip = require('luasnip')
    if LuaSnip.get_active_snip() ~= nil and not LuaSnip.in_snippet() then
      LuaSnip.unlink_current()
    end
  end)
end

---@param distance number
---@return fun(cmp: blink.cmp.API): boolean
local function scroll_page(distance)
  return function(cmp)
    if not cmp.is_menu_visible() then return false end
    vim.schedule(function()
      local list = require('blink.cmp.completion.list')
      if #list.items == 0 or list.context == nil then
        return
      elseif list.selected_item_idx == nil then
        return list.select(distance < 0 and #list.items or 1)
      else
        local page_size = require('blink.cmp.completion.windows.menu').win:get_height()
        return list.select(
          utils.clamp(list.selected_item_idx + page_size * distance, 1, #list.items)
        )
      end
    end)
    return true
  end
end

-- NOTE: <https://www.youtube.com/watch?v=wCllU4YkxBk&t=107s>
-- Default configuration: <https://cmp.saghen.dev/configuration/reference.html>
require('blink.cmp').setup({
  enabled = function()
    local recording_macro = vim.fn.reg_recording() ~= ''
    local in_replace_mode = vim.api.nvim_get_mode().mode:match('^R')
    return not recording_macro and not in_replace_mode
  end,

  keymap = {
    preset = 'enter', -- <https://github.com/Saghen/blink.cmp/blob/v1.1.1/lua/blink/cmp/keymap/presets.lua#L67-L84>

    ['<C-y>'] = { 'select_and_accept' },
    ['<C-e>'] = { 'cancel', 'fallback' },
    ['<C-k>'] = { 'fallback' }, -- I want my digraphs >:)
    ['<C-f>'] = { scroll_page(1), 'fallback' },
    ['<C-b>'] = { scroll_page(-1), 'fallback' },
    ['<F1>'] = { 'show_signature', 'hide_signature', 'fallback' },

    -- ['<Tab>'] = {
    --   function(cmp)
    --     if not (cmp.is_menu_visible() and cmp.get_selected_item() ~= nil) then
    --       return cmp.snippet_forward()
    --     end
    --   end,
    --   'select_next',
    --   'fallback',
    -- },

    -- ['<S-Tab>'] = {
    --   function(cmp)
    --     if not (cmp.is_menu_visible() and cmp.get_selected_item() ~= nil) then
    --       return cmp.snippet_backward()
    --     end
    --   end,
    --   'select_prev',
    --   'fallback',
    -- },
  },

  cmdline = {
    enabled = false,
    keymap = {
      preset = 'cmdline', -- <https://github.com/Saghen/blink.cmp/blob/v1.1.1/lua/blink/cmp/keymap/presets.lua#L24-L37>
      ['<C-e>'] = { 'cancel', 'fallback' },
    },
  },

  completion = {
    list = {
      selection = { preselect = false, auto_insert = true },
    },

    menu = {
      min_width = vim.o.pumwidth,
      max_height = vim.o.pumheight,
      draw = {
        -- By default `label` and `label_description` are put in the same
        -- column, which causes the label description to be right-aligned.
        columns = { { 'kind_icon' }, { 'label' }, { 'label_description' } },
      },
    },

    documentation = {
      auto_show = false,
      -- TODO: disabling treesitter disables ALL highlighting here. Why?
      -- <https://github.com/saghen/blink.cmp/blob/cb5e346d9e0efa7a3eee7fd4da0b690c48d2a98e/lua/blink/cmp/lib/window/docs.lua>
      treesitter_highlighting = true or utils.is_truthy(vim.g.dotfiles_treesitter_highlighting),
    },
  },

  signature = {
    enabled = true,
    window = {
      treesitter_highlighting = true or utils.is_truthy(vim.g.dotfiles_treesitter_highlighting),
    },
  },

  snippets = {
    preset = dotplug.has('LuaSnip') and 'luasnip' or 'default',
    score_offset = 0, -- base penalty for ALL snippets
  },

  sources = {
    default = { 'lsp', 'path', 'snippets', 'buffer' },

    providers = {
      lsp = {
        fallbacks = {}, -- Enable the `buffer` source even if the LS is running
        -- The delay to wait for LS to respond, after which it is treated as an
        -- asynchronous source and the completion menu is shown anyway.
        timeout_ms = 1000,
      },

      snippets = {
        score_offset = -1, -- additional penalty for snippets coming from this source
      },

      buffer = {
        score_offset = -3,
        opts = {
          get_bufnrs = function()
            local cmp_window = require('blink.cmp.completion.windows.menu').win.id
            local visible_bufs = {}
            for _, winid in ipairs(vim.api.nvim_list_wins()) do
              if winid ~= cmp_window then visible_bufs[vim.api.nvim_win_get_buf(winid)] = true end
            end

            local buffers_to_scan = {}
            for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
              local bo = vim.bo[bufnr]
              if
                vim.api.nvim_buf_is_loaded(bufnr)
                and (visible_bufs[bufnr] or bo.buflisted)
                and (bo.buftype == '' or bo.buftype == 'acwrite')
                and not bo.binary
                and utils.get_inmemory_buf_size(bufnr) <= 500000 -- 500kB
              then
                table.insert(buffers_to_scan, bufnr)
              end
            end
            return buffers_to_scan
          end,
        },
      },

      path = {
        opts = {
          show_hidden_files_by_default = true,
        },
      },
    },

    -- TODO?????
    -- transform_items = function(_, items)
    --   local CompletionItemKind = require('blink.cmp.types').CompletionItemKind
    --   -- The default score for items not listed in this table is zero.
    --   ---@type table<lsp.CompletionItemKind, integer>
    --   local score_offset_by_kind = {
    --     -- [CompletionItemKind.Keyword] = 2,
    --     [CompletionItemKind.Snippet] = -2,
    --     [CompletionItemKind.Text] = -10,
    --   }
    --   for _, item in ipairs(items) do
    --     item.score_offset = item.score_offset + (score_offset_by_kind[item] or 0)
    --   end
    --   return items
    -- end,
  },

  fuzzy = {
    implementation = 'prefer_rust_with_warning',
    sorts = { 'score', 'sort_text' },
  },
})
