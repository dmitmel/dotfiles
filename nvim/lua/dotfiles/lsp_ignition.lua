local M, module = require('dotfiles.autoload')('dotfiles.lsp_ignition', {})

local lsp = require('vim.lsp')
local utils = require('dotfiles.utils')
local lsp_extras = require('dotfiles.lsp_extras')
local Settings = require('dotfiles.lsp_settings')

---@alias dotfiles.lsp.RootMarker string | string[] | (fun(name: string, path: string): boolean)

---@class dotfiles.lsp.Config : vim.lsp.Config
---@field enabled? fun(bufnr: integer): boolean
---@field on_new_config? fun(new_config: dotfiles.lsp.Config, new_root_dir: string, igniter: dotfiles.lsp.Igniter)
---@field root_markers? dotfiles.lsp.RootMarker[]
---@field build_settings? fun(ctx: dotfiles.lsp.SettingsContext)

local function make_table() return {} end
local function make_weak_table() return setmetatable({}, { __mode = 'kv' }) end

---@type table<string, dotfiles.lsp.Igniter> config name -> igniter
M.enabled_igniters = M.enabled_igniters or {}
---@type table<string, table<dotfiles.lsp.Igniter, unknown>> filetype -> set<igniter>
M.igniters_by_filetype = M.igniters_by_filetype or {}
---@type table<string, table<integer, unknown>> root_dir -> set<bufnr>
M.buffers_by_root_dir = M.buffers_by_root_dir or {}
---@type table<integer, dotfiles.lsp.Igniter> client_id -> igniter
M.launched_clients = M.launched_clients or {}
---@type table<integer, table<integer, dotfiles.lsp.Igniter>> bufnr -> client_id -> igniter
M.clients_by_buffer = M.clients_by_buffer or {}
---@type table<vim.lsp.protocol.Method|string, lsp.Handler>
M.default_handlers = M.default_handlers or {}

---@generic K, V
---@param tbl table<K, V>
---@param key K
---@param make_value fun(): V
---@return V
local function get_or_insert(tbl, key, make_value)
  local value = tbl[key]
  if value == nil then
    value = make_value()
    tbl[key] = value
  end
  return value
end

---@generic K, V
---@param tbl table<K, table<V, unknown>>
---@param key K
---@param value V
---@return boolean is_empty
local function remove_from_grouped(tbl, key, value)
  local set = tbl[key]
  if set then
    set[value] = nil
    if utils.is_empty(set) then
      tbl[key] = nil
      return true
    end
  end
  return false
end

---@param names string|string[]
---@param enable? boolean
function M.enable(names, enable)
  if type(names) ~= 'table' then names = { names } end
  enable = utils.if_nil(enable, true)

  local added_igniters = {} ---@type table<dotfiles.lsp.Igniter, true>

  for _, name in ipairs(names) do
    if M.enabled_igniters[name] ~= nil then
      local prev_igniter = M.enabled_igniters[name]

      for _, ft in ipairs(prev_igniter.config.filetypes) do
        remove_from_grouped(M.igniters_by_filetype, ft, prev_igniter)
      end

      prev_igniter:stop_client(true)
    end

    M.enabled_igniters[name] = nil

    if enable then
      if lsp.is_enabled ~= nil then
        assert(not lsp.is_enabled(name), 'the config must not be concurrently managed by vim.lsp')
      end

      local config = lsp.config[name] --[[@as dotfiles.lsp.Config|nil]]
      if not config then error(('config not found: %q'):format(name)) end

      local igniter = M.Igniter.new(name, config)
      M.enabled_igniters[name] = igniter

      for _, ft in ipairs(igniter.config.filetypes) do
        get_or_insert(M.igniters_by_filetype, ft, make_weak_table)[igniter] = name
      end

      added_igniters[igniter] = true
    end
  end

  if not utils.is_empty(added_igniters) then
    M.attach_to_all_buffers(function(igniter) return added_igniters[igniter] end)
  end
end

---@param filter? fun(igniter: dotfiles.lsp.Igniter, bufnr: integer): boolean
function M.attach_to_all_buffers(filter)
  local buffers = utils.filter(vim.api.nvim_list_bufs(), vim.api.nvim_buf_is_loaded)

  local curbuf = vim.api.nvim_get_current_buf()
  -- Attach to the current buffer first, so that the `root_dir` is determined
  -- against it, so that I can control the `root_dir` selection.
  if vim.tbl_contains(buffers, curbuf) then M.attach_buffer(curbuf, filter) end

  for _, bufnr in ipairs(buffers) do
    if bufnr ~= curbuf then M.attach_buffer(bufnr, filter) end
  end
end

---@param bufnr integer
---@param filter? fun(igniter: dotfiles.lsp.Igniter, bufnr: integer): boolean
function M.attach_buffer(bufnr, filter)
  if not M.should_attach(bufnr) then return end
  for _, igniter in ipairs(M.get_matching_igniters(bufnr)) do
    if filter == nil or filter(igniter, bufnr) then
      if igniter.autostart and (igniter.config.enabled == nil or igniter.config.enabled(bufnr)) then
        igniter:attach_to_buffer(bufnr)
      end
    end
  end
end

---@param bufnr integer
function M.should_attach(bufnr)
  bufnr = utils.resolve_bufnr(bufnr)
  local bo = vim.bo[bufnr]
  return utils.is_truthy(utils.if_nil(vim.b[bufnr].lsp_enable, true))
    and ((bo.buftype == '' or bo.buftype == 'acwrite') and not bo.binary)
    and vim.uri_from_bufnr(bufnr):match('^file:')
    and utils.get_inmemory_buf_size(bufnr) <= 1000 * 1000 -- 1MB
end

---@param bufnr integer
---@return dotfiles.lsp.Igniter[]
function M.get_matching_igniters(bufnr)
  bufnr = utils.resolve_bufnr(bufnr)
  local list = {}
  -- The 'filetype' option can contain multiple filetypes, separated by dots.
  for ft in vim.gsplit(vim.bo[bufnr].filetype, '%.') do
    for igniter in pairs(M.igniters_by_filetype[ft] or {}) do
      list[#list + 1] = igniter
    end
  end
  return list
end

---@param bufnr integer
---@return dotfiles.lsp.Igniter[]
function M.get_attached_igniters(bufnr)
  bufnr = utils.resolve_bufnr(bufnr)
  return vim.tbl_values(M.clients_by_buffer[bufnr] or {})
end

---@param bufnr integer
function M.detach_buffer(bufnr)
  bufnr = utils.resolve_bufnr(bufnr)
  for _, igniter in pairs(M.clients_by_buffer[bufnr] or {}) do
    igniter:detach_from_buffer(bufnr)
  end
end

---@class dotfiles.lsp.Igniter
local Igniter = M.Igniter or {}
Igniter.__index = Igniter
M.Igniter = Igniter

---@param name string
---@param config dotfiles.lsp.Config
function Igniter.new(name, config)
  ---@class dotfiles.lsp.Igniter
  local self = setmetatable({}, Igniter)
  self.name = name
  self.config = config
  self.client_id = nil ---@type integer?
  self.autostart = true
  self.autostop = true
  self.attaching_buffers = {} ---@type table<integer, true>
  self.deferred_workspace_folder_changes = nil ---@type lsp.WorkspaceFoldersChangeEvent[]|nil
  self.client_exited_listeners = nil ---@type function[]|nil
  return self
end

function Igniter:reset_client_stuff()
  self.client_id = nil
  self.deferred_workspace_folder_changes = nil
  self.client_exited_listeners = nil
end

---@param root_dir string|nil
---@return integer? client_id
function Igniter:launch_client(root_dir)
  if self.client_id ~= nil then return self.client_id end

  local init_completed = self:create_progress_tracker('Starting...')
  self:reset_client_stuff()

  local config = vim.deepcopy(self.config)
  config.handlers = vim.tbl_extend('keep', config.handlers or {}, M.default_handlers)

  local wfs = utils.map(vim.tbl_keys(M.buffers_by_root_dir), M.make_lsp_workspace_folder)
  -- NOTE: This check breaks if the `workspace_folders` list is empty, but not if it is `nil`:
  -- <https://github.com/neovim/neovim/blob/v0.11.3/runtime/lua/vim/lsp/client.lua#L501-L504>.
  config.workspace_folders = #wfs > 0 and wfs or nil
  config.root_dir = root_dir

  local successfully_initialized = false
  local folder_changes = {} ---@type lsp.WorkspaceFoldersChangeEvent[]
  local exit_listeners = {} ---@type function[]

  config.on_init = utils.concat_lists(
    function()
      -- The VERY FIRST thing that must be done is catching up with the folder
      -- changes that occurred while the server was initializing.
      for _, event in ipairs(folder_changes) do
        self:send_workspace_folders_changes(event)
      end
      utils.clear_table(folder_changes)
      self:send_workspace_settings()
    end,

    config.on_init,

    function()
      successfully_initialized = true
      init_completed('Started')
    end
  )

  config.on_exit = utils.concat_lists(config.on_exit, function(code, signal, client_id)
    assert(client_id == self.client_id)
    M.launched_clients[self.client_id] = nil
    self:reset_client_stuff()

    -- Don't auto-restart the client if the server has exited with an error
    -- code. The condition for determining an abnormal exit condition is from:
    -- <https://github.com/neovim/neovim/blob/v0.11.3/runtime/lua/vim/lsp.lua#L236>
    if code ~= 0 or (signal ~= 0 and signal ~= 15) then self.autostart = false end

    -- It might happen that the server crashes while initializing, in which case
    -- `on_init` is not called and we jump straight into `on_exit`.
    if not successfully_initialized then
      vim.schedule(function() init_completed('Failed to start') end)
    end

    for _, exit_listener in ipairs(exit_listeners) do
      exit_listener()
    end
  end)

  if config.on_new_config then
    local ok, err = xpcall(config.on_new_config, debug.traceback, config, root_dir, self)
    if not ok then
      local msg = ('LSP[%s]: Error in on_new_config callback: %s'):format(self.name, err)
      vim.notify(msg, vim.log.levels.ERROR)
    end
  end

  local client_id = lsp.start(config, {
    reuse_client = function() return false end,
    attach = false,
    silent = false,
  })

  -- `lsp.start()` may return `nil` if, for instance, the server executable does
  -- not exist. None of the callbacks (like `on_init`, `on_exit` etc) will be
  -- invoked then.
  if client_id == nil then
    self.autostart = false
    init_completed('Failed to start')
    return nil
  end

  -- HACK: reset the `settings` table of the client to prevent this code from being executed:
  -- <https://github.com/neovim/neovim/blob/v0.11.3/runtime/lua/vim/lsp/client.lua#L562-L564>
  lsp.get_client_by_id(client_id).settings = {}

  self.client_id = client_id
  self.deferred_workspace_folder_changes = folder_changes
  self.client_exited_listeners = exit_listeners
  M.launched_clients[client_id] = self
  return client_id
end

---@return vim.lsp.Client|nil
function Igniter:get_client() return lsp.get_client_by_id(self.client_id) end

---@param event lsp.WorkspaceFoldersChangeEvent
function Igniter:send_workspace_folders_changes(event)
  local client = assert(self:get_client(), 'the client must be running')
  if not client.initialized then
    table.insert(self.deferred_workspace_folder_changes, event)
    return
  end

  client.workspace_folders = client.workspace_folders or {}

  for _, folder in ipairs(event.added) do
    if not utils.find(client.workspace_folders, function(w) return w.uri == folder.uri end) then
      table.insert(client.workspace_folders, folder)
    end
  end

  for _, folder in ipairs(event.removed) do
    utils.remove_all(client.workspace_folders, function(w) return w.uri == folder.uri end)
  end

  ---@type lsp.DidChangeWorkspaceFoldersParams
  local params = { event = event }
  client:notify('workspace/didChangeWorkspaceFolders', params)
end

---@param scope_uri string|nil
---@param trigger 'workspace'|'server_request'
function Igniter:resolve_settings(scope_uri, trigger)
  local client = self:get_client()

  local NeoconfSettings = require('neoconf.settings')
  local NeoconfWorkspace = require('neoconf.workspace')

  local workspace_root = (scope_uri and scope_uri:match('^file:')) and vim.uri_to_fname(scope_uri)
    or (client and client.root_dir or nil)
  workspace_root = workspace_root and NeoconfWorkspace.find_root({ file = workspace_root })

  local global_settings = NeoconfSettings.get_global()
  local local_settings = workspace_root and NeoconfSettings.get_local(workspace_root)
    or NeoconfSettings.new() -- create an empty object if the workspace root wasn't found

  ---@alias dotfiles.lsp.SettingsBuildStep
  ---| 'lspconfig'
  ---| 'generated'
  ---| 'neoconf_local'
  ---| 'neoconf_global'
  ---| 'coc_global'
  ---| 'coc_local'
  ---| 'nlsp_local'
  ---| 'nlsp_global'
  ---| 'vscode_local'

  ---@class dotfiles.lsp.SettingsContext
  local ctx = {
    settings = Settings.new(),
    new_settings = Settings.new(),
    step = nil, ---@type dotfiles.lsp.SettingsBuildStep
    trigger = trigger,
    scope_uri = scope_uri,
    client = client,
    igniter = self,
  }

  local lsp_config = client and client.config --[[@as dotfiles.lsp.Config]]
    or self.config

  ---@param name dotfiles.lsp.SettingsBuildStep
  local function step(name, data)
    ctx.step = name
    ctx.new_settings = Settings.new(data)

    local build_settings = lsp_config.build_settings
    if type(build_settings) == 'function' then
      build_settings(ctx)
    elseif type(data) == 'table' then
      ctx.settings:merge(data) -- the default settings resolution behavior
    end
  end

  local options = require('neoconf.config').get({ file = workspace_root })
  -- The settings resolution order matches the one of neoconf.nvim:
  -- <https://github.com/folke/neoconf.nvim/blob/b516f1ca1943de917e476224e7aa6b9151961991/lua/neoconf/plugins/lspconfig.lua#L53-L64>.
  step('lspconfig', lsp_config.settings)
  step('neoconf_local', global_settings:get('lspconfig.' .. self.name, { expand = true }))
  if options.import.coc then step('coc_global', global_settings:get('coc')) end
  if options.import.nlsp then step('nlsp_global', global_settings:get('nlsp.' .. self.name)) end
  if options.import.vscode then step('vscode_local', local_settings:get('vscode')) end
  if options.import.coc then step('coc_local', local_settings:get('coc')) end
  if options.import.nlsp then step('nlsp_local', local_settings:get('nlsp.' .. self.name)) end
  step('neoconf_local', local_settings:get('lspconfig.' .. self.name, { expand = true }))
  -- The step for generating settings comes last to give the user a chance to
  -- modify any previously merged settings or provide default fallbacks.
  step('generated', nil)

  return ctx.settings
end

function Igniter:send_workspace_settings()
  local client = assert(self:get_client(), 'the client must be running')

  local settings = self:resolve_settings(nil, 'workspace'):get()
  if type(settings) ~= 'table' or utils.is_empty(settings) then settings = vim.empty_dict() end

  if not vim.deep_equal(client.settings, settings) then
    client.settings = settings
    client:notify('workspace/didChangeConfiguration', { settings = settings })
    return true
  else
    return false
  end
end

local DEBUG_SETTINGS_REQUESTS = false

---@param params lsp.ConfigurationParams
M.default_handlers['workspace/configuration'] = function(err, params, ctx)
  if err then
    lsp.log.error(module.name, ctx.method, err)
    lsp_extras.client_notify(ctx.client_id, tostring(err), vim.log.levels.ERROR)
    return
  end

  local client = lsp.get_client_by_id(ctx.client_id)
  if not client then
    local msg = 'client has shut down after sending a ' .. ctx.method .. ' request'
    lsp_extras.client_notify(ctx.client_id, msg, vim.log.levels.ERROR)
    return
  end

  -- It's common for servers to request multiple different sections for the same
  -- URI scope within one request, so a cache is useful to prevent the redundant
  -- work of repeatedly resolving the whole settings table for the same URI.
  -- `vim.NIL` is used as a key for when no `scopeUri` is provided.
  ---@type table<string|vim.NIL, dotfiles.lsp.Settings>
  local settings_per_uri = {
    -- [vim.NIL] = Settings.new(client.settings),
  }

  if DEBUG_SETTINGS_REQUESTS then
    local sections_by_scope = {}
    for _, item in ipairs(params.items) do
      local list = get_or_insert(sections_by_scope, item.scopeUri or vim.NIL, make_table)
      table.insert(list, item.section or vim.NIL)
    end
    dump_compact(client.name, sections_by_scope)
  end

  return utils.map(params.items, function(item)
    local settings = get_or_insert(settings_per_uri, item.scopeUri or vim.NIL, function()
      local igniter = assert(M.launched_clients[client.id])
      return igniter:resolve_settings(item.scopeUri, 'server_request')
    end)
    return settings:get(item.section, vim.NIL)
  end)
end

---@async
---@param bufnr integer
---@param config dotfiles.lsp.Config
---@return string?
local function resolve_root_dir(bufnr, config)
  local root_dir = config.root_dir
  if type(root_dir) == 'string' then
    return root_dir
  elseif type(root_dir) == 'function' then
    return utils.await(function(cb) root_dir(bufnr, cb) end)
  elseif config.root_markers then
    -- The root resolution logic is roughly based on coc.nvim

    local cwd = utils.normalize_path(vim.fn.getcwd())
    local buf_name = vim.fs.abspath(vim.api.nvim_buf_get_name(bufnr))
    local buf_path = utils.normalize_path(buf_name)

    local parents = {} ---@type string[]
    for path in vim.fs.parents(buf_path) do
      parents[#parents + 1] = path
    end

    ---@param dir string
    ---@param marker dotfiles.lsp.RootMarker
    ---@return boolean
    local function check_dir(dir, marker)
      if type(marker) == 'function' then
        for name in vim.fs.dir(dir) do
          if marker(name, dir) then return true end
        end
      else
        if type(marker) == 'string' then marker = { marker } end
        for _, name in ipairs(marker) do
          if vim.uv.fs_stat(vim.fs.joinpath(dir, name)) ~= nil then return true end
        end
      end
      return false
    end

    local buf_is_inside_cwd = vim.tbl_contains(parents, cwd)
    for _, marker in ipairs(config.root_markers) do
      -- Check the working directory first for the presence of the marker, as
      -- the editor will usually be already opened within the project root.
      if buf_is_inside_cwd and check_dir(cwd, marker) then return cwd end
      -- Unlike the default behavior `vim.lsp`, I search for root markers from
      -- the outermost to the innermost directory, which is what coc.nvim does.
      -- This has worked fine for ages under coc.nvim, and hopefully will
      -- produce better results in projects with complex layouts and nested
      -- workspaces than the bottom-up searching process of `vim.fs.root`.
      for i = #parents, 1, -1 do
        local dir = parents[i]
        if dir ~= cwd and check_dir(dir, marker) then return dir end
      end
    end
  end

  return nil
end

---@param bufnr integer
function Igniter:attach_to_buffer(bufnr)
  bufnr = utils.resolve_bufnr(bufnr)
  self.attaching_buffers[bufnr] = true

  utils.run_async(function()
    local root_dir = resolve_root_dir(bufnr, self.config)

    local prev_client_id = self.client_id
    if prev_client_id ~= nil then
      -- What this really checks is whether the client is currently in the
      -- process of stopping. Because once the client has actually stopped it is
      -- removed from the table of all clients, we can know for sure that if it
      -- is still accessible through `lsp.get_client_by_id()` and `is_stopped()`
      -- returns `true`, then it was requested to stop, but has not yet exited.
      -- In which case we wait for it to stop completely, so that a brand new
      -- client can be started in its place.
      if lsp.get_client_by_id(prev_client_id):is_stopped() then
        utils.await(function(cb) table.insert(self.client_exited_listeners, cb) end)
      end
    end

    -- I initially added this to make the session loading work, but it is
    -- important that the client is always started asynchronously -- this has
    -- helped me catch some bugs that I wouldn't otherwise see.
    utils.await(vim.schedule)

    self.attaching_buffers[bufnr] = nil

    -- Exit if the buffer got deleted/unloaded while we were determining the root dir.
    if not vim.api.nvim_buf_is_loaded(bufnr) then return end

    if root_dir then M.add_workspace_folder_of_buffer(root_dir, bufnr) end

    local client_id = self:launch_client(root_dir)
    if client_id then lsp.buf_attach_client(bufnr, client_id) end
  end)
end

---@param bufnr integer
function Igniter:detach_from_buffer(bufnr)
  if self.client_id ~= nil then lsp.buf_detach_client(bufnr, self.client_id) end
end

---@param force? boolean
---@param callback? fun()
function Igniter:stop_client(force, callback)
  -- LuaLS is uncooperative for some reason and I cannot figure out why
  if self.name == 'lua_ls' then force = true end

  if self.client_id == nil then
    if callback then callback() end
  else
    local stop_completed = self:create_progress_tracker('Stopping...')
    table.insert(self.client_exited_listeners, function()
      vim.schedule(function() stop_completed('Stopped') end)
      -- The `on_exit` handlers are invoked in a fast context, so a `schedule()`
      -- is necessary. It will also isolate any errors thrown by the `callback`.
      if callback then vim.schedule(callback) end
    end)

    lsp.stop_client(self.client_id, force)
  end
end

---@param message string
---@return fun(message: string) done_callback
function Igniter:create_progress_tracker(message)
  local has_fidget, fidget = pcall(require, 'fidget')
  if has_fidget then
    local handle = fidget.progress.handle.create({
      lsp_client = { name = 'lsp_ignition' },
      title = self.name,
      message = message,
      cancellable = false,
      done = false,
    })
    return function(done_message)
      handle:report({ done = true, message = done_message })
      handle = nil ---@diagnostic disable-line: cast-local-type
    end
  else
    return function() end
  end
end

---@param root_dir string
function M.make_lsp_workspace_folder(root_dir)
  ---@type lsp.WorkspaceFolder
  return {
    uri = vim.uri_from_fname(root_dir),
    -- Put the full path instead of just the basename/tail into the name of the
    -- folder because `:checkhealth vim.lsp` displays only the name and not the
    -- URI, and it's more informative to be able to see the full path.
    name = root_dir,
  }
end

---@param path string
function M.add_workspace_folder_of_buffer(path, bufnr)
  if vim.fn.isabsolutepath(path) == 0 then
    local msg = ('the workspace folder path must be an absolute path, got %q instead'):format(path)
    vim.notify(module.name .. ': ' .. msg, vim.log.levels.WARN)
    return
  end

  bufnr = utils.resolve_bufnr(bufnr)

  local is_new_folder = M.buffers_by_root_dir[path] == nil
  get_or_insert(M.buffers_by_root_dir, path, make_table)[bufnr] = vim.api.nvim_buf_get_name(bufnr)

  if is_new_folder then
    for _, igniter in pairs(M.launched_clients) do
      local folder = M.make_lsp_workspace_folder(path)
      igniter:send_workspace_folders_changes({ added = { folder }, removed = {} })
    end
  end
end

---@param path string
function M.remove_workspace_folder_of_buffer(path, bufnr)
  bufnr = utils.resolve_bufnr(bufnr)

  local should_remove = remove_from_grouped(M.buffers_by_root_dir, path, bufnr)
  if should_remove then
    for _, igniter in pairs(M.launched_clients) do
      local folder = M.make_lsp_workspace_folder(path)
      igniter:send_workspace_folders_changes({ added = {}, removed = { folder } })
    end
  end
end

---@class dotfiles.lsp.ExportedWorkspace
---@field version 1
---@field folders table<string, table<string, integer>>

---@return dotfiles.lsp.ExportedWorkspace
function M.export_workspace()
  ---@type dotfiles.lsp.ExportedWorkspace
  local json = { version = 1, folders = {} }
  for dir_path, dir_buffers in pairs(M.buffers_by_root_dir) do
    local folder_json = {}

    for bufnr in pairs(dir_buffers) do
      local name = vim.api.nvim_buf_get_name(bufnr)
      local is_shortened = 0
      if vim.startswith(name, dir_path) then
        name = name:sub(#dir_path + 1, -1)
        is_shortened = 1
      end
      folder_json[name] = is_shortened
    end

    json.folders[dir_path] = folder_json
  end
  return json
end

---@param json dotfiles.lsp.ExportedWorkspace
function M.import_workspace(json)
  if type(json) == 'table' and json.version == 1 and type(json.folders) == 'table' then
    local existing_buffers_lookup = {}
    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
      local name = vim.api.nvim_buf_get_name(bufnr)
      if name ~= '' then existing_buffers_lookup[name] = bufnr end
    end

    for dir_path, dir_buffers in pairs(json.folders) do
      for buf_name, is_shortened in pairs(dir_buffers) do
        if is_shortened == 1 then buf_name = dir_path .. buf_name end
        local bufnr = existing_buffers_lookup[buf_name]
        if bufnr ~= nil then M.add_workspace_folder_of_buffer(dir_path, bufnr) end
      end
    end
  end
end

local augroup = utils.augroup(module.name)

augroup:autocmd('FileType', function(event)
  M.detach_buffer(event.buf)
  M.attach_buffer(event.buf)
end)

augroup:autocmd('BufFilePre', function(event)
  M.detach_buffer(event.buf) -- detach from a buffer before it gets renamed
end)

augroup:autocmd('BufFilePost', function(event)
  M.attach_buffer(event.buf) -- re-attach to a buffer after it was renamed
end)

augroup:autocmd('LspAttach', function(event)
  local igniter = M.launched_clients[event.data.client_id]
  if igniter ~= nil then
    get_or_insert(M.clients_by_buffer, event.buf, make_table)[event.data.client_id] = igniter
  end
end)

augroup:autocmd('LspDetach', function(event)
  local no_clients_attached_to_buf =
    remove_from_grouped(M.clients_by_buffer, event.buf, event.data.client_id)
  if no_clients_attached_to_buf then
    for dir_path, dir_buffers in pairs(M.buffers_by_root_dir) do
      if dir_buffers[event.buf] ~= nil then
        M.remove_workspace_folder_of_buffer(dir_path, event.buf)
      end
    end
  end
end)

function M.stop_inactive_clients()
  for client_id, igniter in pairs(M.launched_clients) do
    if
      igniter.autostop
      and utils.is_empty(lsp.get_buffers_by_client_id(client_id))
      and utils.is_empty(igniter.attaching_buffers)
    then
      igniter:stop_client(false)
    end
  end
end

augroup:autocmd('LspDetach', utils.schedule_once_per_tick(M.stop_inactive_clients))

local SESSION_VAR_NAME = 'dotfiles_lsp_ignition_workspace'

augroup:autocmd('User', 'ObsessionPre', function()
  local json = vim.json.encode(M.export_workspace())
  vim.g.obsession_append = { 'let g:' .. SESSION_VAR_NAME .. ' = ' .. json }
end)

augroup:autocmd('User', 'Obsession', function() vim.g.obsession_append = nil end)

-- augroup:autocmd('SessionWritePost', '*', function() end)

augroup:autocmd('SessionLoadPost', function()
  local data = vim.g[SESSION_VAR_NAME]
  if data ~= nil then
    vim.g[SESSION_VAR_NAME] = nil
    M.import_workspace(data)
  end
end)

---@param cmd vim.api.keyset.create_user_command.command_args
local function parse_igniters_list(cmd)
  if utils.is_empty(cmd.fargs) then return nil end
  local results = {} ---@type dotfiles.lsp.Igniter[]
  for _, arg in ipairs(cmd.fargs) do
    local igniter = M.enabled_igniters[arg]
    if igniter then
      results[#results + 1] = igniter
    else
      vim.notify(('%s: config not found: %q'):format(cmd.name, arg), vim.log.levels.ERROR)
    end
  end
  return results
end

---@param list table<unknown, dotfiles.lsp.Igniter> | (fun(): table<unknown, dotfiles.lsp.Igniter>)
local function complete_config_names(list)
  return utils.command_completion_fn(function()
    local names = {}
    for _, igniter in pairs(type(list) ~= 'function' and list or list()) do
      names[#names + 1] = igniter.name
    end
    return names
  end)
end

vim.api.nvim_create_user_command('LspStart', function(cmd)
  for _, igniter in ipairs(parse_igniters_list(cmd) or M.get_matching_igniters(0)) do
    igniter.autostart = true
    M.attach_to_all_buffers(function(other) return other == igniter end)
  end
end, { bar = true, nargs = '*', complete = complete_config_names(M.enabled_igniters) })

vim.api.nvim_create_user_command('LspRestart', function(cmd)
  for _, igniter in ipairs(parse_igniters_list(cmd) or M.get_matching_igniters(0)) do
    igniter.autostart = false
    igniter:stop_client(cmd.bang, function()
      igniter.autostart = true
      M.attach_to_all_buffers(function(other) return other == igniter end)
    end)
  end
end, { bar = true, nargs = '*', complete = complete_config_names(M.enabled_igniters), bang = true })

vim.api.nvim_create_user_command('LspStop', function(cmd)
  for _, igniter in ipairs(parse_igniters_list(cmd) or vim.tbl_values(M.launched_clients)) do
    igniter.autostart = false
    igniter:stop_client(cmd.bang)
  end
end, { bar = true, nargs = '*', complete = complete_config_names(M.launched_clients), bang = true })

vim.api.nvim_create_user_command('LspAttach', function(cmd)
  local bufnr = vim.api.nvim_get_current_buf()
  for _, igniter in ipairs(parse_igniters_list(cmd) or M.get_matching_igniters(bufnr)) do
    igniter:attach_to_buffer(bufnr)
  end
end, { bar = true, nargs = '*', complete = complete_config_names(M.get_matching_igniters) })

vim.api.nvim_create_user_command('LspDetach', function(cmd)
  local bufnr = vim.api.nvim_get_current_buf()
  for _, igniter in ipairs(parse_igniters_list(cmd) or M.get_attached_igniters(bufnr)) do
    igniter:detach_from_buffer(bufnr)
  end
end, { bar = true, nargs = '*', complete = complete_config_names(M.get_attached_igniters) })

function M.get_all_config_names()
  return utils.map(vim.api.nvim_get_runtime_file('lsp/*.lua', true), function(path)
    -- This pattern *should* always match and extract the basename of the file,
    -- but in case it doesn't, raise an error with the offending path in the
    -- message. Also, I love how handy the `assert()` function is in Lua!
    return assert(path:match('([^/]*)%.lua$'), path)
  end)
end

vim.api.nvim_create_user_command('LspEnable', function(cmd) --
  M.enable(cmd.args, true)
end, { bar = true, nargs = '+', complete = utils.command_completion_fn(M.get_all_config_names) })

vim.api.nvim_create_user_command('LspDisable', function(cmd) --
  M.enable(cmd.args, false)
end, { bar = true, nargs = '+', complete = complete_config_names(M.enabled_igniters) })

vim.api.nvim_create_user_command('LspReload', function(cmd) --
  M.enable(cmd.args, false)
  M.enable(cmd.args, true)
end, { bar = true, nargs = '+', complete = complete_config_names(M.enabled_igniters) })

vim.api.nvim_create_user_command('LspWorkspace', function()
  local out = {}
  for dir_path, dir_buffers in pairs(M.buffers_by_root_dir) do
    out[#out + 1] = ('Folder %q, with buffers:'):format(vim.fn.fnamemodify(dir_path, ':~'))
    for bufnr in pairs(dir_buffers) do
      local path = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ':~')
      out[#out + 1] = ('%6d %q'):format(bufnr, path)
    end
    out[#out + 1] = ''
  end
  vim.api.nvim_echo({ { table.concat(out, '\n') } }, --[[ history ]] false, {})
end, { bar = true })

---@type SettingsPlugin
M.neoconf_plugin = M.neoconf_plugin or {}
M.neoconf_plugin.name = module.name

--- See <https://github.com/folke/neoconf.nvim/blob/b516f1ca1943de917e476224e7aa6b9151961991/lua/neoconf/plugins/lspconfig.lua#L8>.
---@param schema Schema
function M.neoconf_plugin.on_schema(schema)
  local options = require('neoconf.config').options
  schema:set('lspconfig', { description = 'lsp server settings for ' .. module.name })
  for name, server_schema in pairs(require('neoconf.build.schemas').get_schemas()) do
    if options.plugins.jsonls.configured_servers_only == false or M.enabled_igniters[name] then
      schema:set('lspconfig.' .. name, {
        ['$ref'] = vim.uri_from_fname(server_schema.settings_file),
      })
    end
  end
end

---@param _changed_settings_file string
function M.neoconf_plugin.on_update(_changed_settings_file)
  local affected_clients = {} ---@type string[]

  for _, igniter in pairs(M.launched_clients) do
    if igniter:send_workspace_settings() then table.insert(affected_clients, igniter.name) end
  end

  if #affected_clients > 0 then
    local msg = module.name .. ': reloaded settings for ' .. table.concat(affected_clients, ', ')
    vim.notify(msg, vim.log.levels.INFO)
  end
end

return M
