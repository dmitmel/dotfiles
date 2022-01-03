local M = require('dotfiles.autoload')('dotfiles.utils.vim')

local utils = require('dotfiles.utils')

M.HLGROUP_NAME_PATTERN = '^[a-zA-Z0-9_]+$' -- :h group-name
M.USER_COMMAND_PATTERN = '^[A-Z][a-zA-Z0-9]*$' -- :h user-cmd-ambiguous
M.FUNCTION_NAME_PATTERN = '^[A-Z_][a-zA-Z0-9_]*$' -- :h :function
M.VARIABLE_NAME_PATTERN = '^[A-Za-z_][A-Za-z0-9_]*$' -- shrug

-- <https://github.com/neovim/neovim/blob/v0.5.0/src/nvim/eval/typval.c#L2963-L3012>
-- <https://github.com/neovim/neovim/blob/v0.5.0/src/nvim/eval.c#L678-L711>
function M.is_truthy(value)
  local t = type(value)
  -- stylua: ignore start
  if t == 'boolean' then return value end
  if t == 'number' then return value ~= 0 end
  if t == 'string' then return value ~= '' end
  if t == 'nil' then return false end
  -- stylua: ignore end
  -- return true
  -- In accordance to the behavior of VimL:
  error(string.format('value of type %s cannot be converted to boolean', type(t)))
end

function M.has(feature)
  return M.is_truthy(vim.fn.has(feature))
end

M.COMMAND_HANDLERS = {}

function M.define_command(cmd_name, def)
  utils.check_type('cmd_name', cmd_name, 'string')
  utils.check_type('def', def, 'table')
  if not cmd_name:match(M.USER_COMMAND_PATTERN) then
    error(string.format('invalid command name %q', cmd_name))
  end
  if M.COMMAND_HANDLERS[cmd_name] ~= nil then
    error(string.format('%s: a command with this name is already registered', cmd_name))
  end

  local definition_parts = {}
  local call_info_parts = {}

  local force = def.force
  if force == nil then
    force = false
  end
  if type(force) ~= 'boolean' then
    error(string.format('%s.force: expected boolean, got %s', cmd_name, type(force)))
  end
  if force == true then
    table.insert(definition_parts, 'command!')
  else
    table.insert(definition_parts, 'command')
  end

  local nargs = def.nargs
  if nargs == nil then
    nargs = '0'
  end
  if type(nargs) ~= 'string' then
    error(string.format('%s.nargs: expected string, got %s', cmd_name, type(nargs)))
  end
  if nargs ~= '0' and nargs ~= '1' and nargs ~= '*' and nargs ~= '?' and nargs ~= '+' then
    error(
      string.format('%s.nargs: expected any of "01*?+", got %s', cmd_name, utils.inspect(nargs))
    )
  end
  table.insert(definition_parts, '-nargs=' .. tostring(nargs))
  if nargs ~= '0' then
    table.insert(call_info_parts, 'q_args=<q-args>')
    if nargs ~= '1' and nargs ~= '?' then
      table.insert(call_info_parts, 'f_args={<f-args>}')
    end
  end

  if def.complete ~= nil then
    -- TODO: validation for -complete=...
    if type(def.complete) ~= 'string' then
      error(string.format('%s.complete: expected string, got %s', cmd_name, type(def.complete)))
    end
    table.insert(definition_parts, '-complete=' .. def.complete)
  end

  local range = def.range
  if range ~= nil then
    if type(range) ~= 'boolean' and type(range) ~= 'string' and type(range) ~= 'number' then
      error(
        string.format(
          '%s.range: expected boolean or string or number, got %s',
          cmd_name,
          type(range)
        )
      )
    end
    if not (range == '%' or type(range) == 'boolean' or type(range) == 'number') then
      error(
        string.format(
          '%s.range: expected "%%" or boolean or number, got %s',
          cmd_name,
          utils.inspect(range)
        )
      )
    end
    if range ~= false then
      if range == true then
        table.insert(definition_parts, '-range')
      elseif type(range) == 'string' then
        table.insert(definition_parts, '-range=' .. range)
      elseif type(range) == 'number' then
        table.insert(definition_parts, string.format('-range=%d', range))
      end
      table.insert(call_info_parts, 'line1=<line1>')
      table.insert(call_info_parts, 'line2=<line2>')
      table.insert(call_info_parts, 'range=<range>')
      table.insert(call_info_parts, 'count=<count>')
    end
  end

  local count = def.count
  if count ~= nil then
    if type(count) ~= 'boolean' and type(count) ~= 'number' then
      error(string.format('%s.count: expected boolean or number, got %s', cmd_name, type(count)))
    end
    if not (type(count) == 'boolean' or (type(count) == 'number')) then
      error(
        string.format(
          '%s.count: expected boolean or number, got %s',
          cmd_name,
          utils.inspect(count)
        )
      )
    end
    if count ~= false then
      if count == true then
        table.insert(definition_parts, '-count')
      else
        table.insert(definition_parts, string.format('-count=%d', count))
      end
      table.insert(call_info_parts, 'count=<count>')
    end
  end

  local addr = def.addr
  if addr ~= nil then
    if type(addr) ~= 'string' then
      error(string.format('%s.addr: expected string, got %s', cmd_name, type(addr)))
    end
    local addr_values = {
      lines = true,
      arguments = true,
      buffers = true,
      loaded_buffers = true,
      windows = true,
      tabs = true,
      quickfix = true,
      other = true,
    }
    if not addr_values[addr] then
      error(
        string.format(
          '%s.addr: expected any of %s, got %s',
          cmd_name,
          utils.inspect(vim.tbl_keys(addr_values)),
          utils.inspect(count)
        )
      )
    end
    table.insert(definition_parts, '-addr=' .. addr)
  end

  if def.bang ~= nil and type(def.bang) ~= 'boolean' then
    error(string.format('%s.bang: expected boolean, got %s', cmd_name, type(def.bang)))
  end
  if def.bang == true then
    table.insert(definition_parts, '-bang')
    table.insert(call_info_parts, 'bang=<q-bang>~=""')
  end

  if def.bar ~= nil and type(def.bar) ~= 'boolean' then
    error(string.format('%s.bar: expected boolean, got %s', cmd_name, type(def.bar)))
  end
  if def.bar == nil or def.bar == true then
    table.insert(definition_parts, '-bar')
  end

  if def.register ~= nil and type(def.register) ~= 'boolean' then
    error(string.format('%s.register: expected boolean, got %s', cmd_name, type(def.register)))
  end
  if def.register == true then
    table.insert(definition_parts, '-register')
    table.insert(call_info_parts, 'reg=<q-reg>')
  end

  if def.mods ~= nil and type(def.mods) ~= 'boolean' then
    error(string.format('%s.mods: expected boolean, got %s', cmd_name, type(def.mods)))
  end
  if def.mods == true then
    table.insert(call_info_parts, 'mods=<q-mods>')
  end

  if def.custom_attrs ~= nil then
    if type(def.custom_attrs) ~= 'string' then
      error(
        string.format('%s.custom_attrs: expected string, got %s', cmd_name, type(def.custom_attrs))
      )
    end
    table.insert(definition_parts, def.custom_attrs)
  end

  table.insert(definition_parts, cmd_name)

  if def.unsilent ~= nil and type(def.unsilent) ~= 'boolean' then
    error(string.format('%s.unsilent: expected boolean, got %s', cmd_name, type(def.unsilent)))
  end
  if def.unsilent == true then
    table.insert(definition_parts, 'unsilent')
  end

  if type(def.handler) ~= 'function' then
    error(string.format('%s.handler: expected function, got %s', cmd_name, type(def.handler)))
  end
  M.COMMAND_HANDLERS[cmd_name] = def.handler
  table.insert(
    definition_parts,
    string.format(
      'lua require("dotfiles.utils.vim").COMMAND_HANDLERS.%s({%s})',
      cmd_name,
      table.concat(call_info_parts, ',')
    )
  )

  vim.cmd(table.concat(definition_parts, ' '))
end

function M.delete_command(cmd_name)
  utils.check_type('cmd_name', cmd_name, 'string')
  if not cmd_name:match(M.USER_COMMAND_PATTERN) then
    error(string.format('invalid command name %q', cmd_name))
  end
  if M.COMMAND_HANDLERS[cmd_name] == nil then
    error(string.format('%s: no command with this name is registered', cmd_name))
  end

  vim.cmd(string.format('delcommand %s', cmd_name))
  M.COMMAND_HANDLERS[cmd_name] = nil
end

M.next_function_id = 0

function M.define_adhoc_function(opts, body)
  utils.check_type('opts', opts, 'table')
  utils.check_type('body', body, 'string')
  utils.check_type('opts.name_suffix', opts.name_suffix, 'string', true)
  utils.check_type('opts.abort', opts.abort, 'boolean', true)
  utils.check_type('opts.range', opts.range, 'boolean', true)

  if opts.name_suffix ~= nil and not opts.name_suffix:match('^[A-Za-z0-9_]*$') then
    error(string.format('invalid function name suffix %q', opts.name_suffix))
  end
  -- The 32-bit length of IDs was chosen arbitrarily.
  if not (1 <= M.next_function_id and M.next_function_id <= 0xffffffff) then
    M.next_function_id = 1
  end
  -- Function names are actually allowed to start with an underscore, amazing.
  -- The documentation says something along the lines of "only uppercase
  -- letters are allowed".
  local actual_name = string.format('_lua%08x%s', M.next_function_id, opts.name_suffix or '')
  M.next_function_id = M.next_function_id + 1

  local def_code = { 'function ', actual_name, '(' }
  for arg_i, arg in ipairs(opts) do
    if type(arg) ~= 'string' then
      error(string.format('args[%d]: expected string, got %s', arg_i, type(arg)))
    end
    if arg_i > 20 then
      error(string.format('a maximum of only 20 arguments is allowed, %d were given', #opts))
    elseif arg == '...' then
      if arg_i < #opts then
        error(string.format('extra arguments marker must be the last in the argument list', arg))
      end
    elseif arg == 'firstline' or arg == 'lastline' then
      error(string.format("%q is a reserved name and can't be used as an argument name", arg))
    elseif not arg:match(M.VARIABLE_NAME_PATTERN) then
      error(string.format('invalid argument name %q', arg))
    end
    if arg_i > 1 then
      table.insert(def_code, ',')
    end
    table.insert(def_code, arg)
  end
  table.insert(def_code, ')')

  if opts.abort == true or opts.abort == nil then
    table.insert(def_code, ' abort')
  end
  if opts.range == true then
    table.insert(def_code, ' range')
  end

  if body:sub(1) ~= '\n' then
    table.insert(def_code, '\n')
  end
  table.insert(def_code, body)
  if body:sub(-1) ~= '\n' then
    table.insert(def_code, '\n')
  end

  table.insert(def_code, 'endfunction')
  vim.cmd(table.concat(def_code))
  return function(...)
    return vim.call(actual_name, ...)
  end, actual_name
end

M.FILEFORMAT_OPTION_TO_NEWLINE_CHAR = {
  dos = '\r\n',
  unix = '\n',
  mac = '\r',
}

function M.buf_get_newline_char(bufnr)
  local ff = vim.api.nvim_buf_get_option(bufnr, 'fileformat')
  return M.FILEFORMAT_OPTION_TO_NEWLINE_CHAR[ff] or '\n'
end

-- Improved version of
-- <https://github.com/neovim/neovim/blob/v0.5.0/runtime/lua/vim/lsp.lua#L256-L267>.
function M.buf_get_full_text(bufnr)
  return M.buf_lines_to_full_text(bufnr, vim.api.nvim_buf_get_lines(bufnr, 0, -1, true))
end

function M.buf_lines_to_full_text(bufnr, lines)
  local nl_char = M.buf_get_newline_char(bufnr)
  local text = table.concat(lines, nl_char)
  if vim.api.nvim_buf_get_option(bufnr, 'endofline') then
    text = text .. nl_char
  end
  return text
end

do
  local function accurate_impl()
    return math.max(0, vim.fn.line2byte(vim.api.nvim_buf_line_count(0) + 1) - 1)
  end
  function M.buf_get_accurate_text_byte_size(bufnr)
    if bufnr == nil or bufnr == 0 then
      return accurate_impl()
    else
      return vim.api.nvim_buf_call(bufnr, accurate_impl)
    end
  end

  function M.buf_get_inmemory_text_byte_size(bufnr)
    return vim.api.nvim_buf_get_offset(bufnr, vim.api.nvim_buf_line_count(bufnr))
  end
end

function M.replace_keys(str)
  return vim.api.nvim_replace_termcodes(str, true, true, true)
end

---@param bufnr number
---@return number
function M.normalize_bufnr(bufnr)
  if bufnr == nil or bufnr == 0 then
    return vim.api.nvim_get_current_buf()
  else
    return bufnr
  end
end

---@param winid number
---@return number
function M.normalize_winid(winid)
  if winid == nil or winid == 0 then
    return vim.api.nvim_get_current_win()
  else
    return winid
  end
end

---@param tabpagenr number
---@return number
function M.normalize_tabpagenr(tabpagenr)
  if tabpagenr == nil or tabpagenr == 0 then
    return vim.api.nvim_get_current_tabpage()
  else
    return tabpagenr
  end
end

M._unsilent_helper = M.define_adhoc_function(
  { 'fun' },
  [[
  unsilent call a:fun()
]]
)

function M.unsilent(fun, ...)
  local args = utils.pack(...)
  local ret
  M._unsilent_helper(function()
    ret = fun(utils.unpack(args, 1, args.n))
  end)
  return ret
end

function M.echo(chunks, hl_group)
  if type(chunks) == 'string' then
    chunks = { chunks, hl_group }
  end
  return vim.api.nvim_echo(chunks, false, {})
end

function M.echomsg(chunks, hl_group)
  if type(chunks) == 'string' then
    chunks = { { chunks, hl_group } }
  end
  return vim.api.nvim_echo(chunks, true, {})
end

return M
