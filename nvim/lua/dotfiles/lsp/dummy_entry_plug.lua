--- ==================== LSP DUMMY ENTRY PLUG ====================
---
--- System for creating dummy Language Servers which don't spawn an actual
--- language server, but instead route all calls to Lua functions. Meant for
--- integration of non-LSP stuff with Neovim's LSP infrastructure. Unlike
--- null-ls doesn't manage launching the fake servers, that is instead a
--- concern of the Ignition system. Under the hood re-implements this module:
--- <https://github.com/neovim/neovim/blob/v0.5.0/runtime/lua/vim/lsp/rpc.lua>.
---
--- See also:
--- How clients are started on a high level - <https://github.com/neovim/neovim/blob/v0.5.0/runtime/lua/vim/lsp.lua#L546-L1024>
--- How RPC actually starts the clients - <https://github.com/neovim/neovim/blob/v0.5.0/runtime/lua/vim/lsp/rpc.lua#L290-L620>
--- How null-ls tackles launching a fake client - <https://github.com/jose-elias-alvarez/null-ls.nvim/blob/2c9690964b91e34b421326dc4839b322a7b1a6cd/lua/null-ls/rpc.lua>
--- How nvim-lint does the same - <https://github.com/mfussenegger/nvim-lint/blob/71b3a9254cff246d057e91ea7ba66f76042de6a9/lua/lint.lua>
---
--- WARNING: My implementation of this is (potentially) very fragile, although
--- provides a nice interface. Be sure to update it if something significant in
--- the internals of `lsp.start_client` and/or `lsp.rpc` changes, there are
--- failsafes in place which can notify about that.
local M = require('dotfiles.autoload')('dotfiles.lsp.dummy_entry_plug')

-- TODO: Better request cancellation? Copy VSCode's CancellationToken abstraction. <https://github.com/microsoft/vscode/blob/1.59.1/src/vs/base/common/cancellation.ts>

-- TODO: integrate vint for vimscript
-- TODO: integrate shellcheck for bash

-- TODO: general-purpose subprocess formatter
-- <https://github.com/fannheyward/coc-pyright/blob/a0da59feef3cfa9f0e5bff0d4e6e705fea256bb9/src/formatters/baseFormatter.ts#L41-L59>

local lsp = require('vim.lsp')
local LspErrorCodes = lsp.protocol.ErrorCodes
local lsp_ignition = require('dotfiles.lsp.ignition')
local utils = require('dotfiles.utils')

M._RPC_FAKE_COMMAND_COOKIE = vim.v.progpath
M._RPC_FAKE_ENV_COOKIE = M.__module.name

local orig_start_client = lsp.start_client
function lsp.start_client(...)
  local config = ...
  if not config.virtual_server then
    return orig_start_client(...)
  end

  -- This is the trigger that `lsp.rpc.start()` will recognize. Note that a
  -- command has to be defined for the config to pass validation.
  config.cmd = { M._RPC_FAKE_COMMAND_COOKIE }
  -- This one is not useful to us anymore.
  config.cmd_cwd = nil
  -- We are using `cmd_env` as a side-channel for smuggling our callbacks in
  -- because it is one of the few config values (apart from `cmd` and
  -- `cmd_cwd`, both of which can be only strings and are validated anyway)
  -- that are passed on to `lsp.rpc.start()`. Additionally, the default API
  -- explicitly allows non-string values and the documentation for
  -- `lsp.start()` specifies that they will normally be converted to strings
  -- before setting the env variables.
  config.cmd_env = {
    [M._RPC_FAKE_ENV_COOKIE] = setmetatable({
      name = config.name,
      config = config.virtual_server,
    }, {
      -- In our case, however, we hijack the code path in `lsp.rpc.start()`
      -- (which leads to stringification of env variables), so we can get our
      -- original table untouched. Although I still add a `__tostring()` just
      -- to catch potential changes in the internals.
      __tostring = function()
        error(
          'this function is not supposed to ever be invoked! some internals of '
            .. 'lsp.start_client() and lsp.rpc.start() have changed, the '
            .. M.__module.name
            .. ' module needs updating!'
        )
      end,
    }),
  }

  local client_id = orig_start_client(...)
  local client = lsp.get_client_by_id(client_id)
  -- Last but not least, smuggle the client ID in.
  client.rpc.virtual_server.client_id = client_id
  return client_id
end

-- The reason for overwriting `lsp.rpc.start()` is that we can get real client
-- IDs allocated to us which will never collide with the IDs for normal clients
-- (the ID counter is, unfortunately, private).
local orig_rpc_start = lsp.rpc.start
function lsp.rpc.start(...)
  local cmd = ...
  if cmd == M._RPC_FAKE_COMMAND_COOKIE then
    return M.fake_rpc_start(...)
  else
    return orig_rpc_start(...)
  end
end

---@alias dotfiles.VirtualServerRunState number
M.VirtualServerRunState = vim.tbl_add_reverse_lookup({
  Uninitialized = 1,
  Initializing = 2,
  Active = 3,
  Stopping = 4,
  Exited = 5,
})

-- <https://github.com/jose-elias-alvarez/null-ls.nvim/blob/f907d945d0285f42dc9ebffbc075ea725b93b6aa/lua/null-ls/rpc.lua#L12-L21>
M.default_virtual_server_capabilities = {
  -- <https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#textDocumentSyncOptions>
  -- (there are actually multiple instances of this interface in the spec)
  -- textDocumentSync = {
  --   openClose = false;
  --   change = lsp.protocol.TextDocumentSyncKind.None;
  -- };
}

-- <https://github.com/neovim/neovim/blob/v0.5.0/runtime/lua/vim/lsp/rpc.lua#L194-L202>
M.virtual_server_errors = vim.tbl_add_reverse_lookup({
  ON_INIT_CALLBACK_ERROR = 1,
  ON_EXIT_CALLBACK_ERROR = 2,
  CLIENT_REQUEST_HANDLER_ERROR = 3,
  CLIENT_REQUEST_CALLBACK_ERROR = 4,
})

function M.fake_rpc_start(cmd, cmd_args, dispatchers, extra_spawn_params)
  utils.check_type('cmd', cmd, 'string')
  utils.check_type('cmd_args', cmd_args, 'table')
  utils.check_type('dispatchers', dispatchers, 'table')
  utils.check_type('extra_spawn_params', extra_spawn_params, 'table')

  local fake_cake = extra_spawn_params.env[M._RPC_FAKE_ENV_COOKIE]
  local vserver = M.VirtualServer.new(fake_cake.name, fake_cake.config, nil, dispatchers)

  local rpc = {
    virtual_server = vserver,
    pid = -1,
    handle = {
      kill = function()
        vserver:force_stop()
      end,
      is_closing = function()
        return vserver.run_state >= M.VirtualServerRunState.Exited
      end,
    },
    notify = function(method, params)
      return vserver:recv_message(method, params, nil)
    end,
    request = function(method, params, callback)
      return vserver:recv_message(method, params, callback)
    end,
  }

  return rpc
end

---@alias dotfiles.VirtualServerHandlerReply fun(error: any|nil, response: any|nil, ...): any
---@alias dotfiles.VirtualServerOnError fun(code: number, error: any, vserver: dotfiles.VirtualServer)
---@alias dotfiles.VirtualServerOnInit fun(vserver: dotfiles.VirtualServer, initialize_params: any, initialize_result: any)
---@alias dotfiles.VirtualServerHandler fun(reply: dotfiles.VirtualServerHandlerReply, method: string, params: any, request_id: number, vserver: dotfiles.VirtualServer)

---@class dotfiles.VirtualServer
---@field run_state dotfiles.VirtualServerRunState
---@field client_id number
---@field client_dispatchers { notification: any, server_request: any, on_error: any, on_exit: any }
---@field name string
---@field config table - TODO write types for this field
---@field handlers table<string, dotfiles.VirtualServerHandler>
---@field on_error dotfiles.VirtualServerOnError
---@field ext table
---@field _next_client_request_id number
---@field _next_server_request_id number
---@field _pending_client_requests table<number, boolean>
---@field _pending_server_requests table<number, boolean>
---@field root_dir string|nil
---@field root_uri string|nil
M.VirtualServer = {}
M.VirtualServer.__index = M.VirtualServer

function M.VirtualServer.new(name, config, client_id, client_dispatchers)
  utils.check_type('name', name, 'string')
  utils.check_type('config', config, 'table')
  utils.check_type('client_id', client_id, 'number', true)
  utils.check_type('client_dispatchers', client_dispatchers, 'table')

  utils.check_type('config.capabilities', config.capabilities, 'table', true)
  utils.check_type('config.handlers', config.handlers, 'table', true)
  utils.check_type('config.on_init', config.on_init, 'function', true)
  utils.check_type('config.on_error', config.on_error, 'function', true)
  utils.check_type('config.on_exit', config.on_exit, 'function', true)

  local self = setmetatable({}, M.VirtualServer)

  -- For user methods and fields.
  self.ext = {}

  self.run_state = M.VirtualServerRunState.Uninitialized
  self.client_id = client_id
  self.client_dispatchers = client_dispatchers

  self.name = name
  self.config = config
  self.handlers = config.handlers or {}
  self.on_error = config.on_error or function(...)
    return self:default_error_handler(...)
  end

  self._next_client_request_id = 0
  self._next_server_request_id = 0
  self._pending_client_requests = {}
  self._pending_server_requests = {}

  return self
end

--- <https://github.com/neovim/neovim/blob/v0.5.0/runtime/lua/vim/lsp.lua#L704-L721>
---@param code number
---@param err any
function M.VirtualServer:default_error_handler(code, err)
  if type(code) == 'number' then
    code = M.virtual_server_errors[code]
  else
    code = tostring(code)
  end
  if type(err) ~= 'string' then
    err = utils.inspect(err)
  end
  vim.api.nvim_err_write(string.format('LSVS[%s]: Error %s: %s\n', self.name, code, err))
end

---@param method string
---@param params any
---@param callback fun(error: any|nil, result: any|nil)
---@return boolean sucesss
---@return number request_id
function M.VirtualServer:recv_message(method, params, callback)
  utils.check_type('method', method, 'string')
  utils.check_type('callback', callback, 'function', true)
  local request_id = nil
  if callback then
    -- Yeah, the logic of message ID allocation is weird: it is only done for
    -- requests (i.e. not for notifications), and even when the server has
    -- been stopped. This replicates the behavior of the stock `lsp.rpc`
    -- module, but, to be fair, I don't have to do it.
    self._next_client_request_id = self._next_client_request_id + 1
    request_id = self._next_client_request_id
  end
  if self.run_state >= M.VirtualServerRunState.Exited then
    return false
  end

  if request_id then
    self._pending_client_requests[request_id] = true
  end
  local function is_cancelled()
    if request_id then
      return not self._pending_client_requests[request_id]
    else
      return false
    end
  end

  local replied = false
  local function reply(...)
    assert(not replied, 'a reply has already been sent')
    replied = true
    if callback and not is_cancelled() then
      self._pending_client_requests[request_id] = nil
      return callback(...)
    end
  end

  -- The real handling must happen asynchronously.
  local function actually_handle_message_from_client()
    -- Phase 1: Early exit.
    if self.run_state >= M.VirtualServerRunState.Exited or is_cancelled() then
      return
    end

    -- Phase 2: Handle "special" methods, in particular ones which affect the
    -- run state.
    if method == 'initialize' then -- <https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#initialize>
      if self.run_state == M.VirtualServerRunState.Uninitialized then
        self.run_state = M.VirtualServerRunState.Initializing
        local response = self:_handle_initialize_request(params)
        return reply(nil, response)
      end

      --
    elseif method == 'initialized' then -- <https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#initialized>
      if self.run_state == M.VirtualServerRunState.Initializing then
        self.run_state = M.VirtualServerRunState.Active
        return reply(nil)
      end

      --
    elseif method == 'shutdown' then -- <https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#shutdown>
      if self.run_state == M.VirtualServerRunState.Active then
        self.run_state = M.VirtualServerRunState.Stopping
        return reply(nil)
      end

      --
    elseif method == 'exit' then -- <https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#exit>
      -- As far as I understand, this notification can be sent at any run
      -- state. Well, at least before `initialize` is sent, that one is
      -- explicitly stated by the spec.
      self:force_stop()
      self.run_state = M.VirtualServerRunState.Exited
      return reply(nil)

      --
    elseif method == '$/cancelRequest' then -- <https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#cancelRequest>
      -- Poor man's request cancellation.
      if params and params.id then
        self._pending_client_requests[params.id] = nil
      end
      return reply(nil)

      --
    else
      -- Phase 3: Handle "regular" methods.
      if self.run_state == M.VirtualServerRunState.Active then
        local handler = self.handlers[method]
        if not handler then
          return reply(lsp.rpc_response_error(LspErrorCodes.MethodNotFound))
        end
        -- Thank God this stuff is asynchronous by design, otherwise I'd have
        -- return parameters like `rpc_result_or_lua_err`.
        local ok, err = xpcall(handler, debug.traceback, reply, method, params, request_id, self)
        if not ok then
          pcall(self.on_error, M.virtual_server_errors.CLIENT_REQUEST_HANDLER_ERROR, err, self)
          if not replied then
            return reply(lsp.rpc_response_error(LspErrorCodes.InternalError, nil, err))
          end
        end
        return
      end
    end

    -- Phase 4: Handle errors due to invalid run states.
    if self.run_state < M.VirtualServerRunState.Active then
      return reply(lsp.rpc_response_error(LspErrorCodes.ServerNotInitialized))
    end
    return reply(lsp.rpc_response_error(LspErrorCodes.InvalidRequest))
  end

  -- NOTE: I want to mention that at first I tried to come up with some
  -- clever solution involving `uv_check_t` for dispatching client request
  -- handlers and stuff, primarily because `vim.schedule()` unconditionally
  -- causes the screen to be refreshed (or, at least, the statusline to be
  -- recomputed) for some reason (on every loop tick, I hope). However, the
  -- main reason why I didn't do that is because the actual handlers that for
  -- common tasks will almost always use Vim or API functions
  -- (`nvim_buf_get_lines` is probably the most obvious example), so they
  -- will have to be deferred with `vim.schedule()` regardless, and in the
  -- case of `uv_check_t` I wouldn't actually win anything because I'd have
  -- to do two reschedulings of the request callback.
  --
  -- P.S. `vim.schedule` callbacks should be executed in the order of
  -- registration if I understand the codebase correctly... So I don't need
  -- to ensure a single callback per one loop tick either.
  vim.schedule(function()
    local ok, err = xpcall(actually_handle_message_from_client, debug.traceback)
    if not ok then
      vim.api.nvim_err_write(tostring(err) .. '\n')
    end
  end)

  return true, request_id
end

---@param params any
---@return any
function M.VirtualServer:_handle_initialize_request(params)
  if params.rootUri ~= nil and params.rootUri ~= vim.NIL then
    self.root_uri = params.rootUri
    self.root_dir = utils.uri_maybe_to_fname(params.rootUri)
  end

  -- <https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#initializeResult>
  local response = {
    capabilities = vim.tbl_deep_extend(
      'force',
      M.default_virtual_server_capabilities,
      self.config.capabilities or vim.empty_dict()
    ),
    serverInfo = {
      name = M.__module.name,
    },
  }

  if self.config.on_init then
    -- We handle errors correctly, UNLIKE THE DEFAULT IMPLEMENTATION
    -- <https://cdn.discordapp.com/emojis/737998832884777013.png?name=lenya>
    local ok, err = xpcall(self.config.on_init, debug.traceback, self, params, response)
    if not ok then
      pcall(self.on_error, M.virtual_server_errors.ON_INIT_CALLBACK_ERROR, err, self)
    end
  end
  return response
end

---@param method string
---@param params any
---@param callback any - TODO
function M.VirtualServer:send_message(method, params, callback)
  utils.check_type('method', method, 'string')
  utils.check_type('callback', callback, 'function', true)
  if callback then
    error('server requests are not implemented currently')
  else
    local ok, err = xpcall(self.client_dispatchers.notification, debug.traceback, method, params)
    if not ok then
      pcall(self.on_error, M.virtual_server_errors.ON_INIT_CALLBACK_ERROR, err, self)
    end
  end
end

function M.VirtualServer:force_stop()
  if self.run_state >= M.VirtualServerRunState.Exited then
    return
  end
  self.run_state = M.VirtualServerRunState.Exited
  self._pending_client_requests = nil
  if self.config.on_exit then
    local ok, err = xpcall(self.config.on_exit, debug.traceback, self)
    if not ok then
      pcall(self.on_error, M.virtual_server_errors.ON_EXIT_CALLBACK_ERROR, err, self)
    end
  end
  -- Both must be zero, so that the exit is treated as clean.
  self.client_dispatchers.on_exit(0, 0) -- code, signal
end

-- function M.setup_formatter(config_name, config)
--   utils.check_type('config_name', config_name, 'string')
--   utils.check_type('config', config, 'table')
--
--   utils.check_type('config.filetypes', config.filetypes, 'table', true)
--   utils.check_type('config.root_dir', config.root_dir, 'function', true)
--
--   lsp_ignition.setup_config(config_name, {
--     filetypes = config.filetypes,
--     root_dir = config.root_dir,
--     single_file_support = true,
--
--     virtual_server = {
--       documentFormattingProvider = true,
--       documentRangeFormattingProvider = true, -- TODO
--     },
--   })
-- end

return M
