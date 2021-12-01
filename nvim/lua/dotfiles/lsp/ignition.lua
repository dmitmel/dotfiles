--- ==================== LSP IGNITION ====================
---
--- The new and revised Language Server activation and attachment system.
--- Heavily based (and maintains compatibility with) on the original
--- nvim-lspconfig implementation:
--- <https://github.com/neovim/nvim-lspconfig/blob/4f72377143fc0961391fb0e42e751b9f677fca4e/lua/lspconfig/configs.lua>
--- <https://github.com/neovim/nvim-lspconfig/blob/4f72377143fc0961391fb0e42e751b9f677fca4e/lua/lspconfig/util.lua#L210-L268>
--- <https://github.com/neovim/nvim-lspconfig/blob/4f72377143fc0961391fb0e42e751b9f677fca4e/lua/lspconfig.lua>
--- <https://github.com/neovim/nvim-lspconfig/blob/4f72377143fc0961391fb0e42e751b9f677fca4e/lua/lspconfig/lspinfo.lua>
---
--- NOTE: Clients are essentially shared across all workspaces, and workspace
--- folder lists are synchronized between all clients. This is what coc.nvim
--- does, and, most likely, so does VSCode. Which means that I triumphantly
--- proclaim this ticket closed:
--- <https://github.com/neovim/nvim-lspconfig/issues/842>
local M = require('dotfiles.autoload')('dotfiles.lsp.ignition')

-- TODO: get rid of presets altogether, add a function like `setup_config_from_lspconfig`

-- TODO: figure out autocommands for attachment
-- TODO: more error messages
-- TODO: add logging
-- TODO: A middleware system with blackjack and next() ?
-- TODO: use weak maps?

-- TODO: <https://github.com/neovim/nvim-lspconfig/pull/652>
-- TODO: <https://www.reddit.com/r/neovim/comments/pi1nw3/how_do_i_set_up_sumnekolua_in_neovim_so_it_doesnt/hbmtah8?context=3>
-- TODO: <https://github.com/mjlbach/nvim-lspconfig/commit/f0cafe843c03214b9b3c5c2660f10eb92db4de22>
-- TODO: <https://github.com/neovim/nvim-lspconfig/pull/1174>
-- TODO: <https://github.com/neovim/nvim-lspconfig/pulls?q=is%3Apr+author%3Amjlbach+is%3Aclosed>

local lsp = require('vim.lsp')
local utils = require('dotfiles.utils')
local utils_vim = require('dotfiles.utils.vim')
local lsp_utils = require('dotfiles.lsp.utils')
local lsp_global_settings = require('dotfiles.lsp.global_settings')
local vim_uri = require('vim.uri')


-- <https://github.com/neovim/neovim/pull/15430>
-- <https://github.com/neovim/neovim/pull/15132>
local CAN_USE_NIL_ROOT_DIR = utils_vim.has('nvim-0.5.1')

M.default_config = {
  log_level = lsp.protocol.MessageType.Warning,
  message_level = lsp.protocol.MessageType.Warning,
  settings = vim.empty_dict(),
  init_options = vim.empty_dict(),
  handlers = vim.empty_dict(),
  autostart = true,
  capabilities = lsp.protocol.make_client_capabilities(),
}
local compat_default_config_ref = function() vim.empty_dict() end

M.config_presets_registry = {}
M.configs_registry = {}
-- The layout of these maps may look weird, and it is, but that's because they
-- are optimized for usage in the most frequent case, i.e. attaching a server
-- to newly opened buffers. It doesn't matter if I have to perform a linear
-- lookup in :LspStop or similar to find all clients with a matching ID because
-- the command will be run relatively rarely, however, when attaching, direct
-- table lookups are critical.
M.filetypes_to_configs_map = {}
-- TODO: Store references to clients instead of client IDs.
M.configs_to_client_ids_map = {}
M.workspace_root_dirs = {}

-- For integration of other subsystems.
M.service_hooks = {
  before_config_installed = {};
  on_config_installed = {};
  before_config_uninstalled = {};
  on_config_uninstalled = {};
  before_init = {};
  on_create = {};
  on_init = {};
  on_attach = {};
  on_exit = {};
  on_new_config = {};
}

-- Give the clients some time to stop. nvim-lspconfig uses 500ms timeout.
M._CLIENT_RESTART_TIMEOUT = 1000


-- TODO: Contribute the following to upstream.
-- <https://github.com/neovim/neovim/blob/v0.5.0/runtime/lua/vim/lsp.lua#L747>
-- <https://github.com/neovim/neovim/blob/v0.5.0/runtime/lua/vim/lsp.lua#L824-L825>
-- <https://github.com/neovim/neovim/blob/v0.5.0/runtime/lua/vim/lsp.lua#L1016-L1017>
do
  local maxn = table.maxn(lsp.client_errors)
  lsp.client_errors = vim.tbl_extend('keep', lsp.client_errors, vim.tbl_add_reverse_lookup {
    BEFORE_INIT_CALLBACK_ERROR   = maxn + 1,
    ON_CREATE_CALLBACK_ERROR     = maxn + 2,  -- My invention
    ON_INIT_CALLBACK_ERROR       = maxn + 3,
    ON_ATTACH_CALLBACK_ERROR     = maxn + 4,
    ON_EXIT_CALLBACK_ERROR       = maxn + 5,
    ON_NEW_CONFIG_CALLBACK_ERROR = maxn + 6,  -- Not really a built-in callback, isn't it?
  })
end


-- These are, quite frankly, terrible APIs in their current form, but can be
-- easily emulated with my functions.
do
  function lsp.buf.add_workspace_folder(workspace_folder)
    vim.validate({
      workspace_folder = {workspace_folder, 'string'};
    })
    M.broadcast_workspace_root_dirs_change({ [workspace_folder] = true })
  end
  function lsp.buf.remove_workspace_folder(workspace_folder)
    vim.validate({
      workspace_folder = {workspace_folder, 'string'};
    })
    M.broadcast_workspace_root_dirs_change({ [workspace_folder] = false })
  end
  function lsp.buf.list_workspace_folders()
    return vim.tbl_keys(M.workspace_root_dirs)
  end
end


function M.setup()
  vim.cmd([[
    augroup dotfiles_lsp_ignition
      autocmd!
      autocmd FileType * unsilent lua require('dotfiles.lsp.ignition').on_buf_created(tonumber(vim.fn.expand('<abuf>')))
    augroup END
  ]])

  dotfiles._lsp_ignition_command_completion = {
    LspStart = M.command_start_completion,
    LspStop = M.command_stop_completion,
    LspRestart = M.command_restart_completion,
  }
  utils_vim.define_command('LspInfo', {
    handler = M.command_info,
  })
  utils_vim.define_command('LspStart', {
    handler = M.command_start,
    complete = 'custom,v:lua.dotfiles._lsp_ignition_command_completion.LspStart',
    nargs = '*',
  })
  utils_vim.define_command('LspStop', {
    handler = M.command_stop,
    complete = 'custom,v:lua.dotfiles._lsp_ignition_command_completion.LspStop',
    nargs = '*',
    bang = true,
  })
  utils_vim.define_command('LspRestart', {
    handler = M.command_restart,
    complete = 'custom,v:lua.dotfiles._lsp_ignition_command_completion.LspRestart',
    nargs = '*',
    bang = true,
  })
end


function M.install_compat()
  package.loaded['lspconfig/configs'] = M._loaded_config_presets_compat
  package.loaded['lspconfig.configs'] = M._loaded_config_presets_compat
  local ok, lspconfig = pcall(require, 'lspconfig')
  assert(ok, 'nvim-lspconfig is not installed, the compat layer is not necessary!')
  lspconfig.util.create_module_commands = function() end
  compat_default_config_ref = function() return lspconfig.util.default_config end
end


M._loaded_config_presets_compat = setmetatable({}, {
  __newindex = function(self, config_name, config_def)
    assert(self == M._loaded_config_presets_compat)
    for k, _ in pairs(config_def) do
      if k ~= 'default_config' and k ~= 'on_new_config' and k ~= 'commands' and k ~= 'docs' then
        vim.notify(
          string.format(
            'warning: encountered an unknown key %q in a config preset %q received from ' ..
            'nvim-lspconfig, the compat layer needs updating', k, config_name
          ),
          vim.log.levels.WARN
        )
      end
    end
    return M.setup_config_preset(config_name, config_def)
  end
})


function M._validate_config_name(config_name)
  if not config_name:match('^[a-zA-Z0-9_-]+$') then
    error(
      string.format(
        'invalid config name %q, it may consist only of letters, digits, underscores and dashes',
        config_name
      )
    )
  end
end


function M.get_config_preset(config_name)
  return M.config_presets_registry[config_name]
end


function M.setup_config_preset(config_name, config_def)
  vim.validate({
    config_name = { config_name, 'string' };
    config_def = { config_def, 'table' };
    default_config = { config_def.default_config, 'table' };
    on_new_config = { config_def.on_new_config, 'function', true };
    commands = { config_def.commands, 'table', true };
  })
  M._validate_config_name(config_name)

  M.delete_config_preset(config_name)

  local config_preset = {
    name = config_name;
    default_config = config_def.default_config;
    on_new_config = config_def.on_new_config;
    commands = config_def.commands;
  }
  M.config_presets_registry[config_name] = config_preset

  local compat_ghost = M._setup_config_compat_ghost(config_name)
  -- Used by their documentation generator, but still is useful for reading the
  -- values of the default config (for adding stuff to lists, for instance)
  -- because it isn't otherwise publicly available.
  compat_ghost.document_config = config_def

  return config_preset
end


function M.delete_config_preset(config_name)
  vim.validate({
    config_name = { config_name, 'string' };
  })
  -- Deleting config presets actually has much less consequences than deleting
  -- configs themselves, but still be careful.

  local config_preset = M.config_presets_registry[config_name]
  if config_preset == nil then
    -- Wasn't registered in the first place.
    return config_preset
  end

  M.config_presets_registry[config_name] = nil
  M._delete_config_compat_ghost(config_name)

  return config_preset
end


function M._setup_config_compat_ghost(config_name)
  if rawget(M._loaded_config_presets_compat, config_name) ~= nil then
    error(string.format('a config compat ghost with the name %q already exists', config_name))
  end

  local compat_ghost = {
    name = config_name;
    -- Public API.
    setup = function(config_def2)
      M.setup_config(config_name, config_def2)
    end;
    -- Used in :LspInfo
    make_config = function(root_dir)
      local config = M.configs_registry[config_name]
      if not config then return end
      return M.make_final_client_config_for_buf(config, root_dir)
    end
  }
  rawset(M._loaded_config_presets_compat, config_name, compat_ghost)
  return compat_ghost
end


function M._delete_config_compat_ghost(config_name)
  rawset(M._loaded_config_presets_compat, config_name, nil)
end


function M.get_config(config_name)
  return M.configs_registry[config_name]
end


function M.setup_config(config_name, config_def)
  vim.validate({
    config_name = { config_name, 'string' };
    config_def = { config_def, 'table' };
  -- TODO: more typechecks
  })
  M._validate_config_name(config_name)

  local prev_config = M.configs_registry[config_name]
  local prev_client_id = nil
  local prev_client_root_dir = nil
  local prev_attached_buffers = nil
  if prev_config ~= nil then
    prev_client_id = M.configs_to_client_ids_map[prev_config]
    if prev_client_id then
      local client = lsp.get_client_by_id(prev_client_id)
      prev_client_root_dir = client.config.root_dir_real
      prev_attached_buffers = vim.list_slice(lsp.get_buffers_by_client_id(prev_client_id))
    end
    M.delete_config(config_name)
  end
  prev_config = nil

  local config_preset = M.config_presets_registry[config_name]
  local config_preset_config = nil
  if not config_def.ignore_preset and config_preset ~= nil then
    config_preset_config = config_preset.default_config
  else
    config_preset_config = vim.empty_dict()
  end

  local compat_default_config = compat_default_config_ref()
  local config = vim.tbl_deep_extend(
    'force',
    -- The configs will be merged in the order they are written down here, in
    -- other words, with increasing priority.
    compat_default_config, M.default_config, config_preset_config, config_def
  )
  config.name = config_name

  for _, fn in ipairs(M.service_hooks.before_config_installed) do
    fn(config)
  end

  M.configs_registry[config_name] = config

  for _, filetype in ipairs(config.filetypes or {}) do
    local ft_configs_set = M.filetypes_to_configs_map[filetype]
    if ft_configs_set == nil then
      ft_configs_set = {}
      M.filetypes_to_configs_map[filetype] = ft_configs_set
    end

    assert(ft_configs_set[config] == nil)
    ft_configs_set[config] = true
  end

  config.ignition_commands = config.ignition_commands or {}
  for command_name, command_def in pairs(config.ignition_commands) do
    local orig_handler = command_def.handler
    command_def.handler = function(call_info, ...)
      local client_id = M.configs_to_client_ids_map[config]
      local bufnr = vim.api.nvim_get_current_buf()
      local buf_clients = lsp.buf_get_clients(bufnr)
      if client_id then
        local client = buf_clients[client_id]
        if client then
          return orig_handler(call_info, client, bufnr, ...)
        end
      end
      local buf_client_names = vim.tbl_map(function(client)
        return string.format('%q', client.name)
      end, buf_clients)
      vim.notify(
        string.format(
          '%s.%s: This command may only be executed in buffers to which the client %q is ' ..
          'attached. Clients attached to the current buffer are: %s.',
          config_name, command_name, config_name, table.concat(buf_client_names, ', ')
        ),
        vim.log.levels.ERROR
      )
    end
    utils_vim.define_command(command_name, command_def)
  end

  local compat_ghost = rawget(M._loaded_config_presets_compat, config_name)
  if compat_ghost == nil then
    -- In case the config was created through the use of our public API.
    compat_ghost = M._setup_config_compat_ghost(config_name)
  else
    -- Otherwise reuse the existing table to not break references.
    assert(compat_ghost.name == config_name)
  end
  -- These are used by :LspInfo from nvim-lspconfig.
  compat_ghost.get_root_dir = config.root_dir
  compat_ghost.filetypes = config.filetypes
  compat_ghost.handlers = config.handlers
  compat_ghost.cmd = config.cmd
  -- <https://github.com/neovim/nvim-lspconfig/commit/c7ef8b9cf448173520953e8c4f311a376a5f5bd9>
  compat_ghost._autostart = config.autostart and config.enabled

  -- Restart a previous client instance if it was active.
  if prev_client_id then
    utils.set_timeout(M._CLIENT_RESTART_TIMEOUT, function()
      local client_id = M.ensure_client_started_for_config(config, prev_client_root_dir)
      for _, bufnr in ipairs(prev_attached_buffers) do
        if vim.api.nvim_buf_is_valid(bufnr) then
          M.ensure_client_attached_to_buf(config, client_id, bufnr)
        end
      end
    end)
  end

  for _, fn in ipairs(M.service_hooks.on_config_installed) do
    fn(config)
  end
end


function M.delete_config(config_name)
  vim.validate({
    config_name = { config_name, 'string' };
  })
  -- Config uninstallation is a responsible task, be vigilant.

  local config = M.configs_registry[config_name]
  if config == nil then
    -- The config is assumed to not have been registered in the first place.
    return config
  end

  for _, fn in ipairs(M.service_hooks.before_config_uninstalled) do
    fn(config)
  end

  local client_id = M.configs_to_client_ids_map[config]
  if client_id then
    local client = lsp.get_client_by_id(client_id)
    client.stop()
  end

  M.configs_registry[config_name] = nil

  for _, filetype in ipairs(config.filetypes or {}) do
    local ft_configs_set = M.filetypes_to_configs_map[filetype]
    assert(ft_configs_set[config] ~= nil)
    ft_configs_set[config] = nil
  end

  for command_name, _ in pairs(config.ignition_commands) do
    utils_vim.delete_command(command_name)
  end

  -- NOTE: Deletion here breaks the `require('lspconfig').server_xyz` API
  -- because the table exported from the main module has to be cleaned up too.
  -- M._delete_config_compat_ghost(config_name)

  for _, fn in ipairs(M.service_hooks.on_config_uninstalled) do
    fn(config)
  end
  return config
end


function M.should_attach(bufnr)
  local buftype = vim.api.nvim_buf_get_option(bufnr, 'buftype')
  if buftype ~= '' and buftype ~= 'acwrite' then return false end

  local path = vim.api.nvim_buf_get_name(bufnr)
  if path:match(utils.URI_SCHEME_PATTERN) then return false end

  local buf_filetype = vim.api.nvim_buf_get_option(bufnr, 'filetype')
  if lsp_global_settings.IGNORED_FILETYPES[buf_filetype] then return false end

  local ok, value = pcall(vim.api.nvim_buf_get_var, bufnr, 'lsp_enabled')
  if ok and utils_vim.is_truthy(value) then return false end

  if vim.api.nvim_buf_get_option(bufnr, 'binary') then return false end

  if lsp_global_settings.MAX_FILE_SIZE then
    local file_size = utils_vim.buf_get_inmemory_text_byte_size(bufnr)
    if file_size > lsp_global_settings.MAX_FILE_SIZE then return false end
  end

  return true
end


function M.on_buf_created(bufnr)
  if M.should_attach(bufnr) then
    for config, _ in pairs(M.get_matching_configs_for_buf(bufnr)) do
      if config.autostart ~= false then
        local client_id = M.ensure_client_started_for_buf(config, bufnr)
        if client_id then M.ensure_client_attached_to_buf(config, client_id, bufnr) end
      end
    end
  end
end


function M.get_matching_configs_for_buf(bufnr)
  local results = {}
  local ft = vim.api.nvim_buf_get_option(bufnr, 'filetype')

  local configs_set = M.filetypes_to_configs_map[ft]
  if configs_set ~= nil then
    for config, _ in pairs(configs_set) do results[config] = true end
  end
  if ft ~= '*' then  -- What the heck?
    configs_set = M.filetypes_to_configs_map['*']
    if configs_set ~= nil then
      for config, _ in pairs(configs_set) do results[config] = true end
    end
  end

  return results
end


function M.ensure_client_started_for_buf(config, bufnr)
  local root_dir = nil

  -- The server might be independent of a root directory (the dummy entry plug
  -- is, for example).
  if config.root_dir then
    -- TODO: Resolve absolute paths of non-existent files. NOTE:
    -- `fnamemodify(path, ':p')` can't do anything if the path doesn't exist.
    local buf_path = vim.api.nvim_buf_get_name(bufnr)
    root_dir = config.root_dir(buf_path, bufnr)
    if not (root_dir and vim.fn.isdirectory(root_dir) ~= 0) then
      lsp_utils.client_notify(
        config.name,
        string.format("Couldn't find workspace root directory for file %q", buf_path),
        vim.log.levels.WARN
      )
      root_dir = nil
    end
    vim.api.nvim_buf_set_var(bufnr, 'lsp_detected_root_dir', root_dir)
  end

  return M.ensure_client_started_for_config(config, root_dir, bufnr)
end


-- NOTE: The bufnr here is optional. Servers can be started without a "trigger"
-- buffer, for instance, when performing an :LspRestart.
function M.ensure_client_started_for_config(config, root_dir, responsible_bufnr)
  if root_dir and M.workspace_root_dirs[root_dir] == nil then
    -- We haven't seen this root directory before, need to send it to all
    -- already connected clients. Should this function proceed with starting
    -- a new client, it will receive workspace roots in its before_init
    -- callback.
    M.broadcast_workspace_root_dirs_change({ [root_dir] = true })
  end

  local client_id = M.configs_to_client_ids_map[config]
  if client_id == false then
    -- The client has been disabled.
    client_id = nil
  elseif client_id == nil then
    -- Great, no client is running! Begin the activation sequence.
    local ok, result = xpcall(function()  -- Three...
      local final_config =
        M.make_final_client_config_for_buf(config, root_dir, responsible_bufnr)  -- Two...
      if final_config.enabled == false then  -- One...
        -- Disable the client and forbid further attempts of starting it.
        M.configs_to_client_ids_map[config] = false
      else
        -- ZERO!!! PRIMARY ENGINE IGNITION!!!
        client_id = lsp.start_client(final_config)
        M.configs_to_client_ids_map[config] = client_id

        local client = lsp.get_client_by_id(client_id)
        assert(client, 'lsp.start_client has returned an invalid client_id')
        -- This extra hook is for tapping into the client just after it has
        -- begun connecting to the server. This solves the problem that
        -- `before_init` receives neither an instance of the client nor its ID,
        -- and `on_init` is fired only after the server has been initialized is
        -- received.
        pcall(client.config.on_create, client)
      end
    end, debug.traceback)

    if not ok then
      -- Forbid spam of errors on repeated start attempts when opening other
      -- files if the client has crashed.
      M.configs_to_client_ids_map[config] = false
      vim.notify(
        string.format(
          'failed to start a client for %q (root dir is %q):\n%s',
          config.name, tostring(root_dir), result
        ),
        vim.log.levels.ERROR
      )
      client_id = nil
    end
  end

  return client_id
end


function M.broadcast_workspace_root_dirs_change(changes)
  vim.validate({
    changes = {changes, 'table'};
  })

  local req_params = { event = { added = {}, removed = {} } }
  local i = 0
  for root_dir, add in pairs(changes) do
    i = i + 1
    if type(root_dir) ~= 'string' then
      error(string.format('changes key #%d: expected string, got %s', i, type(root_dir)))
    end
    if type(add) ~= 'boolean' then
      error(string.format('changes value #%d: expected boolean, got %s', i, type(add)))
    end
    if add then

      if M.workspace_root_dirs[root_dir] then
        error(string.format('root directory %q has already been registered', root_dir))
      end
      local new_workspace_folder = { uri = vim_uri.uri_from_fname(root_dir), name = root_dir }
      M.workspace_root_dirs[root_dir] = new_workspace_folder
      table.insert(req_params.event.added, new_workspace_folder)

    else

      local old_workspace_folder = M.workspace_root_dirs[root_dir]
      if not old_workspace_folder then
        error(string.format("root directory %q hasn't been registered before", root_dir))
      end
      M.workspace_root_dirs[root_dir] = nil
      table.insert(req_params.event.removed, old_workspace_folder)

    end
  end

  for _, client_id in pairs(M.configs_to_client_ids_map) do
    if client_id then
      local client = lsp.get_client_by_id(client_id)
      if client.initialized then
        -- assert(client.workspaceFolders)
        local capabilities = client.resolved_capabilities
        if (
          capabilities.workspace_folder_properties.supported and
          capabilities.workspace_folder_properties.changeNotifications
        ) then
          client.notify('workspace/didChangeWorkspaceFolders', req_params)
        end
        client.workspaceFolders = vim.tbl_values(M.workspace_root_dirs)
      end
    end
  end
end


function M.make_final_client_config_for_buf(src_config, root_dir, responsible_bufnr)
  -- `vim.deepcopy` won't let me copy `vim.NIL`s...
  local final_config = vim.tbl_deep_extend('force', {}, src_config)

  final_config.root_dir_real = root_dir
  if CAN_USE_NIL_ROOT_DIR or root_dir then
    -- Normal case, the root directory is specified (or we have PR 15430).
    final_config.root_dir = root_dir
  else
    if utils_vim.has('unix') then
      -- The root directory is not specified, but the `lsp.start_client`
      -- performs a check for whether `root_dir` is a path that points to a
      -- directory, so it must be faked before we reach `before_init`. But we
      -- can't necessarily use CWD because it is very well possible to start
      -- processes in deleted directories. However, we are on POSIX, and the FS
      -- root directory always exists, so we will use that.
      final_config.root_dir = '/'
    elseif utils_vim.has('win32') then
      -- Same situation, but we are on Windows, where there is no root
      -- directory and C:/ is not guaranteed to exist. But let's try C:/ anyway
      -- because it will exist on any sane setup (other contenders include
      -- $VIMRUNTIME).
      final_config.root_dir = 'C:\\'
    end
    if not final_config.root_dir or not vim.fn.isdirectory(final_config.root_dir) then
      -- If we still aren't able to determine a fake `root_dir`, fall back to
      -- CWD as a last resort. Which might not exist.
      final_config.root_dir = vim.fn.getcwd()
    end
  end

  -- <https://github.com/neovim/neovim/pull/15132/files>
  -- We set the workspace folders ourselves and mustn't allow the user to
  -- override them.
  final_config.workspace_folders = nil

  final_config.capabilities = final_config.capabilities or lsp.protocol.make_client_capabilities()
  final_config.capabilities = vim.tbl_deep_extend('keep', final_config.capabilities, {
    workspace = {
      configuration = true;  -- Allows us sending settings.
      didChangeConfiguration = { dynamicRegistration = false };  -- Same.
      workspaceFolders = true;  -- Allows multiple workspace roots.
    };
  })

  if not final_config.on_error then
    function final_config.on_error(code, err)
      local msg = string.format(
        'LSP[%s]: Error %s: %s', final_config.name, lsp.client_errors[code], err
      )
      if vim.in_fast_event() then
        vim.schedule(function() vim.api.nvim_err_writeln(msg) end)
      else
        vim.api.nvim_err_writeln(msg)
      end
    end
  end

  local function call_hook(error_type, fn, ...)
    local ok, err = xpcall(fn, debug.traceback, ...)
    if not ok then
      pcall(final_config.on_error, lsp.client_errors[error_type], err)
    end
  end
  local function wrap_hook(error_type, fn)
    return function(...) return call_hook(error_type, fn, ...) end
  end

  local orig_before_init = final_config.before_init
  final_config.before_init = wrap_hook('BEFORE_INIT_CALLBACK_ERROR', function(...)
    local init_params, config = ...
    if config.root_dir_real then
      init_params.rootPath = config.root_dir_real
      init_params.rootUri = vim_uri.uri_from_fname(config.root_dir_real)
      -- Get the workspace dirs at the last possible moment, so that they are
      -- the most accurate. Don't forget that client initialization is async.
      init_params.workspaceFolders = vim.tbl_values(M.workspace_root_dirs)
    else
      init_params.rootPath = vim.NIL
      init_params.rootUri = vim.NIL
      init_params.workspaceFolders = vim.NIL
    end
    for _, fn in ipairs(M.service_hooks.before_init) do
      fn(...)
    end
    if orig_before_init ~= nil then
      return orig_before_init(...)
    end
  end)

  local orig_on_create = final_config.on_create
  final_config.on_create = wrap_hook('ON_CREATE_CALLBACK_ERROR', function(...)
    for _, fn in ipairs(M.service_hooks.on_create) do
      fn(...)
    end
    if orig_on_create ~= nil then
      return orig_on_create(...)
    end
  end)

  local orig_on_init = final_config.on_init
  final_config.on_init = wrap_hook('ON_INIT_CALLBACK_ERROR', function(...)
    local client, init_result = ...

    -- Fake this for the purposes of :LspInfo. It's not like we or any
    -- remaining built-in functions read this field.
    client.workspaceFolders = {{
      uri = vim_uri.uri_from_fname(tostring(client.config.root_dir));
      name = tostring(client.config.root_dir);
    }}

    -- See also: <https://github.com/neovim/nvim-lspconfig/pull/1360>.
    if type(init_result.offsetEncoding) == 'string' then
      client.offset_encoding = init_result.offsetEncoding
    end

    -- See also: <https://github.com/neovim/neovim/pull/13659>.
    -- TODO: Ensure that the settings aren't setn twice.
    local settings = client.config.settings
    if settings then
      if vim.tbl_isempty(settings) then
        settings = vim.empty_dict()
      end
      client.notify('workspace/didChangeConfiguration', { settings = settings })
    end

    for _, fn in ipairs(M.service_hooks.on_init) do
      fn(...)
    end
    if orig_on_init ~= nil then
      return orig_on_init(...)
    end
  end)

  local orig_on_attach = final_config.on_attach
  final_config.on_attach = wrap_hook('ON_ATTACH_CALLBACK_ERROR', function(...)
    for _, fn in ipairs(M.service_hooks.on_attach) do
      fn(...)
    end
    -- We aren't calling a Lua function here, `xpcall` won't do any good.
    local ok, err = pcall(vim.api.nvim_command, 'doautocmd <nomodeline> User LspIgnitionBufAttach')
    if not ok then
      vim.api.nvim_err_writeln(err)
    end
    if orig_on_attach ~= nil then
      return orig_on_attach(...)
    end
  end)

  local orig_on_exit = final_config.on_exit
  final_config.on_exit = wrap_hook('ON_EXIT_CALLBACK_ERROR', function(...)
    M.configs_to_client_ids_map[src_config] = nil
    for _, fn in ipairs(M.service_hooks.on_exit) do
      fn(...)
    end
    if orig_on_exit ~= nil then
      return orig_on_exit(...)
    end
  end)

  call_hook('ON_NEW_CONFIG_CALLBACK_ERROR', function(...)
    for _, fn in ipairs(M.service_hooks.on_new_config) do
      fn(...)
    end
    -- TODO: New on_new_config, the current solution is temporary crap.
    local config_preset = M.config_presets_registry[final_config.name]
    if config_preset ~= nil and config_preset.on_new_config then
      config_preset.on_new_config(...)
    end
    if final_config.on_new_config then
      final_config.on_new_config(...)
    end
  end, final_config, final_config.root_dir, responsible_bufnr)

  return final_config
end


function M.ensure_client_attached_to_buf(config, client_id, bufnr)
  assert(vim.api.nvim_buf_is_valid(bufnr), 'buffer not found')
  -- This line <https://github.com/neovim/neovim/blob/v0.5.0/runtime/lua/vim/lsp.lua#L1133>
  -- may(?) cause a leak on repeated attachments, so we make a sanity check
  -- beforehand. TODO: open a fix PR to the upstream.
  if not lsp.buf_is_attached(bufnr, client_id) then
    return lsp.buf_attach_client(bufnr, client_id)
  else
    return true
  end
end


function M.get_all_client_ids()
  local result = {}
  local i = 1
  for _, client_id in pairs(M.configs_to_client_ids_map) do
    if client_id then
      result[i] = client_id
      i = i + 1
    end
  end
  return result
end


function M.get_client_by_config_name(name)
  -- This should pass through all the intermediary `nil`s...
  return lsp.get_client_by_id(M.configs_to_client_ids_map[M.configs_registry[name]])
end


function M.command_info()
  local ok, lspconfig = pcall(require, 'lspconfig')
  assert(ok, 'sorry, this command is not implemented yet!')
  lspconfig._root.commands.LspInfo[1]()
end


function M.command_start(call_info)
  local requested_configs = nil
  if not vim.tbl_isempty(call_info.f_args) then
    requested_configs = {}
    for _, config_name in ipairs(call_info.f_args) do
      local config = M.configs_registry[config_name]
      if config ~= nil then
        requested_configs[config] = true
      else
        error(string.format('config %q not found', config_name))
      end
    end
  end

  local bufnr = vim.api.nvim_get_current_buf()
  if M.should_attach(bufnr) then
    local matching_configs = M.get_matching_configs_for_buf(bufnr)
    for config, _ in pairs(requested_configs or matching_configs) do
      config.autostart = true
      -- NOTE: I moved start-up of the client outside of the check for whether
      -- the config actually applies to the buffer on purpose. This does allow
      -- starting an LS for a file of a different filetype, but this file is
      -- used only for detection of the root directory. As an example, I can
      -- open `Cargo.toml` and start the language server for Rust in the
      -- project that this `Cargo.toml` resides in.
      local client_id = M.ensure_client_started_for_buf(config, bufnr)
      if matching_configs[config] ~= nil then
        if client_id then M.ensure_client_attached_to_buf(config, client_id, bufnr) end
      end
    end
  end
end


function M.command_start_completion()
  local results = {}
  local bufnr = vim.api.nvim_get_current_buf()

  local all_configs = vim.tbl_values(M.configs_registry)
  local matching_configs = M.get_matching_configs_for_buf(bufnr)
  M._command_completion_sort_configs(all_configs, matching_configs)

  for _, config in pairs(all_configs) do
    local client_id = M.configs_to_client_ids_map[config]
    if not client_id or not lsp.buf_is_attached(bufnr, client_id) then
      table.insert(results, config.name)
    end
  end
  return table.concat(results, '\n')
end


function M.command_stop(call_info)
  local requested_client_ids = {}

  if vim.tbl_isempty(call_info.f_args) then
    -- Stop all clients that we are in charge of.
    for config, client_id in pairs(M.configs_to_client_ids_map) do
      if client_id then requested_client_ids[client_id] = {config = config} end
    end
  else
    -- Stop only the clients the user has requested.
    for _, config_name in ipairs(call_info.f_args) do
      local client_id = tonumber(config_name)
      if client_id then
        requested_client_ids[client_id] = {}
        goto continue
      end

      local config = M.configs_registry[config_name]
      if config ~= nil then
        client_id = M.configs_to_client_ids_map[config]
        if client_id then
          requested_client_ids[client_id] = {config = config}
        end
        goto continue
      else
        error(string.format('config %q not found', config_name))
      end

      ::continue::
    end
  end

  local force = call_info.bang
  for client_id, client_meta_bag in pairs(requested_client_ids) do
    local config = client_meta_bag.config
    if config then config.autostart = false end
    local client = lsp.get_client_by_id(client_id)
    if client then client.stop(force) end
  end
end


function M.command_stop_completion()
  local results = {}
  local bufnr = vim.api.nvim_get_current_buf()

  local started_configs, attached_configs = {}, {}
  for config, client_id in pairs(M.configs_to_client_ids_map) do
    if client_id then
      table.insert(started_configs, config)
      if lsp.buf_is_attached(bufnr, client_id) then
        attached_configs[config] = true
      end
    end
  end
  M._command_completion_sort_configs(started_configs, attached_configs)

  for _, config in pairs(started_configs) do
    local client_id = M.configs_to_client_ids_map[config]
    if client_id then
      table.insert(results, config.name)
      table.insert(results, tostring(client_id))
    end
  end
  return table.concat(results, '\n')
end


function M.command_restart(call_info)
  local requested_configs_with_root_dirs = {}

  if vim.tbl_isempty(call_info.f_args) then
    for config, _ in pairs(M.configs_to_client_ids_map) do
      requested_configs_with_root_dirs[config] = {}
    end
  else
    for _, config_name in ipairs(call_info.f_args) do
      local config = M.configs_registry[config_name]
      if config ~= nil then
        requested_configs_with_root_dirs[config] = {}
      else
        error(string.format('config %q not found', config_name))
      end
    end
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local force = call_info.bang
  for config, config_meta_bag in pairs(requested_configs_with_root_dirs) do
    local client_id = M.configs_to_client_ids_map[config]
    if client_id then
      config_meta_bag.prev_client_id = client_id
      local client = lsp.get_client_by_id(client_id)
      if client then
        config_meta_bag.root_dir = client.config.root_dir_real
        config_meta_bag.attached_buffers = vim.list_slice(lsp.get_buffers_by_client_id(client_id))
        client.stop(force)
      end
    end
  end

  utils.set_timeout(M._CLIENT_RESTART_TIMEOUT, function()
    local should_attach = M.should_attach(bufnr)
    local matching_configs = M.get_matching_configs_for_buf(bufnr)
    for config, config_meta_bag in pairs(requested_configs_with_root_dirs) do
      config.autostart = true
      if config_meta_bag.prev_client_id then
        -- The root dir has been previously known, use it for restarting the client.
        local client_id = M.ensure_client_started_for_config(config, config_meta_bag.root_dir)
        for _, bufnr2 in ipairs(config_meta_bag.attached_buffers) do
          if vim.api.nvim_buf_is_valid(bufnr2) then
            M.ensure_client_attached_to_buf(config, client_id, bufnr2)
          end
        end
      elseif should_attach then
        -- NOTE: See the comment in `M.command_start()`.
        local client_id = M.ensure_client_started_for_buf(config, bufnr)
        if matching_configs[config] ~= nil then
          if client_id then M.ensure_client_attached_to_buf(config, client_id, bufnr) end
        end
      end
    end
  end)
end


function M.command_restart_completion()
  local results = {}
  local bufnr = vim.api.nvim_get_current_buf()

  local started_configs, attached_configs = {}, {}
  for config, client_id in pairs(M.configs_to_client_ids_map) do
    if client_id then
      table.insert(started_configs, config)
      if lsp.buf_is_attached(bufnr, client_id) then
        attached_configs[config] = true
      end
    end
  end
  M._command_completion_sort_configs(started_configs, attached_configs)

  for _, config in pairs(started_configs) do
    local client_id = M.configs_to_client_ids_map[config]
    if client_id then
      table.insert(results, config.name)
    end
  end
  return table.concat(results, '\n')
end


function M._command_completion_sort_configs(all_configs, matching_configs)
  matching_configs = matching_configs or {}
  return table.sort(all_configs, function(cfg_a, cfg_b)
    local cfg_a_matching = matching_configs[cfg_a]
    local cfg_b_matching = matching_configs[cfg_b]
    if cfg_a_matching ~= cfg_b_matching then
      -- Sort matching configs earlier in the results. `a and not b` is equiv
      -- to `a > b` had Lua supported comparison ops on booleans.
      return cfg_a_matching and not cfg_b_matching
    else
      return cfg_a.name < cfg_b.name
    end
  end)
end


function M.add_client_capabilities(extra_capabilities)
  M.default_config.capabilities = vim.tbl_deep_extend('force', M.default_config.capabilities, extra_capabilities)
end

function M.add_default_config(extra_config)
  M.default_config = vim.tbl_deep_extend('force', M.default_config, extra_config)
end


return M
