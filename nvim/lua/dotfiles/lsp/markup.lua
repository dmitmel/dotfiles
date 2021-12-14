--- Implements parsing and highlighting of a small subset of Markdown syntax
--- that I am interested in. Based largely on coc.nvim's implementation, of
--- which the key parts are:
--- <https://github.com/neoclide/coc.nvim/blob/e7f4fd4d941cb651105d9001253c9187664f4ff6/src/markdown/index.ts>
--- <https://github.com/neoclide/coc.nvim/blob/e7f4fd4d941cb651105d9001253c9187664f4ff6/src/handler/hover.ts#L125-L152>
--- <https://github.com/neoclide/coc.nvim/blob/e7f4fd4d941cb651105d9001253c9187664f4ff6/autoload/coc/float.vim#L470-L514>
--- <https://github.com/neoclide/coc.nvim/blob/e7f4fd4d941cb651105d9001253c9187664f4ff6/autoload/coc/highlight.vim#L252-L319>
--- <https://github.com/markedjs/marked/blob/v2.1.3/src/rules.js#L13>
---
--- ...And on Neovim's implementation, here:
--- <https://github.com/neovim/neovim/blob/v0.5.0/runtime/lua/vim/lsp/util.lua#L791-L842>
--- <https://github.com/neovim/neovim/blob/v0.5.0/runtime/lua/vim/lsp/util.lua#L1032-L1246>
---
--- LSP documentation on the matter:
--- <https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#hover>
--- <https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#markupContent>
---
--- Some intricacies of the code blocks syntax are covered here:
--- <https://www.danvega.dev/blog/2019/05/31/escape-backtick-markdown/>
--- <https://markdownmonster.west-wind.com/docs/_5eg1brc0z.htm>
--- <https://github.github.com/gfm/#fenced-code-blocks>
---
--- TODO: Use a real markdown parsing library? Some considerations:
--- 1. coc.nvim uses marked, but we can't use JS stuff without remote plugins,
--- and I don't want to do that for a common piece of functionality.
--- 2. I'm inclined not to use a Lua library either because Lua lacks a regex
--- engine and markdown seems to be correctly parseable only with regexes. Or,
--- at least, that's what those Regular Expression-Oriented Programming adepts
--- lead me to believe.
--- 3. As such, binding to a C-based markdown library seems like a good choice.
--- 4. coc.nvim can do some pretty advanced stuff like splitting actual URLs
--- into "footnotes" at the end of the buffer when rendering markdown, as a
--- result of using a real markdown parser.
local M = require('dotfiles.autoload')('dotfiles.lsp.markdown')

local lsp = require('vim.lsp')
local utils_vim = require('dotfiles.utils.vim')
local lsp_global_settings = require('dotfiles.lsp.global_settings')

-- Parsing context stores temporary state and results of parsing documentation
-- blocks. It may be reused across invocations of the parser.
M.ParsingContext = {}
M.ParsingContext.__index = M.ParsingContext

function M.ParsingContext.new()
  local self = setmetatable({}, M.ParsingContext)
  self.linenr = 0
  self.lines = {}
  self.lines_syntaxes = {}
  self.lines_syntax_region_breaks = {}
  self.lines_separators = {}
  return self
end

function M.ParsingContext:push_line(text, syntax)
  vim.validate({
    text = { text, 'string' },
    syntax = { syntax, 'string', true },
  })
  self.linenr = self.linenr + 1
  self.lines[self.linenr] = text
  self.lines_syntaxes[self.linenr] = syntax or ''
end

function M.ParsingContext:push_separator()
  self.linenr = self.linenr + 1
  self.lines[self.linenr] = ''
  self.lines_syntaxes[self.linenr] = ''
  self.lines_separators[self.linenr] = true
end

function M.ParsingContext:set_syntax_region_break()
  self.lines_syntax_region_breaks[self.linenr] = true
end

-- A rough re-implementation of <https://github.com/neoclide/coc.nvim/blob/e7f4fd4d941cb651105d9001253c9187664f4ff6/src/markdown/index.ts#L36-L75>.
-- Handles values of type `MarkedString | MarkedString[] | MarkupContent`.
-- <https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#markedString>
-- <https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#markupContentInnerDefinition>
function M.parse_documentation_blocks(blocks, parsing_ctx, markdown_syntax_name)
  vim.validate({
    parsing_ctx = { parsing_ctx, 'table', true },
    markdown_syntax_name = { markdown_syntax_name, 'string', true },
  })
  if parsing_ctx == nil then
    parsing_ctx = M.ParsingContext.new()
  end

  if type(blocks) == 'string' then
    -- MarkedString, markdown variation. Short-circuiting is fine here.
    M.parse_markdown_block(blocks, markdown_syntax_name, parsing_ctx)
  elseif type(blocks) == 'table' then
    if blocks.kind then
      -- MarkupContent. Also, there can't be an array of these.

      -- Apparently some servers don't send the `value` when it is empty? Well,
      -- I'll trust Nvim authors on this one.
      local block_value = blocks.value or ''
      -- See MarkupKind under <https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#markupContent>.
      if blocks.kind == 'markdown' then
        M.parse_markdown_block(block_value, markdown_syntax_name, parsing_ctx)
      elseif blocks.kind == 'plaintext' then
        M.parse_plaintext_block(block_value, '', parsing_ctx)
      end
    else
      -- MarkedString or MarkedString[].
      -- <https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#markedString>
      if not vim.tbl_islist(blocks) then
        blocks = { blocks }
      end

      local is_first_block = true
      for block_i, block in ipairs(blocks) do
        if type(block) == 'string' then
          if block ~= '' then
            if not is_first_block then
              parsing_ctx:push_separator()
            end
            is_first_block = false
            M.parse_markdown_block(block, markdown_syntax_name, parsing_ctx)
          end
        elseif type(block) == 'table' then
          if block.value and block.value ~= '' then
            if not is_first_block then
              parsing_ctx:push_separator()
            end
            is_first_block = false
            M.parse_plaintext_block(block.value, block.language, parsing_ctx)
          end
        else
          error(string.format('blocks[%d]: unexpected type %s', block_i, type(blocks)))
        end
      end
    end
  else
    error(string.format('blocks: unexpected type %s', type(blocks)))
  end

  return parsing_ctx
end

-- Rough re-implementation of <https://github.com/neoclide/coc.nvim/blob/e7f4fd4d941cb651105d9001253c9187664f4ff6/src/markdown/index.ts#L118-L199>.
function M.parse_markdown_block(block_text, markdown_syntax_name, parsing_ctx)
  vim.validate({
    block_text = { block_text, 'string' },
    markdown_syntax_name = { markdown_syntax_name, 'string', true },
    parsing_ctx = { parsing_ctx, 'table' },
  })

  -- NOTE: highlighting Markdown using Vim's built-in highlighter tends to
  -- break often because documentation is rarely strictly formatted Markdown,
  -- and that parser is very brittle in and of itself, e.g. it can't tell that
  -- underscores inside an identifier shouldn't be interpreted as italic tags.
  -- TODO: We need a real, much more advanced markdown parser.
  -- markdown_syntax_name = markdown_syntax_name or 'lsp_markdown'

  -- The logic in this parser built on crutches and bicycles leaves a lot to be
  -- desired...

  local code_block_fence_types = {
    {
      start_pattern = '^(```+)%s*([a-zA-Z0-9_-]*)[^`]*$',
      end_pattern = function(match_fence)
        return '^' .. match_fence .. '+$'
      end,
    },
    {
      start_pattern = '^(~~~+)%s*([a-zA-Z0-9_-]*).*$',
      end_pattern = function(match_fence)
        return '^' .. match_fence .. '+$'
      end,
    },
  }

  local is_within_code_block = false
  local code_block_syntax = nil
  local code_block_end_pattern = nil

  local is_first_paragraph = true
  local empty_lines_counter = 0
  for line in vim.gsplit(block_text, '\n', true) do
    local line_trimmed = vim.trim(line)

    if is_within_code_block then
      if line_trimmed:match(code_block_end_pattern) then
        is_within_code_block = false
        goto continue
      end
      parsing_ctx:push_line(line, code_block_syntax)
      goto continue
    end

    if #line_trimmed == 0 then
      empty_lines_counter = empty_lines_counter + 1
      goto continue
    end

    if line_trimmed:match('^%-%-%-+$') then
      parsing_ctx:push_separator()
      is_first_paragraph = true
      goto continue
    end

    if not is_first_paragraph then
      if empty_lines_counter > 0 then
        parsing_ctx:push_line('', markdown_syntax_name)
      end
    end
    is_first_paragraph = false
    empty_lines_counter = 0

    for _, fence_type in ipairs(code_block_fence_types) do
      local match_fence, match_syntax = line_trimmed:match(fence_type.start_pattern)
      if match_fence and match_syntax then
        is_within_code_block = true
        code_block_syntax = match_syntax
        code_block_end_pattern = fence_type.end_pattern(match_fence)
        goto continue
      end
    end

    parsing_ctx:push_line(line_trimmed, markdown_syntax_name)

    ::continue::
  end

  return parsing_ctx
end

function M.parse_plaintext_block(block_text, block_syntax, parsing_ctx)
  vim.validate({
    block_text = { block_text, 'string' },
    block_syntax = { block_syntax, 'string' },
    parsing_ctx = { parsing_ctx, 'table' },
  })

  local empty_lines_counter = 0
  local is_first_paragraph = true

  -- Equivalent to `lsp.util.trim_empty_lines(vim.split(block_syntax, '\n'))`,
  -- but with iterators and less iterations.
  for line in vim.gsplit(block_text, '\n', true) do
    if #line > 0 then
      if not is_first_paragraph then
        for _ = 1, empty_lines_counter do
          parsing_ctx:push_line('', block_syntax)
        end
      end
      is_first_paragraph = false

      empty_lines_counter = 0
      parsing_ctx:push_line(line, block_syntax)
    else
      empty_lines_counter = empty_lines_counter + 1
    end
  end

  return parsing_ctx
end

-- But of course, the same one as what coc uses!
-- <https://github.com/neoclide/coc.nvim/blob/e7f4fd4d941cb651105d9001253c9187664f4ff6/src/markdown/index.ts#L70>
M.HORIZONTAL_SEPARATOR_CHAR = '—'

-- Serves the same purpose as `lsp.util.stylize_markdown`, but parsing is
-- decoupled into functions above and is more precise. See:
-- <https://github.com/neovim/neovim/blob/v0.5.0/runtime/lua/vim/lsp/util.lua#L1074-L1246>
-- <https://github.com/neoclide/coc.nvim/blob/e7f4fd4d941cb651105d9001253c9187664f4ff6/autoload/coc/highlight.vim#L252-L319>
function M.render_documentation_into_buf(bufnr, winid, parsing_ctx, opts)
  vim.validate({
    bufnr = { bufnr, 'number' },
    parsing_ctx = { parsing_ctx, 'table' },
    opts = { opts, 'table', true },
  })
  opts = opts or {}

  -- Thus far this closely resembles Nvim's implementation...

  opts.wrap_at = opts.wrap_at
    or (vim.api.nvim_win_get_option(winid, 'wrap') and vim.api.nvim_win_get_width(winid))
  local width, height = lsp.util._make_floating_popup_size(parsing_ctx.lines, opts)
  local separator = string.rep(M.HORIZONTAL_SEPARATOR_CHAR, math.min(width, opts.wrap_at or width))

  local lines_rendered = {}
  local lines_count = 0
  local linenr_offset = 0
  for i = 1, opts.pad_top or 0 do
    lines_rendered[i] = ''
    linenr_offset = linenr_offset + 1
  end
  for linenr, line in ipairs(parsing_ctx.lines) do
    if parsing_ctx.lines_separators[linenr] then
      lines_rendered[linenr_offset + linenr] = separator
    else
      lines_rendered[linenr_offset + linenr] = line
    end
    lines_count = lines_count + 1
  end
  for i = 1, opts.pad_bottom or 0 do
    lines_rendered[linenr_offset + lines_count + i] = ''
  end
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines_rendered)

  -- I don't think we are supposed to use this, the standard markdown.vim uses
  -- g:markdown_fenced_languages as a list of which other syntaxes must be
  -- preloaded together with markdown.
  --[[
  local syntax_name_mapping = {}
  -- Copied from <https://github.com/neovim/neovim/blob/v0.5.0/runtime/lua/vim/lsp/util.lua#L1059-L1072>.
  for _, rule in pairs(vim.g.markdown_fenced_languages or {}) do
    if type(rule) == 'string' then
      local idx = rule:find('=')
      if idx then
        local mkd_lang, vim_syntax = rule:sub(1, idx - 1), rule:sub(idx + 1)
        syntax_name_mapping[mkd_lang] = vim_syntax
      end
    end
  end
  --]]

  -- Compatibility with coc:
  --[[
  local disabled_syntaxes = {}
  for _, syntax in ipairs(vim.g.coc_markdown_disabled_languages or {}) do
    if type(syntax) == 'string' then
      disabled_syntaxes[syntax] = true
    end
  end
  --]]

  local syntax_name_mapping = lsp_global_settings.MARKDOWN_SYNTAX_NAMES_MAPPING
  local disabled_syntaxes = lsp_global_settings.MARKDOWN_DISABLED_SYNTAXES

  -- ...But what follows, is based on coc!

  vim.api.nvim_buf_call(bufnr, function()
    vim.cmd('syntax clear') -- Also clears b:current_syntax
    local loaded_syntaxes = {}

    local region_id = 1
    local start_linenr = 1
    while start_linenr <= lines_count do
      local syntax = parsing_ctx.lines_syntaxes[start_linenr] or ''
      local end_linenr = start_linenr + 1
      while end_linenr <= lines_count do
        if (parsing_ctx.lines_syntaxes[end_linenr] or '') ~= syntax then
          break
        end
        if parsing_ctx.lines_syntax_region_breaks[end_linenr] then
          break
        end
        end_linenr = end_linenr + 1
      end
      -- NOTE: end_linenr will not be inclusive, but that's just what `:syntax
      -- region` wants.

      if syntax ~= '' and syntax ~= 'txt' and not disabled_syntaxes[syntax] then
        syntax = syntax_name_mapping[syntax] or syntax
        -- This also implicitly checks that the type of `syntax`.
        if not string.match(syntax, utils_vim.HLGROUP_NAME_PATTERN) then
          error(string.format('invalid syntax name %q', syntax))
        end
        local loaded_cluster_name = loaded_syntaxes[syntax]
        if not loaded_cluster_name then
          loaded_cluster_name = syntax:upper()
          vim.cmd(
            string.format(
              'silent! syntax include @%s syntax/%s.vim | unlet! b:current_syntax',
              loaded_cluster_name,
              syntax
            )
          )
          loaded_syntaxes[syntax] = loaded_cluster_name
        end
        vim.cmd(
          string.format(
            'silent! syntax region CodeBlock%d start=/\\%%%dl/ end=/\\%%%dl/ contains=@%s keepend',
            region_id,
            linenr_offset + start_linenr,
            linenr_offset + end_linenr,
            loaded_cluster_name
          )
        )
        region_id = region_id + 1
      end

      start_linenr = end_linenr
    end
  end)

  return parsing_ctx.lines
end

local orig_util_stylize_markdown = lsp.util.stylize_markdown
function lsp.util.stylize_markdown(bufnr, contents, opts, ...)
  if opts.dotfiles_markup_parsing_ctx then
    return M.render_documentation_into_buf(bufnr, 0, opts.dotfiles_markup_parsing_ctx, opts)
  end
  return orig_util_stylize_markdown(bufnr, contents, opts, ...)
end

return M
