--- Implements parsing and highlighting of Markdown syntax USING A REAL PARSER.
--- Highlighting Markdown with Vim's built-in syntax highlighter tends to break
--- often because documentation is rarely strictly formatted Markdown, and that
--- parser is very brittle in and of itself, e.g. it can't tell that
--- underscores inside a word (`some_random_identifier_from_code`) shouldn't be
--- interpreted as italic tags. Instead, I use Github's libcmark-gfm (through
--- LuaJIT's FFI), which, itself, is a fork of libcmark. Other alternative ways
--- of rendering Markdown were considered:
---
--- 1. I immediately rejected the usage Markdown rendering libraries for Lua,
---    for two reasons: first of all, the language is less popular, so those
---    libraries would get less testing (and parsing Markdown is not exactly a
---    simple task), secondly, Lua lacks a built-in regular expression engine
---    by design, but Markdown seems to be the rare case when parsing with
---    regexes makes much more sense (or, at least, this is what reading
---    existing implementations lead me to believe). Also, there is the
---    question of it being installable with system package managers, and
---    Luarocks doesn't count.
--- 2. coc.nvim uses marked (<https://marked.js.org/>), but we can't use JS
---    libraries (or libraries of any scripting language for that matter)
---    without remote plugins, and I didn't want to rely on them for such
---    commonly-invoked functionality.
--- 3. There is, however, another way of obtaining access to those libraries: I
---    could make a program which would be spawned as a subprocess and output
---    the parsed AST of the Markdown block. But this obviously would run
---    pretty slow because spwaning subprocesses on Linux is known to be
---    expensive, and Nodejs in particular has especially long startup times
---    (`node -e ''` takes 40 milliseconds on my machine, while the current
---    implementation can parse this comment in less than a millisecond, and I
---    am not even importing any libraries in Node).
--- 4. Finally, with the recent advent of Treesitter integration in Neovim,
---    using it seemed like a viable option, but I've heard that the Markdown
---    parser for it segfaults sometimes, and I didn't know how to use
---    Treesitter, and using a pre-made library with a nice Lua API would've
---    been no fun anyway.
---
--- As such, I opted for libcmark. It is a popular library, is used by Github
--- (their fork supports Github-flavored Markdown, which is baked into LSP),
--- has a pretty nice and simple C API, and is available even in Debian
--- repositories (let alone Arch).
---
--- The highlighter part itself (the one which takes parsed data and puts it
--- into a buffer) is largely based on coc.nvim's implementation, of which the
--- key parts are:
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
local M = require('dotfiles.autoload')('dotfiles.lsp.markdown')

local lsp = require('vim.lsp')
local utils_vim = require('dotfiles.utils.vim')
local utils = require('dotfiles.utils')
local lsp_global_settings = require('dotfiles.lsp.global_settings')
local highlight_match = require('dotfiles.lsp.highlight_match')
local ffi = require('ffi')

---@type table<string, any>
local lib = ffi.load('cmark-gfm')
---@type table<string, any>
local lib_ext = ffi.load('cmark-gfm-extensions')

ffi.cdef(utils.read_file(vim.fn.fnamemodify(utils.script_path(), ':h') .. '/cmark_ffi_defs.h'))

M._CMARK_VERSION = lib.cmark_version()
M._CMARK_VERSION_STR = ffi.string(lib.cmark_version_string())

-- <https://github.com/github/cmark-gfm/blob/0.29.0.gfm.0/src/cmark-gfm_version.h.in#L4>
function M._get_cmark_version_int(major, minor, patch, gfm)
  return bit.bor(
    bit.lshift(bit.band(major, 0xff), 24),
    bit.lshift(bit.band(minor, 0xff), 16),
    bit.lshift(bit.band(patch, 0xff), 8),
    bit.lshift(bit.band(gfm, 0xff), 0)
  )
end

M.ns_id = vim.api.nvim_create_namespace(M.__module.name)

---@class dotfiles.MarkupRenderer
---@field public linenr number
---@field public lines string[]
---@field public lines_prefixes string[]
---@field public line_indent_stack string[]
---@field public lines_separators table<number, string>
---@field public syntaxes_stack table[]
---@field public syntaxes_ranges table[]
---@field public hlgroups_stack table[]
---@field public hlgroups_ranges table[]
M.Renderer = {}
M.Renderer.__index = M.Renderer

---@return dotfiles.MarkupRenderer
function M.Renderer.new()
  local self = setmetatable({}, M.Renderer)
  self.linenr = 0
  self.lines = {}
  self.lines_prefixes = {}
  self.lines_separators = {}
  self.syntaxes_ranges = {}
  self.hlgroups_ranges = {}
  self:reset_section_state()
  return self
end

function M.Renderer:reset_section_state()
  self.line_indent_stack = {}
  self.syntaxes_stack = {}
  self.hlgroups_stack = {}
end

function M.Renderer:current_pos()
  local line = self.linenr
  if line ~= 0 then
    return line, #self.lines_prefixes[line] + #self.lines[line] + 1
  else
    return 1, 1
  end
end

function M.Renderer:push_indent(indent)
  utils.check_type('indent', indent, 'string')
  table.insert(self.line_indent_stack, indent)
end

function M.Renderer:push_temporary_indent(indent)
  utils.check_type('indent', indent, 'string')
  self.lines_prefixes[self.linenr] = self.lines_prefixes[self.linenr] .. indent
end

function M.Renderer:pop_indent()
  return table.remove(self.line_indent_stack)
end

function M.Renderer:push_line(text)
  utils.check_type('text', text, 'string')
  self.linenr = self.linenr + 1
  self.lines[self.linenr] = text
  self.lines_prefixes[self.linenr] = table.concat(self.line_indent_stack)
end

function M.Renderer:push_text(text)
  utils.check_type('text', text, 'string')
  local first = true
  for chunk in vim.gsplit(text, '\n', true) do
    if first and self.linenr ~= 0 then
      self.lines[self.linenr] = self.lines[self.linenr] .. chunk
    else
      self:push_line(chunk)
    end
    first = false
  end
end

function M.Renderer:ensure_new_line()
  if self.linenr == 0 or #self.lines[self.linenr] > 0 or self.lines_separators[self.linenr] then
    self:push_line('')
  else
    self.lines[self.linenr] = ''
  end
end

function M.Renderer:push_separator()
  self:push_line('')
  self.lines_separators[self.linenr] = true
end

function M.Renderer:push_syntax(syntax)
  utils.check_type('syntax', syntax, 'string')
  local range = {
    syntax = syntax,
    start_linenr = -1,
    end_linenr = -1,
  }
  range.start_linenr, _ = self:current_pos()
  table.insert(self.syntaxes_stack, range)
end

function M.Renderer:pop_syntax()
  local range = table.remove(self.syntaxes_stack)
  range.end_linenr, _ = self:current_pos()
  range.end_linenr = range.end_linenr
  table.insert(self.syntaxes_ranges, range)
  return range.syntax
end

function M.Renderer:push_hlgroup(hlgroup)
  utils.check_type('hlgroup', hlgroup, 'string')
  local hl = {
    group = hlgroup,
    start_linenr = -1,
    start_colnr = -1,
    end_linenr = -1,
    end_colnr = -1,
  }
  hl.start_linenr, hl.start_colnr = self:current_pos()
  table.insert(self.hlgroups_stack, hl)
end

function M.Renderer:pop_hlgroup()
  local hl = table.remove(self.hlgroups_stack)
  hl.end_linenr, hl.end_colnr = self:current_pos()
  table.insert(self.hlgroups_ranges, hl)
end

function M.Renderer:add_hlgroup(hl)
  utils.check_type('hl.group', hl.group, 'string')
  utils.check_type('hl.start_linenr', hl.start_linenr, 'number')
  utils.check_type('hl.start_colnr', hl.start_colnr, 'number')
  utils.check_type('hl.end_linenr', hl.end_linenr, 'number')
  utils.check_type('hl.end_colnr', hl.end_colnr, 'number')
  table.insert(self.hlgroups_ranges, hl)
end

-- A rough re-implementation of <https://github.com/neoclide/coc.nvim/blob/e7f4fd4d941cb651105d9001253c9187664f4ff6/src/markdown/index.ts#L36-L75>.
-- Handles values of type `MarkedString | MarkedString[] | MarkupContent`.
-- <https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#markedString>
-- <https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#markupContentInnerDefinition>
function M.Renderer:parse_documentation_sections(sections)
  if type(sections) == 'string' then
    -- MarkedString, markdown variation. Short-circuiting is fine here.
    self:parse_markdown_section(sections)
  elseif type(sections) == 'table' then
    if sections.kind then
      -- MarkupContent. Also, there can't be an array of these.

      -- Apparently some servers don't send the `value` when it is empty? Well,
      -- I'll trust Nvim authors on this one.
      local section_value = sections.value or ''
      -- See MarkupKind under <https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#markupContent>.
      if sections.kind == 'markdown' then
        self:parse_markdown_section(section_value)
      elseif sections.kind == 'plaintext' then
        self:parse_plaintext_section(section_value, '')
      end
    else
      -- MarkedString or MarkedString[].
      -- <https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#markedString>
      if not vim.tbl_islist(sections) then
        sections = { sections }
      end

      local is_first_section = true
      for section_i, section in ipairs(sections) do
        if type(section) == 'string' then
          if section ~= '' then
            if not is_first_section then
              self:push_separator()
            end
            is_first_section = false
            self:parse_markdown_section(section)
          end
        elseif type(section) == 'table' then
          if section.value and section.value ~= '' then
            if not is_first_section then
              self:push_separator()
            end
            is_first_section = false
            self:parse_plaintext_section(section.value, section.language)
          end
        else
          error(string.format('sections[%d]: unexpected type %s', section_i, type(sections)))
        end
      end
    end
  else
    error(string.format('sections: unexpected type %s', type(sections)))
  end
end

function M.Renderer:parse_markdown_section(section_text)
  vim.validate({
    section_text = { section_text, 'string' },
  })

  self:reset_section_state()

  local options = bit.bor(
    lib.CMARK_OPT_DEFAULT,
    lib.CMARK_OPT_STRIKETHROUGH_DOUBLE_TILDE
    -- NOTE: footnotes currently can't be supported because the library doesn't
    -- publicly expose a way of tying together the definition and reference of
    -- a footnote.
    -- lib.CMARK_OPT_FOOTNOTES
  )

  lib_ext.cmark_gfm_core_extensions_ensure_registered()

  local parser = ffi.gc(lib.cmark_parser_new(options), lib.cmark_parser_free)
  local parser_extensions = {}
  for _, ext_name in ipairs({
    -- 'table', -- Nah, too much effort to implement.
    'autolink', -- Why not? The extension doesn't add new node types.
    'strikethrough', -- Vim can do it, see help for |strikethrough|
    -- 'tagfilter', -- Unnecessary, we aren't rendering HTML
    'tasklist', -- Basically a small addition on top of regular lists.
  }) do
    local ext = lib_ext.cmark_find_syntax_extension(ext_name)
    if ext == nil then
      error('extension not available: ' .. ext_name)
    end
    lib_ext.cmark_parser_attach_syntax_extension(parser, ext)
    parser_extensions[ext_name] = ext
  end

  lib.cmark_parser_feed(parser, section_text, #section_text)
  local doc = ffi.gc(lib.cmark_parser_finish(parser), lib.cmark_node_free)

  local function walk_node_tree(root_node)
    local iter = ffi.gc(lib.cmark_iter_new(root_node), lib.cmark_iter_free)
    return function()
      local event = lib.cmark_iter_next(iter)
      if event ~= lib.CMARK_EVENT_DONE then
        return event, lib.cmark_iter_get_node(iter), iter
      end
    end
  end

  local function extract_literal_text_from_node(root_node)
    local chunks = {}
    for event, node in walk_node_tree(root_node) do
      if event == lib.CMARK_EVENT_ENTER then
        local text_ptr = lib.cmark_node_get_literal(node)
        if text_ptr ~= nil then
          table.insert(chunks, ffi.string(text_ptr))
        end
      end
    end
    return table.concat(chunks)
  end

  local function handle_inline_style_node(event, hlgroup)
    if event == lib.CMARK_EVENT_ENTER then
      self:push_hlgroup(hlgroup)
    elseif event == lib.CMARK_EVENT_EXIT then
      self:pop_hlgroup()
    end
  end

  local begun_pushing_paragraph = false
  local function handle_block_node(event)
    if event == lib.CMARK_EVENT_ENTER then
      self:ensure_new_line()
      if not begun_pushing_paragraph then
        begun_pushing_paragraph = true
        self:push_line('')
      end
    elseif event == lib.CMARK_EVENT_EXIT then
      begun_pushing_paragraph = false
    end
  end

  local handlers = {}

  local seen_link_nodes = {}
  local function handle_links_section(event)
    handle_block_node(event)
    if event == lib.CMARK_EVENT_ENTER then
      table.sort(seen_link_nodes, function(a, b)
        return vim.stricmp(a.text, b.text) < 0
      end)
      for _, link in ipairs(seen_link_nodes) do
        self:ensure_new_line()
        self:push_text('[')
        self:push_hlgroup('cmarkNodeLinkText')
        self:push_text(link.text)
        self:pop_hlgroup()
        self:push_text(']: <')
        self:push_hlgroup('cmarkNodeLinkUrl')
        self:push_text(link.url)
        self:pop_hlgroup()
        self:push_text('>')
        if #link.title > 0 then
          self:push_text(' ')
          self:push_hlgroup('cmarkNodeLinkTitle')
          self:push_text(link.title)
          self:pop_hlgroup()
        end
      end
    end
  end

  handlers[tonumber(lib.CMARK_NODE_DOCUMENT)] = function(_, event)
    if event == lib.CMARK_EVENT_ENTER then
      begun_pushing_paragraph = true
    end
    handle_block_node(event)
    if event == lib.CMARK_EVENT_EXIT then
      if #seen_link_nodes > 0 then
        handle_links_section(lib.CMARK_EVENT_ENTER)
        handle_links_section(lib.CMARK_EVENT_EXIT)
      end
    end
  end

  handlers[tonumber(lib.CMARK_NODE_PARAGRAPH)] = function(_, event)
    handle_block_node(event)
  end

  handlers[tonumber(lib.CMARK_NODE_TEXT)] = function(node, event)
    if event == lib.CMARK_EVENT_ENTER then
      self:push_text(ffi.string(lib.cmark_node_get_literal(node)))
    end
  end

  handlers[tonumber(lib.CMARK_NODE_SOFTBREAK)] = function(_, event)
    if event == lib.CMARK_EVENT_ENTER then
      self:push_line('')
    end
  end

  handlers[tonumber(lib.CMARK_NODE_LINEBREAK)] = function(_, event)
    if event == lib.CMARK_EVENT_ENTER then
      self:push_line('')
    end
  end

  handlers[tonumber(lib.CMARK_NODE_LIST)] = function(node, event)
    if event == lib.CMARK_EVENT_ENTER then
      -- The idea for this check was taken from <https://github.com/github/cmark-gfm/blob/0.29.0.gfm.0/src/commonmark.c#L189-L200>.
      -- NULL checks are redundant, the library does that for us.
      if lib.cmark_node_get_list_tight(node) ~= 0 then
        local parent_node = lib.cmark_node_parent(node)
        if lib.cmark_node_get_type(parent_node) == lib.CMARK_NODE_ITEM then
          local parent_list_node = lib.cmark_node_parent(parent_node)
          if lib.cmark_node_get_list_tight(parent_list_node) ~= 0 then
            begun_pushing_paragraph = true
          end
        end
      end
    end
    handle_block_node(event)
  end

  local function is_tasklist_item_checked(node)
    if lib.cmark_node_get_syntax_extension(node) ~= parser_extensions.tasklist then
      return
    end
    local ok = pcall(function()
      -- This function was introduced in version 0.29.0.gfm.1:
      -- <https://github.com/github/cmark-gfm/issues/160>
      -- <https://github.com/github/cmark-gfm/pull/161>
      -- <https://github.com/github/cmark-gfm/pull/162>
      return lib_ext.cmark_gfm_extensions_get_tasklist_item_checked
    end)
    if ok then
      return lib_ext.cmark_gfm_extensions_get_tasklist_item_checked(node)
    else
      -- Fallback for 0.29.0.gfm.0:
      -- <https://github.com/github/cmark-gfm/pull/136>
      local state = ffi.string(lib_ext.cmark_gfm_extensions_get_tasklist_state(node))
      -- The fact that states here are flipped is not a bug, it is a workaround
      -- for <https://github.com/github/cmark-gfm/pull/142>.
      if state == 'checked' then
        return false
      elseif state == 'unchecked' then
        return true
      else
        return
      end
    end
  end

  handlers[tonumber(lib.CMARK_NODE_ITEM)] = function(node, event)
    if event == lib.CMARK_EVENT_ENTER then
      -- The logic for figuring out where we are in the list, along with
      -- pretty much rest of logic in this handler, was stolen from
      -- <https://github.com/github/cmark-gfm/blob/0.29.0.gfm.2/src/commonmark.c#L234-L243>
      local list_node = lib.cmark_node_parent(node)
      if lib.cmark_node_get_list_tight(list_node) ~= 0 then
        begun_pushing_paragraph = true
      end
      handle_block_node(event)

      local list_type = lib.cmark_node_get_list_type(list_node)
      local marker
      if list_type == lib.CMARK_BULLET_LIST then
        marker = '-'
      elseif list_type == lib.CMARK_ORDERED_LIST then
        local list_number = lib.cmark_node_get_list_start(list_node) - 1
        local tmp = node
        while tmp ~= nil do
          tmp = lib.cmark_node_previous(tmp)
          list_number = list_number + 1
        end
        local list_delim = lib.cmark_node_get_list_delim(list_node)
        if list_delim == lib.CMARK_PAREN_DELIM then
          list_delim = ')'
        elseif list_delim == lib.CMARK_PERIOD_DELIM then
          list_delim = '.'
        else
          error('invalid list delimiter: ' .. list_delim)
        end
        marker = string.format('%d%s', list_number, list_delim)
      else
        error('invalid list type: ' .. list_type)
      end

      self:push_hlgroup('cmarkNodeItem')
      self:push_temporary_indent(marker)
      self:pop_hlgroup()
      self:push_temporary_indent(' ')
      local is_checked = is_tasklist_item_checked(node)
      if is_checked ~= nil then
        self:push_temporary_indent('[' .. (is_checked and 'x' or ' ') .. '] ')
      end
      self:push_indent(string.rep(' ', #marker + 1))
      begun_pushing_paragraph = true
    elseif event == lib.CMARK_EVENT_EXIT then
      self:pop_indent()
      handle_block_node(event)
    end
  end

  handlers[tonumber(lib.CMARK_NODE_CODE)] = function(node, event)
    if event == lib.CMARK_EVENT_ENTER then
      handle_inline_style_node(lib.CMARK_EVENT_ENTER, 'cmarkNodeCode')
      self:push_text(ffi.string(lib.cmark_node_get_literal(node)))
      handle_inline_style_node(lib.CMARK_EVENT_EXIT, 'cmarkNodeCode')
    end
  end

  handlers[tonumber(lib.CMARK_NODE_STRONG)] = function(_, event)
    handle_inline_style_node(event, 'cmarkNodeStrong')
  end

  handlers[tonumber(lib.CMARK_NODE_EMPH)] = function(_, event)
    handle_inline_style_node(event, 'cmarkNodeEmph')
  end

  handlers[tonumber(lib_ext.CMARK_NODE_STRIKETHROUGH)] = function(_, event)
    handle_inline_style_node(event, 'cmarkNodeStrikethrough')
  end

  handlers[tonumber(lib.CMARK_NODE_CODE_BLOCK)] = function(node, event)
    if event == lib.CMARK_EVENT_ENTER then
      handle_block_node(lib.CMARK_EVENT_ENTER)
      self:push_syntax(ffi.string(lib.cmark_node_get_fence_info(node)))
      local text = ffi.string(lib.cmark_node_get_literal(node))
      self:push_text(utils.remove_suffix(text, '\n'))
      self:pop_syntax()
      handle_block_node(lib.CMARK_EVENT_EXIT)
    end
  end

  -- Replicates the logic in <https://github.com/github/cmark-gfm/blob/0.29.0.gfm.2/src/commonmark.c#L118-L154>.
  local function is_autolink(node)
    if lib.cmark_node_get_type(node) ~= lib.CMARK_NODE_LINK then
      return false
    end
    local url = ffi.string(lib.cmark_node_get_url(node))
    if not url:match('^[a-zA-Z][a-zA-Z0-9.+-]*:') then
      return false
    end
    local title = ffi.string(lib.cmark_node_get_title(node))
    if #title > 0 then
      return false
    end
    local text_node = lib.cmark_node_first_child(node)
    -- text_node must be the only child
    if text_node == nil or lib.cmark_node_next(text_node) ~= nil then
      return false
    end
    if lib.cmark_node_get_type(text_node) ~= lib.CMARK_NODE_TEXT then
      return false
    end
    local text = ffi.string(lib.cmark_node_get_literal(text_node))
    return text == url:gsub('^mailto:', '')
  end

  handlers[tonumber(lib.CMARK_NODE_LINK)] = function(node, event)
    if is_autolink(node) then
      if event == lib.CMARK_EVENT_ENTER then
        self:push_text('<')
        self:push_hlgroup('cmarkNodeLinkText')
      elseif event == lib.CMARK_EVENT_EXIT then
        self:pop_hlgroup()
        self:push_text('>')
      end
      return
    end

    if event == lib.CMARK_EVENT_ENTER then
      local link_obj = {
        text = extract_literal_text_from_node(node),
        url = ffi.string(lib.cmark_node_get_url(node)),
        title = ffi.string(lib.cmark_node_get_title(node)),
      }
      -- I can't put a "tuple" into a table key to ensure uniqueness of the
      -- values by multiple keys (like I would in Rust or Python), so instead I
      -- make a unique string key. Lengths of strings are added to handle
      -- situations when a string in the "tuple" contains the separator (e.g.
      -- tuples `("a", "b|c")` and `("a|b", "c")` would be treated as equal).
      local key = table.concat({
        #link_obj.text,
        #link_obj.url,
        #link_obj.title,
        link_obj.text,
        link_obj.url,
        link_obj.title,
      }, '|')
      if not seen_link_nodes[key] then
        seen_link_nodes[key] = true
        table.insert(seen_link_nodes, link_obj)
      end
      if lib.cmark_node_get_type(node) == lib.CMARK_NODE_IMAGE then
        -- Would be cool to render images inline: <https://github.com/edluffy/hologram.nvim>
        self:push_text('IMG')
      end
      self:push_text('[')
      self:push_hlgroup('cmarkNodeLinkText')
    elseif event == lib.CMARK_EVENT_EXIT then
      self:pop_hlgroup()
      self:push_text(']')
    end
  end
  handlers[tonumber(lib.CMARK_NODE_IMAGE)] = handlers[tonumber(lib.CMARK_NODE_LINK)]

  handlers[tonumber(lib.CMARK_NODE_BLOCK_QUOTE)] = function(_, event)
    handle_block_node(event)
    if event == lib.CMARK_EVENT_ENTER then
      local marker = '> '
      self:push_indent(marker)
      self:push_temporary_indent(marker)
    elseif event == lib.CMARK_EVENT_EXIT then
      self:pop_indent()
    end
  end

  handlers[tonumber(lib.CMARK_NODE_HEADING)] = function(node, event)
    handle_block_node(event)
    if event == lib.CMARK_EVENT_ENTER then
      local marker = string.rep('#', lib.cmark_node_get_heading_level(node)) .. ' '
      self:push_temporary_indent(marker)
      self:push_indent(marker)
    elseif event == lib.CMARK_EVENT_EXIT then
      self:pop_indent()
    end
    handle_inline_style_node(event, 'cmarkNodeHeading')
  end

  handlers[tonumber(lib.CMARK_NODE_THEMATIC_BREAK)] = function(_, event)
    if event == lib.CMARK_EVENT_ENTER then
      self:ensure_new_line()
      self.lines_separators[self.linenr] = true
      self:ensure_new_line()
      begun_pushing_paragraph = true
    end
  end

  handlers[tonumber(lib.CMARK_NODE_HTML_BLOCK)] = function(node, event)
    if event == lib.CMARK_EVENT_ENTER then
      handle_block_node(lib.CMARK_EVENT_ENTER)
      self:push_syntax('html')
      local text = ffi.string(lib.cmark_node_get_literal(node))
      self:push_text(utils.remove_suffix(text, '\n'))
      self:pop_syntax()
      handle_block_node(lib.CMARK_EVENT_EXIT)
    end
  end

  handlers[tonumber(lib.CMARK_NODE_HTML_INLINE)] = function(node, event)
    if event == lib.CMARK_EVENT_ENTER then
      self:push_text(ffi.string(lib.cmark_node_get_literal(node)))
    end
  end

  handlers[tonumber(lib.CMARK_NODE_CUSTOM_BLOCK)] = function(node, event)
    handle_block_node(event)
    if event == lib.CMARK_EVENT_ENTER then
      self:push_text(ffi.string(lib.cmark_node_get_on_enter(node)))
    elseif event == lib.CMARK_EVENT_EXIT then
      self:push_text(ffi.string(lib.cmark_node_get_on_exit(node)))
    end
  end

  handlers[tonumber(lib.CMARK_NODE_CUSTOM_INLINE)] = function(node, event)
    if event == lib.CMARK_EVENT_ENTER then
      self:push_text(ffi.string(lib.cmark_node_get_on_enter(node)))
    elseif event == lib.CMARK_EVENT_EXIT then
      self:push_text(ffi.string(lib.cmark_node_get_on_exit(node)))
    end
  end

  for event, node, iter in walk_node_tree(doc) do
    local handler = handlers[tonumber(lib.cmark_node_get_type(node))]
    if handler then
      local descend = handler(node, event)
      if descend ~= nil and not descend then
        -- This idea was copied from <https://github.com/github/cmark-gfm/blob/0.29.0.gfm.2/src/render.c#L183-L191>
        lib.cmark_iter_reset(iter, node, lib.CMARK_EVENT_EXIT)
      end
    else
      utils_vim.echomsg(
        string.format(
          '%s: encountered node with unknown type %q at %d:%d, refusing to render it',
          M.__module.name,
          ffi.string(lib.cmark_node_get_type_string(node)),
          lib.cmark_node_get_start_line(node),
          lib.cmark_node_get_start_column(node)
        ),
        'WarningMsg'
      )
    end
  end
end

function M.Renderer:parse_plaintext_section(section_text, section_syntax)
  vim.validate({
    section_text = { section_text, 'string' },
    section_syntax = { section_syntax, 'string' },
  })

  self:reset_section_state()

  local empty_lines_counter = 0
  local is_first_paragraph = true

  self:push_syntax(section_syntax)

  -- Equivalent to `lsp.util.trim_empty_lines(vim.split(section_syntax, '\n'))`,
  -- but with more iterators and less iterations.
  for line in vim.gsplit(section_text, '\n', true) do
    if #line > 0 then
      if not is_first_paragraph then
        for _ = 1, empty_lines_counter do
          self:push_line('')
        end
      end
      is_first_paragraph = false

      empty_lines_counter = 0
      self:push_line(line)
    else
      empty_lines_counter = empty_lines_counter + 1
    end
  end

  self:pop_syntax()
end

-- But of course, the same one as what coc uses!
-- <https://github.com/neoclide/coc.nvim/blob/e7f4fd4d941cb651105d9001253c9187664f4ff6/src/markdown/index.ts#L70>
M.HORIZONTAL_SEPARATOR_CHAR = '—'

-- Serves the same purpose as `lsp.util.stylize_markdown`, but parsing is
-- decoupled into functions above and is more precise. See:
-- <https://github.com/neovim/neovim/blob/v0.5.0/runtime/lua/vim/lsp/util.lua#L1074-L1246>
-- <https://github.com/neoclide/coc.nvim/blob/e7f4fd4d941cb651105d9001253c9187664f4ff6/autoload/coc/highlight.vim#L252-L319>
function M.Renderer:render_documentation_into_buf(bufnr, winid, opts)
  vim.validate({
    bufnr = { bufnr, 'number', true },
    winid = { winid, 'number', true },
    opts = { opts, 'table', true },
  })
  opts = opts or {}

  -- Thus far this closely resembles Nvim's implementation...

  opts.wrap_at = opts.wrap_at
    or (vim.api.nvim_win_get_option(winid, 'wrap') and vim.api.nvim_win_get_width(winid))
  local width, height = lsp.util._make_floating_popup_size(self.lines, opts)
  local separator_width = math.min(width, opts.wrap_at or width)

  local lines_rendered = {}
  local lines_count = 0
  local linenr_offset = 0
  for i = 1, opts.pad_top or 0 do
    lines_rendered[i] = ''
    linenr_offset = linenr_offset + 1
  end
  for linenr, line in ipairs(self.lines) do
    local prefix = self.lines_prefixes[linenr]
    if self.lines_separators[linenr] then
      line = prefix .. string.rep(M.HORIZONTAL_SEPARATOR_CHAR, separator_width - #prefix)
      table.insert(self.hlgroups_ranges, {
        group = 'cmarkNodeThematicBreak',
        start_linenr = linenr,
        start_colnr = #prefix + 1,
        end_linenr = linenr,
        end_colnr = #line + 1,
      })
    else
      line = prefix .. line
    end
    line = string.gsub(line, '%s+$', '')
    lines_rendered[linenr_offset + linenr] = line
    lines_count = lines_count + 1
  end
  for i = 1, opts.pad_bottom or 0 do
    lines_rendered[linenr_offset + lines_count + i] = ''
  end
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines_rendered)

  vim.api.nvim_buf_clear_namespace(bufnr, M.ns_id, 0, -1)
  local hl_slice_requests = {}
  for i, range in ipairs(self.hlgroups_ranges) do
    hl_slice_requests[i] = {
      linenr_offset + range.start_linenr - 1,
      range.start_colnr - 1,
      linenr_offset + range.end_linenr - 1,
      range.end_colnr - 1,
      range.group,
    }
  end
  for _, slice in ipairs(highlight_match.compute_slices(hl_slice_requests, bufnr, 'utf-8')) do
    local line, start, len, group = utils.unpack4(slice)
    vim.api.nvim_buf_add_highlight(bufnr, M.ns_id, group, line - 1, start - 1, start + len - 1)
  end

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
    vim.cmd('syntax match cmarkTodo ' .. vim.call('dotfiles#todo_comments#get_pattern'))

    local region_id = 1
    for _, range in ipairs(self.syntaxes_ranges) do
      -- Ignore any extra metadata in the "fence info". This also implicitly
      -- checks that the type of `syntax` is string and that it won't have any
      -- special characters when interpolated into the `syntax include`
      -- command.
      local syntax = string.match(range.syntax, '^%s*([a-zA-Z0-9_]+)') or ''
      if syntax ~= '' and syntax ~= 'text' and not disabled_syntaxes[syntax] then
        syntax = syntax_name_mapping[syntax] or syntax
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
        -- NOTE: The end line must be exclusive here.
        vim.cmd(
          string.format(
            'silent! syntax region CodeBlock%d start=/\\%%%dl/ end=/\\%%%dl/ contains=@%s keepend',
            region_id,
            linenr_offset + range.start_linenr,
            linenr_offset + range.end_linenr + 1,
            loaded_cluster_name
          )
        )
        region_id = region_id + 1
      end
    end
  end)

  return self.lines
end

function lsp.util.stylize_markdown(bufnr, contents, opts)
  ---@type dotfiles.MarkupRenderer|nil
  local renderer = opts.dotfiles_markup_renderer
  if not renderer then
    renderer = M.Renderer.new()
    renderer:parse_markdown_section(table.concat(contents, '\n'))
  end
  return renderer:render_documentation_into_buf(bufnr, 0, opts)
end

-- Faster replacement for `vim.tbl_isempty(lsp.util.trim_empty_lines(markdown_lines))`
function M.Renderer:are_all_lines_empty()
  for _, line in ipairs(self.lines) do
    if #line > 0 then
      return false
    end
  end
  return true
end

function M.Renderer:open_in_floating_window(opts)
  opts = opts or {}
  opts.dotfiles_markup_renderer = self
  return lsp.util.open_floating_preview(self.lines, 'markdown', opts)
end

return M
