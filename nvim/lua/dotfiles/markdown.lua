--- Implements parsing and highlighting of Markdown syntax USING A REAL PARSER.
--- Highlighting Markdown with Vim's built-in syntax highlighter tends to break
--- often because documentation is rarely strictly formatted Markdown, and that
--- parser is very brittle in and of itself, e.g. it can't tell that underscores
--- inside a word (`some_random_identifier_from_code`) shouldn't be interpreted
--- as italic tags. Instead, I use Github's libcmark-gfm (through LuaJIT's FFI),
--- which, itself, is a fork of libcmark. Other alternative ways of rendering
--- Markdown were considered:
---
--- 1. I immediately rejected the usage Markdown rendering libraries for Lua,
---    for two reasons: first of all, the language is less popular, so those
---    libraries would get less testing (and parsing Markdown is not exactly a
---    simple task), secondly, Lua lacks a built-in regular expression engine by
---    design, but Markdown seems to be the rare case when parsing with regexes
---    makes much more sense (or, at least, this is what reading existing
---    implementations lead me to believe). Also, there is the question of it
---    being installable with system package managers, and Luarocks doesn't count.
--- 2. coc.nvim uses marked (<https://marked.js.org/>), but we can't use JS
---    libraries (or libraries of any scripting language for that matter)
---    without remote plugins, and I didn't want to rely on them for such
---    commonly-invoked functionality.
--- 3. There is, however, another way of obtaining access to those libraries: I
---    could make a program which would be spawned as a subprocess and output
---    the parsed AST of the Markdown block. But this obviously would run pretty
---    slow because spwaning subprocesses on Linux is known to be expensive, and
---    Nodejs in particular has especially long startup times (`node -e ''`
---    takes 40 milliseconds on my machine, while the current implementation can
---    parse this comment in less than a millisecond, and I am not even
---    importing any libraries in Node).
--- 4. Finally, with the recent advent of Treesitter integration in Neovim,
---    using it seemed like a viable option, but I've heard that the Markdown
---    parser for it segfaults sometimes, and I didn't know how to use
---    Treesitter, and using a pre-made library with a nice Lua API would've
---    been no fun anyway.
---
--- As such, I opted for libcmark. It is a popular library, is used by Github
--- (their fork supports Github-flavored Markdown, which is baked into LSP), has
--- a pretty nice and simple C API, and is available even in Debian repositories
--- (let alone Arch).
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
local M, module = require('dotfiles.autoload')('dotfiles.markdown', {})

local utils = require('dotfiles.utils')
local ffi = require('ffi')

---@type table<string, any>
local lib = ffi.load('cmark-gfm')
---@type table<string, any>
local lib_ext = ffi.load('cmark-gfm-extensions')

if not module.reloading then
  local cmark_header = utils.read_file(utils.script_relative('./cmark-gfm.h'))
  ffi.cdef(cmark_header)
end

local can_get_list_item_index = pcall(function() return lib.cmark_node_get_item_index end)

local can_get_tasklist_item_checked = pcall(
  function() return lib_ext.cmark_gfm_extensions_get_tasklist_item_checked end
)

local ns_id = vim.api.nvim_create_namespace(module.name)

for hlgroup, link in pairs({
  dotmarkCode = 'String',
  dotmarkStrong = 'Bold',
  dotmarkEmph = 'Italic',
  dotmarkStrikethrough = 'Strikethrough',
  dotmarkHeading = 'Title',
  dotmarkBlockquote = 'Comment',
  dotmarkThematicBreak = 'WinSeparator',
  dotmarkLinkUrl = 'String',
  dotmarkLinkText = 'Underlined',
  dotmarkLinkTitle = 'Label',
  dotmarkItem = 'Identifier',
  dotmarkTodo = 'Todo',
}) do
  vim.api.nvim_set_hl(0, hlgroup, { default = true, link = link })
end

---@class dotfiles.markdown.renderer
---@field linenr integer
---@field lines string[]
---@field lines_prefixes string[]
---@field line_indent_stack string[]
---@field lines_separators table<integer, boolean>
---@field syntaxes_stack dotfiles.markdown.syntax[]
---@field syntaxes_ranges dotfiles.markdown.syntax[]
---@field hlgroups_stack dotfiles.markdown.hlgroup[]
---@field hlgroups_ranges dotfiles.markdown.hlgroup[]
local renderer = M.renderer or {}
renderer.__index = renderer
M.renderer = renderer

---@return dotfiles.markdown.renderer
function renderer.new()
  local self = setmetatable({}, renderer)
  self.linenr = 0
  self.lines = {}
  self.lines_prefixes = {}
  self.lines_separators = {}
  self.syntaxes_ranges = {}
  self.hlgroups_ranges = {}
  self:reset_section_state()
  return self
end

function renderer:reset_section_state()
  self.line_indent_stack = {}
  self.syntaxes_stack = {}
  self.hlgroups_stack = {}
end

---@return integer line
---@return integer col
function renderer:current_pos()
  local line = self.linenr
  if line == 0 then return 0, 0 end
  return line - 1, #self.lines_prefixes[line] + #self.lines[line]
end

---@param indent string
function renderer:push_indent(indent) table.insert(self.line_indent_stack, indent) end

---@param indent string
function renderer:push_temporary_indent(indent)
  self.lines_prefixes[self.linenr] = self.lines_prefixes[self.linenr] .. indent
end

---@return string
function renderer:pop_indent() return table.remove(self.line_indent_stack) end

---@param text string
function renderer:push_line(text)
  self.linenr = self.linenr + 1
  self.lines[self.linenr] = text
  self.lines_prefixes[self.linenr] = table.concat(self.line_indent_stack)
end

---@param text string
function renderer:push_text(text)
  local first = true
  for chunk in vim.gsplit(text, '\n') do
    if first and self.linenr ~= 0 then
      self.lines[self.linenr] = self.lines[self.linenr] .. chunk
    else
      self:push_line(chunk)
    end
    first = false
  end
end

function renderer:ensure_new_line()
  if self.linenr == 0 or #self.lines[self.linenr] > 0 or self.lines_separators[self.linenr] then
    self:push_line('')
  else
    self.lines[self.linenr] = ''
  end
end

function renderer:ensure_separator()
  if self.linenr > 0 and not self.lines_separators[self.linenr] then
    self:ensure_new_line()
    self.lines_separators[self.linenr] = true
    self:ensure_new_line()
  end
end

---@param syntax string
function renderer:push_syntax(syntax)
  ---@class dotfiles.markdown.syntax
  local syn = { syntax = syntax }
  syn.start_row, syn.start_col = self:current_pos()
  syn.end_row, syn.end_col = -1, -1
  table.insert(self.syntaxes_stack, syn)
  table.insert(self.syntaxes_ranges, syn)
end

function renderer:pop_syntax()
  ---@type dotfiles.markdown.syntax
  local syn = table.remove(self.syntaxes_stack)
  syn.end_row, syn.end_col = self:current_pos()
end

---@param name string
---@param extmark? vim.api.keyset.set_extmark
function renderer:push_hlgroup(name, extmark)
  ---@class dotfiles.markdown.hlgroup
  local hl = { name = name, extmark = extmark }
  hl.start_row, hl.start_col = self:current_pos()
  hl.end_row, hl.end_col = -1, -1
  table.insert(self.hlgroups_stack, hl)
  table.insert(self.hlgroups_ranges, hl)
end

---@param text string
---@param hlgroup string
---@param extmark? vim.api.keyset.set_extmark
function renderer:push_text_with_hl(text, hlgroup, extmark)
  self:push_hlgroup(hlgroup, extmark)
  self:push_text(text)
  self:pop_hlgroup()
end

function renderer:pop_hlgroup()
  ---@type dotfiles.markdown.hlgroup
  local hl = table.remove(self.hlgroups_stack)
  hl.end_row, hl.end_col = self:current_pos()
end

-- A rough re-implementation of <https://github.com/neoclide/coc.nvim/blob/e7f4fd4d941cb651105d9001253c9187664f4ff6/src/markdown/index.ts#L36-L75>.
-- <https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#markedString>
-- <https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#markupContentInnerDefinition>
---@param sections string|lsp.MarkupContent|lsp.MarkedString|lsp.MarkedString[]
function renderer:parse_documentation_sections(sections)
  if type(sections) == 'string' then
    -- MarkedString, markdown variation. Short-circuiting is fine here.
    self:parse_markdown_section(sections)
  elseif type(sections) == 'table' then
    if sections.kind ~= nil then -- MarkupContent. Also, there can't be an array of these.
      -- Apparently some servers don't send the `value` when it is empty? Well,
      -- I'll trust Nvim authors on this one.
      local section_value = sections.value or ''
      -- See MarkupKind under <https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#markupContent>.
      if sections.kind == 'markdown' then
        self:parse_markdown_section(section_value)
      elseif sections.kind == 'plaintext' then
        self:parse_plaintext_section(section_value, '')
      end
    else -- MarkedString or MarkedString[].
      -- <https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#markedString>
      if not utils.is_list(sections) then sections = { sections } end
      for idx, section in ipairs(sections) do
        if type(section) == 'string' then
          if section ~= '' then
            self:ensure_separator()
            self:parse_markdown_section(section)
          end
        elseif type(section) == 'table' then
          if section.value and section.value ~= '' then
            self:ensure_separator()
            self:parse_plaintext_section(section.value, section.language)
          end
        else
          error('sections[' .. idx .. ']: unexpected type ' .. type(sections))
        end
      end
    end
  else
    error('sections: unexpected type ' .. type(sections))
  end
end

---@param section_text string
function renderer:parse_markdown_section(section_text)
  self:reset_section_state()

  lib_ext.cmark_gfm_core_extensions_ensure_registered()
  local options = bit.bor(lib.CMARK_OPT_DEFAULT, lib.CMARK_OPT_STRIKETHROUGH_DOUBLE_TILDE)
  local parser = ffi.gc(lib.cmark_parser_new(options), lib.cmark_parser_free)
  local parser_extensions = {}
  for _, ext_name in ipairs({
    'table', -- Too much effort to implement tables properly, with line wrapping and shit.
    'autolink', -- Why not? The extension doesn't add new node types.
    'strikethrough', -- Vim can do it, see help for |strikethrough|
    -- 'tagfilter', -- Unnecessary, we aren't rendering HTML
    'tasklist', -- Basically a small addition on top of regular lists.
  }) do
    local ext = lib_ext.cmark_find_syntax_extension(ext_name)
    if ext == nil then error('extension not available: ' .. ext_name) end
    lib_ext.cmark_parser_attach_syntax_extension(parser, ext)
    parser_extensions[ext_name] = ext
  end

  lib.cmark_parser_feed(parser, section_text, #section_text)
  local doc = ffi.gc(lib.cmark_parser_finish(parser), lib.cmark_node_free)

  local function walk_node_tree(root_node)
    local iter = ffi.gc(lib.cmark_iter_new(root_node), lib.cmark_iter_free)
    return function()
      local event = lib.cmark_iter_next(iter)
      if event ~= lib.CMARK_EVENT_DONE then return event, lib.cmark_iter_get_node(iter), iter end
    end
  end

  local function extract_literal_text_from_node(root_node)
    local chunks = {}
    for event, node in walk_node_tree(root_node) do
      if event == lib.CMARK_EVENT_ENTER then
        local text_ptr = lib.cmark_node_get_literal(node)
        if text_ptr ~= nil then table.insert(chunks, ffi.string(text_ptr)) end
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

  local paragraph_started = false
  local function handle_block_node(event)
    if event == lib.CMARK_EVENT_ENTER then
      self:ensure_new_line()
      if not paragraph_started then
        paragraph_started = true
        self:push_line('')
      end
    elseif event == lib.CMARK_EVENT_EXIT then
      paragraph_started = false
    end
  end

  local handlers = {}

  ---@type { [string]: boolean, [integer]: { url: string, text: string, title: string } }
  local seen_link_nodes = {}
  local function add_links_section()
    handle_block_node(lib.CMARK_EVENT_ENTER)

    table.sort(seen_link_nodes, function(a, b) return vim.stricmp(a.text, b.text) < 0 end)
    for _, link in ipairs(seen_link_nodes) do
      self:ensure_new_line()
      self:push_text_with_hl(link.text, 'dotmarkLinkText', { url = link.url })
      self:push_text(': ')
      self:push_text_with_hl(link.url, 'dotmarkLinkUrl', { url = link.url })
      if #link.title > 0 then
        self:push_text(' ')
        self:push_text_with_hl(link.title, 'dotmarkLinkTitle')
      end
    end

    handle_block_node(lib.CMARK_EVENT_EXIT)
  end

  handlers[tonumber(lib.CMARK_NODE_DOCUMENT)] = function(_, event)
    if event == lib.CMARK_EVENT_ENTER then paragraph_started = true end
    handle_block_node(event)
    if event == lib.CMARK_EVENT_EXIT then
      if #seen_link_nodes > 0 then add_links_section() end
    end
  end

  handlers[tonumber(lib.CMARK_NODE_PARAGRAPH)] = function(_, event) handle_block_node(event) end

  handlers[tonumber(lib.CMARK_NODE_TEXT)] = function(node, event)
    if event == lib.CMARK_EVENT_ENTER then
      self:push_text(ffi.string(lib.cmark_node_get_literal(node)))
    end
  end

  handlers[tonumber(lib.CMARK_NODE_SOFTBREAK)] = function(_, event)
    if event == lib.CMARK_EVENT_ENTER then self:push_text(' ') end
  end

  handlers[tonumber(lib.CMARK_NODE_LINEBREAK)] = function(_, event)
    if event == lib.CMARK_EVENT_ENTER then self:push_line('') end
  end

  handlers[tonumber(lib.CMARK_NODE_LIST)] = function(node, event)
    if event == lib.CMARK_EVENT_ENTER then
      -- The idea for this check was taken from <https://github.com/github/cmark-gfm/blob/0.29.0.gfm.0/src/commonmark.c#L189-L200>.
      -- NULL checks are redundant, the library does that for us.
      if lib.cmark_node_get_list_tight(node) ~= 0 then
        local parent_node = lib.cmark_node_parent(node)
        if lib.cmark_node_get_type(parent_node) == lib.CMARK_NODE_ITEM then
          local parent_list_node = lib.cmark_node_parent(parent_node)
          if lib.cmark_node_get_list_tight(parent_list_node) ~= 0 then paragraph_started = true end
        end
      end
    end
    handle_block_node(event)
  end

  local function is_tasklist_item_checked(node)
    if lib.cmark_node_get_syntax_extension(node) ~= parser_extensions.tasklist then return end
    if can_get_tasklist_item_checked then
      -- This function was introduced in version 0.29.0.gfm.1:
      -- <https://github.com/github/cmark-gfm/issues/160>
      -- <https://github.com/github/cmark-gfm/pull/161>
      -- <https://github.com/github/cmark-gfm/pull/162>
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

  local function get_list_item_index(node)
    if can_get_list_item_index then
      -- This function was added in v0.29.0.gfm.11:
      -- <https://github.com/github/cmark-gfm/commit/f040422cd787ea3fd22cb53d14e22952fb31055d>
      return lib.cmark_node_get_item_index(node)
    else
      -- This snippet for figuring out where we are in the list was stolen from
      -- <https://github.com/github/cmark-gfm/blob/0.29.0.gfm.2/src/commonmark.c#L237-L243>
      local index = lib.cmark_node_get_list_start(node) - 1
      while node ~= nil do
        node = lib.cmark_node_previous(node)
        index = index + 1
      end
      return index
    end
  end

  handlers[tonumber(lib.CMARK_NODE_ITEM)] = function(node, event)
    if event == lib.CMARK_EVENT_ENTER then
      -- Most of the logic in this handler is based on
      -- <https://github.com/github/cmark-gfm/blob/0.29.0.gfm.2/src/commonmark.c#L234-L243>
      local list_node = lib.cmark_node_parent(node)
      if lib.cmark_node_get_list_tight(list_node) ~= 0 then paragraph_started = true end
      handle_block_node(event)

      local list_type = lib.cmark_node_get_list_type(list_node)
      local marker
      if list_type == lib.CMARK_BULLET_LIST then
        marker = '*'
      elseif list_type == lib.CMARK_ORDERED_LIST then
        local list_number = get_list_item_index(node)
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

      self:push_hlgroup('dotmarkItem')
      self:push_temporary_indent(marker)
      self:pop_hlgroup()
      self:push_temporary_indent(' ')
      local is_checked = is_tasklist_item_checked(node)
      if is_checked ~= nil then self:push_temporary_indent(is_checked and ' ' or ' ') end
      self:push_indent(string.rep(' ', #marker + 1))
      paragraph_started = true
    elseif event == lib.CMARK_EVENT_EXIT then
      self:pop_indent()
      handle_block_node(event)
    end
  end

  handlers[tonumber(lib.CMARK_NODE_CODE)] = function(node, event)
    if event == lib.CMARK_EVENT_ENTER then
      handle_inline_style_node(lib.CMARK_EVENT_ENTER, 'dotmarkCode')
      self:push_text(ffi.string(lib.cmark_node_get_literal(node)))
      handle_inline_style_node(lib.CMARK_EVENT_EXIT, 'dotmarkCode')
    end
  end

  handlers[tonumber(lib.CMARK_NODE_STRONG)] = function(_, event)
    handle_inline_style_node(event, 'dotmarkStrong')
  end

  handlers[tonumber(lib.CMARK_NODE_EMPH)] = function(_, event)
    handle_inline_style_node(event, 'dotmarkEmph')
  end

  handlers[tonumber(lib_ext.CMARK_NODE_STRIKETHROUGH)] = function(_, event)
    handle_inline_style_node(event, 'dotmarkStrikethrough')
  end

  handlers[tonumber(lib.CMARK_NODE_CODE_BLOCK)] = function(node, event)
    if event == lib.CMARK_EVENT_ENTER then
      handle_block_node(lib.CMARK_EVENT_ENTER)
      self:push_syntax(ffi.string(lib.cmark_node_get_fence_info(node)))
      local text = ffi.string(lib.cmark_node_get_literal(node))
      self:push_text(text:sub(-1) == '\n' and text:sub(1, -2) or text)
      self:pop_syntax()
      handle_block_node(lib.CMARK_EVENT_EXIT)
    end
  end

  -- Replicates the logic in <https://github.com/github/cmark-gfm/blob/0.29.0.gfm.2/src/commonmark.c#L118-L154>.
  local function is_autolink(node)
    if lib.cmark_node_get_type(node) ~= lib.CMARK_NODE_LINK then return false end
    local url = ffi.string(lib.cmark_node_get_url(node))
    if not url:match('^[a-zA-Z][a-zA-Z0-9.+-]*:') then return false end
    local title = ffi.string(lib.cmark_node_get_title(node))
    if #title > 0 then return false end
    local text_node = lib.cmark_node_first_child(node)
    -- text_node must be the only child
    if text_node == nil or lib.cmark_node_next(text_node) ~= nil then return false end
    if lib.cmark_node_get_type(text_node) ~= lib.CMARK_NODE_TEXT then return false end
    local text = ffi.string(lib.cmark_node_get_literal(text_node))
    return text == url:gsub('^mailto:', '')
  end

  handlers[tonumber(lib.CMARK_NODE_LINK)] = function(node, event)
    if is_autolink(node) then
      if event == lib.CMARK_EVENT_ENTER then
        self:push_text('<')
        local url = ffi.string(lib.cmark_node_get_url(node))
        self:push_hlgroup('dotmarkLinkText', { url = url })
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
        self:push_text_with_hl('[IMG]', 'Error') -- TODO: render images with snacks.nvim
      end
      self:push_hlgroup('dotmarkLinkText', { url = link_obj.url })
    elseif event == lib.CMARK_EVENT_EXIT then
      self:pop_hlgroup()
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
    handle_inline_style_node(event, 'dotmarkHeading')
    if event == lib.CMARK_EVENT_ENTER then
      local marker = string.rep('#', lib.cmark_node_get_heading_level(node)) .. ' '
      self:push_temporary_indent(marker)
      self:push_indent(string.rep(' ', #marker))
    elseif event == lib.CMARK_EVENT_EXIT then
      self:pop_indent()
    end
  end

  handlers[tonumber(lib.CMARK_NODE_THEMATIC_BREAK)] = function(_, event)
    if event == lib.CMARK_EVENT_ENTER then
      self:ensure_new_line()
      self.lines_separators[self.linenr] = true
      self:ensure_new_line()
      paragraph_started = true
    end
  end

  handlers[tonumber(lib.CMARK_NODE_HTML_BLOCK)] = function(node, event)
    if event == lib.CMARK_EVENT_ENTER then
      handle_block_node(lib.CMARK_EVENT_ENTER)
      self:push_syntax('html')
      local text = ffi.string(lib.cmark_node_get_literal(node))
      self:push_text(text:sub(-1) == '\n' and text:sub(1, -2) or text)
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

  -- Only bare-bones support is provided for tables, they are just inserted
  -- verbatim as a markdown code block, preserving the original formatting.
  handlers[tonumber(lib_ext.CMARK_NODE_TABLE)] = function(node, event)
    if event == lib.CMARK_EVENT_ENTER then
      handle_block_node(lib.CMARK_EVENT_ENTER)
      local start_line = lib.cmark_node_get_start_line(node)
      local end_line = lib.cmark_node_get_end_line(node)
      self:push_syntax('markdown')
      local lines = vim.split(section_text, '\n', { plain = true })
      self:push_text(table.concat(vim.list_slice(lines, start_line, end_line), '\n'))
      self:pop_syntax()
      handle_block_node(lib.CMARK_EVENT_EXIT)
      return false
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
      vim.notify(
        ('%s: encountered node with unknown type %q at %d:%d, refusing to render it'):format(
          module.name,
          ffi.string(lib.cmark_node_get_type_string(node)),
          lib.cmark_node_get_start_line(node),
          lib.cmark_node_get_start_column(node)
        ),
        vim.log.levels.WARN
      )
    end
  end
end

---@param text string
---@param syntax string
function renderer:parse_plaintext_section(text, syntax)
  self:reset_section_state()
  self:push_syntax(syntax)

  local empty_lines_counter = 0
  local is_first_paragraph = true
  for line in vim.gsplit(text, '\n') do
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

---@param bufnr integer
---@param win_width integer
function renderer:highlight_markdown(bufnr, win_width)
  vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)

  for _, hl in ipairs(self.hlgroups_ranges) do
    local extmark = hl.extmark or {}
    extmark.hl_group = hl.name
    extmark.end_row = hl.end_row
    extmark.end_col = hl.end_col
    vim.api.nvim_buf_set_extmark(bufnr, ns_id, hl.start_row, hl.start_col, extmark)
  end

  for linenr in pairs(self.lines_separators) do
    vim.api.nvim_buf_set_extmark(bufnr, ns_id, linenr - 1, 0, {
      virt_text = { { string.rep('─', win_width), 'dotmarkThematicBreak' } },
      virt_text_pos = 'overlay',
    })
  end
end

---@param bufnr integer
function renderer:highlight_code_blocks(bufnr)
  local syntax_name_mapping = {} ---@type table<string, string>
  for _, rule in pairs(vim.g.vim_markdown_fenced_languages or {}) do
    local from, to = string.match(rule, '^(.-)=(.*)$')
    if from and to then syntax_name_mapping[from] = to end
  end

  local disabled_syntaxes = {
    text = true,
    txt = true,
  }

  local region_id = 1
  local loaded_syntaxes = {}
  local failed_syntaxes = {}

  ---@param range dotfiles.markdown.syntax
  local function add_syntax_region(range)
    -- Ignore any extra metadata in the "fence info". The pattern for the
    -- language name also implicitly checks that the string won't have any
    -- special characters when interpolated into the `syntax include` command.
    local ft = range.syntax:match('^%s*([a-zA-Z0-9_-]+)') or ''
    if ft ~= '' and not disabled_syntaxes[ft] then
      ft = syntax_name_mapping[ft] or ft

      if not loaded_syntaxes[ft] and not failed_syntaxes[ft] then
        local cluster_name = '@' .. ft:upper()
        vim.b.current_syntax = nil
        local ok, err =
          pcall(vim.cmd.syntax, { 'include', cluster_name, 'syntax/' .. ft .. '.vim' })
        vim.b.current_syntax = nil

        if not ok then
          failed_syntaxes[ft] = true
          vim.notify(module.name .. ': ' .. err, vim.log.levels.WARN)
        else
          loaded_syntaxes[ft] = cluster_name
        end
      end

      if loaded_syntaxes[ft] then
        -- NOTE: The end line is be exclusive here, and both start and end are 1-based indexes.
        vim.cmd.syntax({
          'region',
          'dotmarkCodeBlock' .. region_id,
          'start=/\\%' .. (range.start_row + 1) .. 'l/',
          'end=/\\%' .. (range.end_row + 2) .. 'l/',
          'contains=' .. loaded_syntaxes[ft],
          'keepend',
        })
        region_id = region_id + 1
        return
      end
    end

    vim.cmd.syntax({
      'region',
      'markdownCode',
      'start=/\\%' .. (range.start_row + 1) .. 'l/',
      'end=/\\%' .. (range.end_row + 2) .. 'l/',
      'keepend',
      'extend',
    })
  end

  vim.api.nvim_buf_call(bufnr, function()
    vim.cmd.syntax('clear')
    vim.cmd.syntax({ 'match', 'dotmarkTodo', vim.call('dotfiles#todo_comments#get_pattern') })
    vim.b.dotfiles_lsp_markdown = true
    for _, range in ipairs(self.syntaxes_ranges) do
      add_syntax_region(range)
    end
  end)
end

---@return boolean
function renderer:is_empty()
  for nr, line in ipairs(self.lines) do
    if #line > 0 or #self.lines_prefixes[nr] > 0 then return false end
  end
  return true
end

---@return string[]
function renderer:get_lines()
  local rendered = {}
  for nr, line in ipairs(self.lines) do
    rendered[nr] = self.lines_prefixes[nr] .. line
  end
  return rendered
end

---@param level integer
---@param text string
function renderer:add_section_heading(level, text)
  self:ensure_new_line()
  self:push_indent(string.rep(' ', level + 1))
  self:push_text_with_hl(string.rep('#', level) .. ' ' .. text, 'dotmarkHeading')
  self:pop_indent()
end

return M
