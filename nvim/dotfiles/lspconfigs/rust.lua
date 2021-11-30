-- See also:
-- <https://github.com/rust-analyzer/rust-analyzer/blob/master/docs/dev/lsp-extensions.md>
-- <https://github.com/simrat39/rust-tools.nvim>
-- <https://github.com/fannheyward/coc-rust-analyzer/blob/master/src/lsp_ext.ts>
-- <https://github.com/fannheyward/coc-rust-analyzer/blob/master/src/commands.ts>

-- TODO TODO TODO
-- <https://github.com/fannheyward/coc-rust-analyzer/blob/master/package.json>
-- <https://github.com/fannheyward/coc-rust-analyzer/blob/70a051e6877064dca71caa65f7b21ad2a7eb419a/src/commands.ts#L573-L592>
-- <https://github.com/fannheyward/coc-rust-analyzer/blob/70a051e6877064dca71caa65f7b21ad2a7eb419a/src/index.ts>
-- <https://github.com/simrat39/rust-tools.nvim/tree/master/lua/rust-tools>
-- <https://github.com/rust-analyzer/rust-analyzer/blob/2021-07-19/docs/dev/lsp-extensions.md>
-- <https://github.com/akinsho/nvim-toggleterm.lua/blob/master/lua/toggleterm/config.lua>

local lsp_utils = require('dotfiles.lsp.utils')
local lspconfig = require('lspconfig')
local lsp = require('vim.lsp')

lspconfig['rust_analyzer'].setup({
  completion_item_label = 'Rs';

  settings_scopes = {'rust-analyzer'};
  -- <https://github.com/rust-analyzer/rust-analyzer/blob/2021-07-19/docs/user/manual.adoc#configuration>
  settings = {
    ['rust-analyzer'] = {
      lens = {
        enable = false;
      };
      inlayHints = {
        chainingHints = false;
        parameterHints = false;
        typeHints = false;
      };
      diagnostics = {
        enable = false;
        enableExperimental = false;
      };
      completion = {
        autoimport = {
          enable = false;
        };
      };
      checkOnSave = {
        command = 'clippy';
      };
      cargo = {
        loadOutDirsFromCheck = true;
      };
    };
  };

  on_new_config = function(config)
    local orig_handler = config.handlers['window/showMessage'] or lsp.handlers['window/showMessage']
    -- :SanGoblin: <https://github.com/rust-analyzer/rust-analyzer/pull/9937>
    config.handlers['window/showMessage'] = lsp_utils.wrap_handler_compat(
      function(err, result, ctx, opts)
        if (
          not err and type(result) == 'table' and type(result.message) == 'string' and
          result.message:match('^overly long loop turn: ')
        ) then
          return
        end
        return lsp_utils.call_handler_compat(orig_handler, err, result, ctx, opts)
      end
    )
  end;

  ignition_commands = {
    -- <https://github.com/fannheyward/coc-rust-analyzer/blob/70a051e6877064dca71caa65f7b21ad2a7eb419a/src/commands.ts#L435-L439>
    -- <https://github.com/neovim/nvim-lspconfig/blob/4f72377143fc0961391fb0e42e751b9f677fca4e/lua/lspconfig/rust_analyzer.lua#L5-L13>
    LspRustReloadWorkspace = {handler = function(_, client, bufnr)
      client.request(
        'rust-analyzer/reloadWorkspace',
        nil,
        lsp_utils.wrap_handler_errors(function(_, _, _) end),
        bufnr
      )
    end};

    -- <https://github.com/fannheyward/coc-rust-analyzer/blob/70a051e6877064dca71caa65f7b21ad2a7eb419a/src/commands.ts#L389-L411>
    -- <https://github.com/simrat39/rust-tools.nvim/blob/11f232c7a82c3fd5d34654c6b02abae4f56ac5e6/lua/rust-tools/expand_macro.lua>
    LspRustExpandMacro = {handler = function(_, client, bufnr)
      client.request(
        'rust-analyzer/expandMacro',
        lsp.util.make_position_params(),
        lsp_utils.wrap_handler_errors(function(params, ctx, _)
          if not (params and params.name and params.expansion) then
            lsp_utils.client_notify(ctx.client_id, 'No macro found under cursor', vim.log.levels.WARN)
            return
          end
          vim.call('dotfiles#utils#open_scratch_preview_win', {
            title = string.format('[Rust: recursive expansion of %s! macro]', params.name),
            text = params.expansion,
            setup_commands = {'set syntax=rust'},
          })
        end),
        bufnr
      )
    end};

    -- <https://github.com/fannheyward/coc-rust-analyzer/blob/70a051e6877064dca71caa65f7b21ad2a7eb419a/src/commands.ts#L62-L72>
    LspRustStatus = {handler = function(_, client, bufnr)
      client.request(
        'rust-analyzer/analyzerStatus',
        lsp.util.make_position_params(),
        lsp_utils.wrap_handler_errors(function(params, _, _)
          if type(params) == 'string' then
            print(params)
          end
        end),
        bufnr
      )
    end};

    -- <https://github.com/fannheyward/coc-rust-analyzer/blob/70a051e6877064dca71caa65f7b21ad2a7eb419a/src/commands.ts#L74-L79>
    LspRustMemoryUsage = {handler = function(_, client, bufnr)
      client.request(
        'rust-analyzer/memoryUsage',
        nil,
        lsp_utils.wrap_handler_errors(function(params, _, _)
          if type(params) == 'string' then
            print(params)
          end
        end),
        bufnr
      )
    end};

    -- <https://github.com/fannheyward/coc-rust-analyzer/blob/70a051e6877064dca71caa65f7b21ad2a7eb419a/src/commands.ts#L121-L148>
    -- <https://github.com/simrat39/rust-tools.nvim/blob/11f232c7a82c3fd5d34654c6b02abae4f56ac5e6/lua/rust-tools/parent_module.lua>
    LspRustParentModule = {handler = function(_, client, bufnr)
      client.request(
        'experimental/parentModule',
        lsp.util.make_position_params(),
        lsp_utils.wrap_handler_errors(function(params, _, _)
          lsp_utils.jump_to_location_maybe_many(params)
        end),
        bufnr
      )
    end};

    -- <https://github.com/fannheyward/coc-rust-analyzer/blob/70a051e6877064dca71caa65f7b21ad2a7eb419a/src/commands.ts#L559-L571>
    -- <https://github.com/simrat39/rust-tools.nvim/blob/11f232c7a82c3fd5d34654c6b02abae4f56ac5e6/lua/rust-tools/open_cargo_toml.lua>
    LspRustOpenCargoToml = {handler = function(_, client, bufnr)
      client.request(
        'experimental/openCargoToml',
        lsp.util.make_position_params(),
        lsp_utils.wrap_handler_errors(function(params, ctx, _)
          if not params then
            lsp_utils.client_notify(ctx.client_id, 'Cargo.toml not found', vim.log.levels.WARN)
            return
          end
          lsp.util.jump_to_location(params)
        end),
        bufnr
      )
    end};

    -- <https://github.com/fannheyward/coc-rust-analyzer/blob/70a051e6877064dca71caa65f7b21ad2a7eb419a/src/commands.ts#L543-L557>
    LspRustExternalDocs = {handler = function(_, client, bufnr)
      client.request(
        'experimental/externalDocs',
        lsp.util.make_position_params(),
        lsp_utils.wrap_handler_errors(function(params, ctx, _)
          if not params then
            lsp_utils.client_notify(ctx.client_id, 'No symbol found under cursor', vim.log.levels.WARN)
            return
          end
          vim.call('dotfiles#utils#open_url', params)
        end),
        bufnr
      )
    end};

    -- <https://github.com/fannheyward/coc-rust-analyzer/blob/70a051e6877064dca71caa65f7b21ad2a7eb419a/src/commands.ts#L543-L557>
    LspRustCrateGraph = {bang = true, handler = function(call_info, client, bufnr)
      client.request(
        'rust-analyzer/viewCrateGraph',
        {full = call_info.bang},
        lsp_utils.wrap_handler_errors(function(params, ctx, _)
          if type(params) ~= 'string' then return end
          local file_path = vim.fn.tempname() .. '_rust_crate_graph.svg'
          local file = assert(io.open(file_path, 'w'))
          assert(file:write(params))
          assert(file:flush())
          assert(file:close())
          vim.call('dotfiles#utils#open_url', file_path)
        end),
        bufnr
      )
    end};

    -- <https://github.com/fannheyward/coc-rust-analyzer/blob/70a051e6877064dca71caa65f7b21ad2a7eb419a/src/commands.ts#L672-L690>
    LspRustItemTree = {handler = function(_, client, bufnr)
      client.request(
        'rust-analyzer/viewItemTree',
        lsp.util.make_position_params(),
        lsp_utils.wrap_handler_errors(function(params, _, _)
          if type(params) ~= 'string' then
            return
          end
          vim.call('dotfiles#utils#open_scratch_preview_win', {
            title = '[Rust: Item Tree]',
            text = params,
            vertical = true,
            setup_commands = {'set syntax=rust'},
          })
        end),
        bufnr
      )
    end};

    -- <https://github.com/fannheyward/coc-rust-analyzer/blob/70a051e6877064dca71caa65f7b21ad2a7eb419a/src/commands.ts#L573-L592>
    LspRustHIR = {handler = function(_, client, bufnr)
      client.request(
        'rust-analyzer/viewHir', lsp.util.make_position_params(),
        lsp_utils.wrap_handler_errors(function(params, _, _)
          if type(params) ~= 'string' then
            return
          end
          vim.call('dotfiles#utils#open_scratch_preview_win', {
            title = '[Rust: HIR]',
            text = params,
            vertical = true,
            setup_commands = {'set syntax=rust'},
          })
        end),
        bufnr
      )
    end};

    -- <https://github.com/fannheyward/coc-rust-analyzer/blob/70a051e6877064dca71caa65f7b21ad2a7eb419a/src/commands.ts#L362-L387>
    LspRustSyntaxTree = {range = '%', handler = function(call_info, client, bufnr)
      local req_params = { textDocument = lsp.util.make_text_document_params() }
      local start_pos, end_pos = {call_info.line1, 1}, {call_info.line2, #vim.fn.getline(call_info.line2)}
      if call_info.range ~= 0 then
        if vim.fn.visualmode() == 'v' then
          -- "Enhance" the precision in linewise Visual mode by adding the
          -- column numbers, but only if the command was invoked with '<,'>
          local start_mark, end_mark = {vim.fn.line("'<"), vim.fn.col("'<")}, {vim.fn.line("'>"), vim.fn.col("'>")}
          if start_mark[1] == call_info.line1 and end_mark[1] == call_info.line2 then
            start_pos[2], end_pos[2] = start_mark[2], end_mark[2]
          end
        end
        req_params.range = lsp.util.make_given_range_params(start_pos, end_pos).range
      end

      client.request(
        'rust-analyzer/syntaxTree',
        req_params,
        lsp_utils.wrap_handler_errors(function(params, _, _)
          if type(params) ~= 'string' then
            return
          end
          vim.call('dotfiles#utils#open_scratch_preview_win', {
            title = string.format(
              '[Rust: Syntax Tree from %d:%d to %d:%d]', start_pos[1], start_pos[2], end_pos[1], end_pos[2]
            ),
            text = params,
            vertical = true,
            setup_commands = {'set syntax=rust'},
          })
        end),
        bufnr
      )
    end};
  };
})
