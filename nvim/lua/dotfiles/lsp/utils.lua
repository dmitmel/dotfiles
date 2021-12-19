local M = require('dotfiles.autoload')('dotfiles.lsp.utils')

local lsp = require('vim.lsp')
local vim_uri = require('vim.uri')
local lsp_global_settings = require('dotfiles.lsp.global_settings')
local utils = require('dotfiles.utils')
local utils_vim = require('dotfiles.utils.vim')
local lsp_sync_available, lsp_sync = pcall(require, 'vim.lsp.sync')

-- CLIENTS {{{

function M.client_notify(client_id, message, log_level, ...)
  local client_name = ''
  if type(client_id) == 'string' then
    client_name = client_id
  elseif client_id then
    client_name = M.try_get_client_name(client_id)
  end
  vim.notify(string.format('LSP[%s] %s', client_name, message), log_level, ...)
  vim.cmd('redraw')
end

-- Implements the following frequently repeated pattern:
-- <https://github.com/neovim/neovim/blob/v0.5.0/runtime/lua/vim/lsp/handlers.lua#L30-L34>.
function M.assert_get_client_by_id(client_id)
  local client = lsp.get_client_by_id(client_id)
  if not client then
    vim.notify(
      string.format('LSP[id=%s] client has shut down after sending the message', client_id),
      vim.log.levels.ERROR
    )
    vim.cmd('redraw')
  end
  return client
end

function M.try_get_client_name(client_id)
  local client
  if type(client_id) == 'table' then
    client = client_id
  else
    client = lsp.get_client_by_id(client_id)
  end
  return (client and client.name) or string.format('id=%s', client_id)
end

function M.is_any_client_attached_to_buf(bufnr)
  local result = false
  -- `lsp.buf_get_clients()` allocates a table, but uses
  -- `lsp.for_each_buffer_client()` internally. This is the fastest we can do.
  lsp.for_each_buffer_client(bufnr, function()
    result = true
  end)
  return result
end

-- The logical continuation to `lsp.buf_is_attached()`.
function lsp.buf_is_any_attached(bufnr)
  return M.is_any_client_attached_to_buf(bufnr)
end

function M.any_attached_client_supports_method(bufnr, method)
  local result = false
  lsp.for_each_buffer_client(bufnr, function(client)
    if client.supports_method(method) then
      result = true
    end
  end)
  return result
end

function lsp.buf_any_client_supports_method(bufnr, method)
  return M.any_attached_client_supports_method(bufnr, method)
end

-- }}}

-- VSCODE DETECTION AND INTEGR... err, I mean, HIJACKING {{{

M.VSCODE_POSSIBLE_INSTALL_PATHS = {}

if utils_vim.has('macunix') then
  vim.list_extend(M.VSCODE_POSSIBLE_INSTALL_PATHS, {
    '/Applications/Visual Studio Code - Insiders.app/Contents/Resources/app',
    '/Applications/Visual Studio Code.app/Contents/Resources/app',
  })
elseif utils_vim.has('unix') then
  vim.list_extend(M.VSCODE_POSSIBLE_INSTALL_PATHS, {
    '/opt/visual-studio-code-insiders/resources/app', -- Arch Linux <https://aur.archlinux.org/packages/visual-studio-code-insiders-bin/>
    '/opt/visual-studio-code/resources/app', -- Arch Linux <https://aur.archlinux.org/packages/visual-studio-code-bin/>
    '/usr/lib/code/extensions', -- Arch Linux <https://archlinux.org/packages/community/x86_64/code/>
    '/usr/share/code/resources/app', -- Debian/Ubuntu <https://code.visualstudio.com/docs/setup/linux#_debian-and-ubuntu-based-distributions>
  })
end

M.VSCODE_INSTALL_PATH = nil
for _, dir in ipairs(M.VSCODE_POSSIBLE_INSTALL_PATHS) do
  if utils_vim.is_truthy(vim.fn.isdirectory(dir)) then
    M.VSCODE_INSTALL_PATH = dir
    break
  end
end

-- }}}

-- THE MULTIBYTE CHARACTER UNIFIED SUPPORT PROJECT {{{
-- NOTE: LSP's lines and characters are 0-indexed, however, Vim's lines and
-- columns are 1-indexed. Also NOTE: LSP uses UTF-16 for character offsets!!!
-- <https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#textDocuments>

-- TODO: <https://github.com/neovim/neovim/pull/16382>

-- See also:
-- <https://github.com/neovim/neovim/blob/v0.5.0/runtime/lua/vim/lsp/util.lua#L155-L181>
-- <https://github.com/neovim/neovim/blob/v0.6.0/runtime/lua/vim/lsp/util.lua#L237-L263>
-- <https://github.com/neovim/neovim/pull/16218>
function M.char_offset_to_byte_offset(char_idx, line_text, offset_encoding)
  if type(char_idx) ~= 'number' then
    error(string.format('char_idx: expected number, got %s', type(char_idx)))
  end
  if type(line_text) ~= 'string' then
    error(string.format('line_text: expected string, got %s', type(line_text)))
  end
  if char_idx <= 0 then
    -- We are on the first character, thus there is no difference between byte
    -- or character position. Accordingly, return the first column.
    return 0
  end

  local use_utf16 = true
  if offset_encoding == nil or offset_encoding == 'utf-16' then
    -- The most common case. UTF-16 is baked into the LSP specification,
    -- although there are talks of changing that:
    -- <https://github.com/microsoft/language-server-protocol/issues/376>.
    use_utf16 = true
  elseif offset_encoding == 'utf-8' then
    -- Vim uses UTF-8 internally, no difference here.
    return math.min(char_idx, #line_text)
  elseif offset_encoding == 'utf-32' then
    -- The least common case.
    use_utf16 = false
  else
    error(
      string.format(
        'offset_encoding: expected "utf-8" or "utf-16" or "utf-32", got %s',
        offset_encoding
      )
    )
  end

  local line_len_utf32, line_len_utf16 = vim.str_utfindex(line_text)
  local line_char_len = line_len_utf16
  if not use_utf16 then
    line_char_len = line_len_utf32
  end
  if char_idx >= line_char_len then
    -- Early exit if the character is past EOL.
    return #line_text
  end
  -- str_byteindex() shouldn't ever fail now because we have already checked
  -- that char_idx is in bounds of the string and it works fine on invalid UTF.
  return vim.str_byteindex(line_text, char_idx, use_utf16)
end

-- See also: <https://github.com/neovim/neovim/blob/v0.5.0/runtime/lua/vim/lsp/util.lua#L1858-L1872>.
function M.byte_offset_to_char_offset(byte_idx, line_text, offset_encoding)
  if type(byte_idx) ~= 'number' then
    error(string.format('byte_idx: expected number, got %s', type(byte_idx)))
  end
  if type(line_text) ~= 'string' then
    error(string.format('line_text: expected string, got %s', type(line_text)))
  end
  if byte_idx <= 0 then
    -- First column, see a comment above.
    return 0
  end

  -- See comments in the function above about UTF encodings.
  local use_utf16 = true
  if offset_encoding == nil or offset_encoding == 'utf-16' then
    use_utf16 = true
  elseif offset_encoding == 'utf-8' then
    return math.min(byte_idx, #line_text)
  elseif offset_encoding == 'utf-32' then
    use_utf16 = false
  else
    error(
      string.format(
        'offset_encoding: expected "utf-8" or "utf-16" or "utf-32", got %s',
        offset_encoding
      )
    )
  end

  local char_idx_utf16, char_idx_utf32
  if byte_idx > #line_text then
    -- Use the line length if we are past EOL.
    char_idx_utf32, char_idx_utf16 = vim.str_utfindex(line_text)
  else
    char_idx_utf32, char_idx_utf16 = vim.str_utfindex(line_text, byte_idx)
  end
  if use_utf16 then
    return char_idx_utf16
  else
    return char_idx_utf32
  end
end

--- Rerwite of <https://github.com/neovim/neovim/blob/v0.6.0/runtime/lua/vim/lsp/util.lua#L150-L221>
--- and <https://github.com/neovim/neovim/blob/v0.5.0/runtime/lua/vim/lsp/util.lua#L1489-L1558>.
function M.get_buf_lines_batch(bufnr, out_lines)
  if bufnr ~= nil and type(bufnr) ~= 'number' then
    error(string.format('bufnr: expected number, got %s', type(bufnr)))
  end
  for linenr, _ in pairs(out_lines) do
    if type(linenr) ~= 'number' then
      error(string.format('linenr: expected number, got %s', type(linenr)))
    end
  end

  local function buf_lines()
    for linenr, _ in pairs(out_lines) do
      -- Not batching `nvim_buf_get_lines` calls is not as slow as you might
      -- think: my experience with contributing to cmp-buffer suggests that
      -- performing line requests in small chunks lowers memory usage and
      -- doesn't hurt performance much. Tested on the CC source code (185k
      -- lines): requesting it all line-by-line is about 2-3 times slower than
      -- requesting the entire buffer at once, and we are talking about
      -- hundreds of thousands of lines here, whereas the most common use-case
      -- of `get_buf_lines_batch` is `locations_to_items`, which will generate
      -- disjoint ranges of lines. As such, batching line numbers into joined
      -- ranges to then pass them to `nvim_buf_get_lines` just complicates the
      -- code and is not worth it (but, apparently, is worth writing a ten-line
      -- comment about...).
      out_lines[linenr] = vim.api.nvim_buf_get_lines(bufnr, linenr, linenr + 1, true)[1] or ''
    end
    return out_lines
  end

  local function empty_lines()
    for linenr, _ in pairs(out_lines) do
      out_lines[linenr] = ''
    end
    return out_lines
  end

  local was_loaded = vim.api.nvim_buf_is_loaded(bufnr)
  if was_loaded then
    -- Shortcut for the hot path
    return buf_lines()
  end

  local uri = vim_uri.uri_from_bufnr(bufnr)
  local file_path = utils.uri_maybe_to_fname(uri)
  -- The server sent back a non-file URI, it must be loaded by a `BufReadCmd`
  -- autocommand.
  if not file_path then
    -- This branch will be inherently slow due to buffer loading.
    vim.fn.bufload(bufnr)
    return buf_lines()
  end

  -- Check if the file exists, is readable and is a file (i.e. not a
  -- directory). I know that this is has a TOCTOU error, but the original
  -- implementation with fs_stat before fs_open wasn't safe either.
  local fd = vim.loop.fs_open(file_path, 'r', tonumber('666', 8))
  if not fd then
    return empty_lines()
  end
  vim.loop.fs_close(fd)

  -- Now comes the HACK part. The original implementation opens the file with
  -- libUV and tries to heuristically find the requested lines, but the thing
  -- is that Vim's buffer loading handles much more than that: UTF-16 decoding,
  -- BOM detection, line ending detection and so on, of which the last one was
  -- what I was particularly interested in. So, by making Vim load the buffer,
  -- I ensure that the behavior of handling loaded and unloaded buffers lines
  -- up exactly.
  local opt_title
  if not was_loaded then
    -- Suspend updates to the terminal title, otherwise it will flash with the
    -- files that are being processed. Note that unsetting `title` doesn't
    -- actually clear the window title (though this is not the case with GUIs,
    -- apparently...).
    opt_title = vim.api.nvim_get_option('title')
    vim.api.nvim_set_option('title', false)
    -- This is the core part of the hack: we use bufload, just like slow path,
    -- but disable autocommands, so that plugins don't run and slow down the
    -- process. NOTE: But then again, this is literally thousands of times
    -- slower than the default implementation...
    vim.cmd(string.format('noautocmd call bufload(%d)', bufnr))
  end
  -- pcall here works as a sort of try-finally block.
  local ok, lines = xpcall(buf_lines, debug.traceback)
  if not was_loaded then
    -- Unload the buffer once we finish the job. This is to ensure that
    -- autocommands like syntax and ftplugins that we ignored run the next time
    -- the file is opened for real by the user.
    vim.cmd(string.format('noautocmd %dbunload', bufnr))
    vim.api.nvim_set_option('title', opt_title)
  end
  -- Rethrows the error if it has occured.
  assert(ok, lines)

  return lines
end

function M.get_buf_line(bufnr, linenr)
  return M.get_buf_lines_batch(bufnr, { [linenr] = true })[linenr]
end

-- In v0.6.0 this function and `get_line` are no longer exported, but I
-- "polyfill" those to use my internals instead because plugins may perform a
-- check like this: <https://github.com/folke/trouble.nvim/blob/aae12e7b23b3a2b8337ec5b1d6b7b4317aa3929b/lua/trouble/util.lua#L149-L155>.
function lsp.util.get_lines(bufnr, lines)
  local lines_request
  for _, linenr in ipairs(lines) do
    lines_request[linenr] = true
  end
  return M.get_buf_lines_batch(bufnr, lines_request)
end

function lsp.util.get_line(bufnr, linenr)
  return M.get_buf_line(bufnr, linenr)
end

-- <https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#position>
-- See also: <https://github.com/neovim/neovim/blob/v0.5.0/runtime/lua/vim/lsp/util.lua#L155-L181>.
function M.position_to_linenr_colnr(bufnr, position, offset_encoding)
  if type(position) ~= 'table' then
    error(string.format('position: expected table, got %s', type(position)))
  end
  local linenr = position.line
  local line_text = M.get_buf_line(bufnr, linenr)
  local colnr = M.char_offset_to_byte_offset(position.character, line_text, offset_encoding)
  return linenr, colnr
end

-- See also: <https://github.com/neovim/neovim/blob/v0.5.0/runtime/lua/vim/lsp/util.lua#L1736-L1746>.
function M.linenr_colnr_to_position(bufnr, linenr, colnr, offset_encoding)
  if type(linenr) ~= 'number' then
    error(string.format('linenr: expected number, got %s', type(linenr)))
  end
  if type(colnr) ~= 'number' then
    error(string.format('colnr: expected number, got %s', type(colnr)))
  end
  local line_text = M.get_buf_line(bufnr, linenr)
  local charnr = M.byte_offset_to_char_offset(colnr, line_text, offset_encoding)
  return { line = linenr, character = charnr }
end

-- The default implementation actually doesn't treat text as UTF-16 (instead
-- operates on UTF-32) and I have more additional checks.
-- See also: <https://github.com/neovim/neovim/blob/v0.5.0/runtime/lua/vim/lsp/util.lua#L155-L181>.
function lsp.util._get_line_byte_from_position(bufnr, position, offset_encoding)
  local _, colnr = M.position_to_linenr_colnr(bufnr, position, offset_encoding)
  return colnr
end

-- The default implementation wastes time on a redundant conversion
-- (vim_uri.uri_from_bufnr, to pass the URI to lsp.util.get_line, even though
-- bufnr is already known and usage of nvim_buf_get_lines is not forbidden).
-- And also its users (only lsp.util.make_given_range_params) suffer from the
-- same problem as above, operating on UTF-32 instead of UTF-16. See also:
-- <https://github.com/neovim/neovim/blob/v0.5.0/runtime/lua/vim/lsp/util.lua#L1858-L1872>.
-- These problems have largely been addressed in version 0.6.0.
function lsp.util.character_offset(bufnr, linenr, colnr)
  local charnr = M.linenr_colnr_to_position(bufnr, linenr, colnr).character
  -- HACK: Violation of an API contract of lsp.util.character_offset() (which
  -- returns the UTF-32 AND UTF-16 indices as a pair), but eh, not like many
  -- care about UTF-16 vs UTF-32 these days.
  return charnr, charnr
end

-- See also: <https://github.com/neovim/neovim/blob/v0.5.0/runtime/lua/vim/lsp/util.lua#L1736-L1746>.
function M.make_cursor_position(winid)
  local bufnr = vim.api.nvim_win_get_buf(winid)
  local linenr, colnr = utils.unpack2(vim.api.nvim_win_get_cursor(winid))
  return M.linenr_colnr_to_position(bufnr, linenr - 1, colnr)
end

function M.make_cursor_range(winid)
  local position = M.make_cursor_position(winid)
  -- Remember: in VSCode the character is a beam and not a block, hence you
  -- shouldn't make a range containing a single character - that would be a
  -- selection.
  return { start = position, ['end'] = position }
end

-- <https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#textDocumentPositionParams>
-- See also: <https://github.com/neovim/neovim/blob/v0.5.0/runtime/lua/vim/lsp/util.lua#L1748-L1757>.
function lsp.util.make_position_params()
  return {
    textDocument = lsp.util.make_text_document_params(),
    position = M.make_cursor_position(),
  }
end

-- See also: <https://github.com/neovim/neovim/blob/v0.5.0/runtime/lua/vim/lsp/util.lua#L1759-L1772>.
function lsp.util.make_range_params()
  return {
    textDocument = lsp.util.make_text_document_params(),
    range = M.make_cursor_range(),
  }
end

-- Add NUL-byte support.
-- See also: <https://github.com/neovim/neovim/blob/v0.5.0/runtime/lua/vim/lsp/util.lua#L1268-L1341>.
local orig_util_make_floating_popup_size = lsp.util._make_floating_popup_size
function lsp.util._make_floating_popup_size(contents, ...)
  local contents_patched = {}
  for i, line in ipairs(contents) do
    contents_patched[i] = string.gsub(line, '%z', '\n')
  end
  return orig_util_make_floating_popup_size(contents_patched, ...)
end

-- `byte_idx` is 0-based, returned `linenr` and `colnr` are 0-based as well.
function M.byte_offset_to_linenr_colnr_in_str(byte_idx, text)
  vim.validate({
    byte_idx = { byte_idx, 'number' },
    text = { text, 'string' },
  })
  -- We are really only interested in the text preceding the `byte_idx`. Also,
  -- note that we are operating here (and in the remaining part of this
  -- function) in terms of Lua's 1-based indexes, but since `byte_idx` is
  -- 0-based, the string will be sliced up to the character that `byte_idx`
  -- really points to (in other words, the final character is excluded).
  text = text:sub(1, byte_idx)
  local line_start_idx = 1 -- This one (along with `line_end_idx`) is 1-based.
  local linenr = 0 -- However, this one is 0-based.
  while true do
    local line_end_idx = text:find('\n', line_start_idx, true)
    if line_end_idx then
      linenr = linenr + 1
      line_start_idx = line_end_idx + 1
    else
      local colnr = #text - (line_start_idx - 1) -- This one is 0-based.
      return linenr, colnr
    end
  end
end

function M.range_contains_position(range, pos)
  local start_pos, end_pos = range.start, range['end']
  if pos.line < start_pos.line or pos.line > end_pos.line then
    return false
  end
  if pos.line == start_pos.line and pos.character < start_pos.character then
    return false
  end
  -- NOTE: LSP ranges are exclusive at the end position
  if pos.line == end_pos.line and pos.character >= end_pos.character then
    return false
  end
  return true
end

-- }}}

-- LOCATIONS AND LOCATION LISTS {{{

-- Extension of <https://github.com/neovim/neovim/blob/v0.5.0/runtime/lua/vim/lsp/util.lua#L1629-L1638>.
-- Fortunately, the function is really tiny.
function lsp.util.set_qflist(items, opts)
  if opts == nil then
    opts = vim.empty_dict()
  end
  vim.call(
    'dotfiles#utils#push_qf_list',
    vim.tbl_extend('keep', opts, {
      title = 'Language Server',
      items = items,
    })
  )
end

local orig_util_preview_location = lsp.util.preview_location
function lsp.util.preview_location(location, opts, ...)
  opts = opts or {}
  opts.max_width = opts.max_width or lsp_global_settings.LOCATION_PREVIEW_WINDOW_MAX_WIDTH
  opts.max_height = opts.max_height or lsp_global_settings.LOCATION_PREVIEW_WINDOW_MAX_HEIGHT
  opts.wrap = opts.wrap or false
  return orig_util_preview_location(location, opts, ...)
end

-- Copy of <https://github.com/neovim/neovim/blob/v0.5.0/runtime/lua/vim/lsp/util.lua#L1560-L1615>
-- with multibyte character support, simplified code and current item tracking.
function M.locations_to_items(locations, current_text_doc_pos)
  local ranges_grouped_by_uri = {}
  local sorted_uris = {}
  for _, location in ipairs(locations) do
    -- locations may be Location or LocationLink
    -- <https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#location>
    -- <https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#locationLink>
    local uri = location.uri or location.targetUri
    local range = location.range or location.targetSelectionRange
    local group = ranges_grouped_by_uri[uri]
    if group ~= nil then
      table.insert(group, range)
    else
      ranges_grouped_by_uri[uri] = { range }
      table.insert(sorted_uris, uri)
    end
  end
  table.sort(sorted_uris)

  local items = {}
  local current_item_idx = nil
  for _, uri in ipairs(sorted_uris) do
    local ranges = ranges_grouped_by_uri[uri]
    table.sort(ranges, function(range_a, range_b)
      local pos_a, pos_b = range_a.start, range_b.start
      if pos_a.line ~= pos_b.line then
        return pos_a.line < pos_b.line
      end
      return pos_a.character < pos_b.character
    end)
    local filename = vim_uri.uri_to_fname(uri)

    local lines_request = {}
    for _, range in ipairs(ranges) do
      lines_request[range.start.line] = true
    end
    M.get_buf_lines_batch(vim_uri.uri_to_bufnr(uri), lines_request)

    for _, range in ipairs(ranges) do
      local item_idx = #items + 1
      if
        current_text_doc_pos
        and not current_item_idx
        and uri == current_text_doc_pos.textDocument.uri
        and M.range_contains_position(range, current_text_doc_pos.position)
      then
        current_item_idx = item_idx
      end
      local line = lines_request[range.start.line]
      local col = M.char_offset_to_byte_offset(range.start.character, line)
      items[item_idx] = {
        filename = filename,
        lnum = range.start.line + 1,
        col = col + 1,
        text = line,
      }
    end
  end
  return items, current_item_idx
end

function lsp.util.locations_to_items(locations)
  local items = M.locations_to_items(locations)
  return items
end

-- NOTE: <https://github.com/neovim/neovim/pull/16520>
if not utils_vim.has('nvim-0.7.0') then
  local orig_jump_to_location = lsp.util.jump_to_location
  function lsp.util.jump_to_location(...)
    local ok = orig_jump_to_location(...)
    if ok then
      vim.cmd([[normal! zv]])
    end
    return ok
  end
end

-- Essentially a copy of <https://github.com/neovim/neovim/blob/v0.5.0/runtime/lua/vim/lsp/handlers.lua#L282-L307>.
function M.jump_to_location_maybe_many(locations, opts)
  if not locations or vim.tbl_isempty(locations) then
    return
  end
  if not vim.tbl_islist(locations) then
    locations = { locations }
  end
  local list_opts = {}
  list_opts.title = opts.title or 'Language Server'
  list_opts.items, list_opts.idx = M.locations_to_items(locations, opts.current_position_params)
  list_opts.dotfiles_auto_open = #locations > 1
  vim.call('dotfiles#utils#push_qf_list', list_opts)
  if #locations == 1 then
    lsp.util.jump_to_location(locations[1])
  end
end

-- }}}

-- The reference implementation of my Simple Line Diffing algorithm. One of its
-- major uses is described in the `dotfiles.rplugin_bridge` module.
function M.simple_line_diff(old_lines, new_lines, search_from_start_offset, search_from_end_offset)
  vim.validate({
    old_lines = { old_lines, 'table' },
    new_lines = { new_lines, 'table' },
    search_from_start_offset = { search_from_start_offset, 'number', true },
    search_from_end_offset = { search_from_end_offset, 'number', true },
  })
  local old_lines_len, new_lines_len = #old_lines, #new_lines
  local min_lines_len = math.min(old_lines_len, new_lines_len)

  local common_lines_from_start, common_lines_from_end = 0, 0
  for i = search_from_start_offset or 1, min_lines_len do
    if old_lines[i] ~= new_lines[i] then
      break
    end
    common_lines_from_start = common_lines_from_start + 1
  end
  if old_lines_len == new_lines_len and common_lines_from_start == old_lines_len then
    -- No changes have been made at all!
    return false, common_lines_from_start, common_lines_from_end
  end
  for i = search_from_end_offset or 1, min_lines_len - common_lines_from_start do
    if old_lines[old_lines_len - i + 1] ~= new_lines[new_lines_len - i + 1] then
      break
    end
    common_lines_from_end = common_lines_from_end + 1
  end

  assert(old_lines_len >= common_lines_from_start + common_lines_from_end, 'sanity check')
  assert(new_lines_len >= common_lines_from_start + common_lines_from_end, 'sanity check')
  return true, common_lines_from_start, common_lines_from_end
end

if lsp_sync_available then
  local orig_compute_diff = lsp_sync.compute_diff
  --- The callback for on_lines sometimes receives "inefficient" events whose
  --- reported range of changes (firstline/lastline/new_lastline) is larger
  --- than the actual change. In other words, these "inefficient" events also
  --- include unchanged lines. This patch narrows down the
  --- firstline/lastline/new_lastline parameters to a range without those
  --- unchanged lines.
  function lsp_sync.compute_diff(prev_lines, curr_lines, firstline, lastline, new_lastline, ...)
    -- Note that firstline and lastline are 0-indexed, and lastline is exclusive.
    -- This means that lastline is effectively 1-indexed already, but firstline
    -- needs to be incremented before using it for indexing into Lua tables, or
    -- ranges in Lua loops.
    -- Speaking of loops: the ranges may not make sense at first, but it is
    -- because this code doesn't actually read the counter variable and cares
    -- only about the number of steps taken by the loops.

    -- Within the firstline/lastline range, find the first line that was actually changed.
    for _ = firstline + 1, math.min(lastline, new_lastline) do
      if prev_lines[firstline + 1] ~= curr_lines[firstline + 1] then
        break
      end
      firstline = firstline + 1
    end

    if lastline == new_lastline and firstline == new_lastline then
      -- The lengths of both previous and current ranges (lastline - firstline
      -- == new_lastline - firstline, which is equivalent to lastline ==
      -- new_lastline) match, which means no lines were added or removed, and
      -- all lines in the range between firstline and lastline were equivalent
      -- to the range firstline to new_lastline (and so were all skipped, as
      -- such firstline == new_lastline), thus no insertions or deletions or
      -- changes were made at all.
      return nil
    end

    -- Repeat the logic in the first loop, but in the reverse direction, to
    -- find the last line with actual changes.
    for _ = math.min(lastline, new_lastline), firstline + 1, -1 do
      if prev_lines[lastline] ~= curr_lines[new_lastline] then
        break
      end
      lastline = lastline - 1
      new_lastline = new_lastline - 1
    end

    return orig_compute_diff(prev_lines, curr_lines, firstline, lastline, new_lastline, ...)
  end
end

--- :SanCheeseAngry: <https://github.com/neovim/neovim/pull/15504> {{{
if utils_vim.has('nvim-0.5.1') then
  ---@param handler fun(err: any, result: any, context: any, config: any): any
  ---@return fun(err: any, result: any, context: any, config: any): any
  function M.wrap_handler_compat(handler)
    return handler
  end

  ---@param handler fun(result: any, context: any, config: any): any
  ---@return fun(err: any, result: any, context: any, config: any): any
  function M.wrap_handler_errors(handler)
    return function(err, result, ctx, config, ...)
      if err then
        M.client_notify(ctx.client_id, err, vim.log.levels.ERROR)
        return
      end
      return handler(result, ctx, config, ...)
    end
  end

  ---@param handler fun(err: any, result: any, context: any, config: any): any
  ---@param err any
  ---@param result any
  ---@param context any
  ---@param config any
  ---@return any
  function M.call_handler_compat(handler, err, result, context, config, ...)
    return handler(err, result, context, config, ...)
  end
else
  ---@param handler fun(err: any, result: any, context: any, config: any): any
  ---@return fun(err: any, method: string, result: any, client_id: number, bufnr: number, config: any): any
  function M.wrap_handler_compat(handler)
    return function(err, method, result, client_id, bufnr, config, ...)
      return handler(
        err,
        result,
        { method = method, client_id = client_id, bufnr = bufnr },
        config,
        ...
      )
    end
  end

  ---@param handler fun(result: any, context: any, config: any): any
  ---@return fun(err: any, method: string, result: any, client_id: number, bufnr: number, config: any): any
  function M.wrap_handler_errors(handler)
    return function(err, method, result, client_id, bufnr, config, ...)
      if err then
        M.client_notify(client_id, err, vim.log.levels.ERROR)
        return
      end
      return handler(
        result,
        { method = method, client_id = client_id, bufnr = bufnr },
        config,
        ...
      )
    end
  end

  ---@param handler fun(err: any, method: string, result: any, client_id: number, bufnr: number, config: any): any
  ---@param err any
  ---@param result any
  ---@param context any
  ---@param config any
  ---@return any
  function M.call_handler_compat(handler, err, result, context, config, ...)
    return handler(err, context.method, result, context.client_id, context.bufnr, config, ...)
  end
end
-- }}}

-- See also: <https://github.com/neovim/neovim/blob/v0.5.0/runtime/lua/vim/lsp/util.lua#L1815-L1821>,
-- <https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#textDocumentIdentifier>.
function lsp.util.make_text_document_params(bufnr)
  return { uri = vim_uri.uri_from_bufnr(bufnr) }
end

-- See also: <https://github.com/neovim/neovim/blob/v0.5.0/runtime/lua/vim/lsp/util.lua#L1815-L1821>,
-- <https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#versionedTextDocumentIdentifier>.
function M.make_versioned_text_document_params(bufnr)
  bufnr = utils_vim.normalize_bufnr(bufnr)
  local result = lsp.util.make_text_document_params(bufnr)
  result.version = lsp.util.buf_versions[bufnr]
  return result
end

return M
