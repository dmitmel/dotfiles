local utils = require('dotfiles.utils')

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
        list.select(distance < 0 and #list.items or 1)
      else
        local page_size = require('blink.cmp.completion.windows.menu').win:get_height()
        list.select(utils.clamp(list.selected_item_idx + page_size * distance, 1, #list.items))
      end
    end)
    return true
  end
end

-- NOTE: <https://www.youtube.com/watch?v=wCllU4YkxBk&t=107s>
-- Default configuration: <https://cmp.saghen.dev/configuration/reference.html>
---@type blink.cmp.Config
local blink_cmp_config = {
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
      min_width = 15,
      max_height = 20,
      draw = {
        columns = { { 'kind_icon' }, { 'label', 'label_description', gap = 1 } },
        components = { label = { width = { fill = false } } },
      },
    },

    documentation = {
      auto_show = false,
    },
  },

  signature = {
    enabled = true,
  },

  snippets = {
    preset = 'luasnip',
    score_offset = 0, -- base penalty for ALL snippets
  },

  sources = {
    default = { 'lsp', 'path', 'snippets', 'buffer', 'modelines' },
    per_filetype = {
      query = { 'omni', inherit_defaults = true },
    },

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
        opts = (function()
          ---@type blink.cmp.BufferOpts|{} the `|{}` after the type makes all fields optional
          local opts = {
            max_sync_buffer_size = 20 * 1000,
            max_async_buffer_size = 200 * 1000,
            max_total_buffer_size = 1000 * 1000,
          }
          local max_buffer_size = math.max(opts.max_sync_buffer_size, opts.max_async_buffer_size)

          function opts.get_bufnrs()
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
                and utils.get_inmemory_buf_size(bufnr) < max_buffer_size
              then
                table.insert(buffers_to_scan, bufnr)
              end
            end
            return buffers_to_scan
          end

          return opts
        end)(),
      },

      path = {
        opts = {
          show_hidden_files_by_default = true,
        },
      },

      modelines = {
        name = 'modelines',
        module = 'dotfiles.blink_cmp_modelines',
      },
    },
  },

  fuzzy = {
    implementation = 'prefer_rust_with_warning',
    sorts = { 'score', 'sort_text' },
  },
}

---@type LazySpec
return {
  'https://github.com/saghen/blink.cmp',
  version = 'v1.*',
  enabled = vim.g.vim_ide == 2 and utils.has('nvim-0.10'),

  dependencies = {
    {
      'https://github.com/L3MON4D3/LuaSnip',
      version = 'v2.*',
      build = 'make install_jsregexp',
      enabled = utils.has('nvim-0.7'),

      config = function(_, opts)
        local luasnip = require('luasnip')
        luasnip.setup(opts)

        require('luasnip.loaders.from_snipmate').lazy_load()

        utils.augroup('dotfiles_snippets'):autocmd({ 'InsertEnter', 'InsertLeave' }, function()
          if luasnip.get_active_snip() ~= nil and not luasnip.in_snippet() then
            luasnip.unlink_current()
          end
        end)
      end,
    },
  },

  opts = blink_cmp_config,
}
