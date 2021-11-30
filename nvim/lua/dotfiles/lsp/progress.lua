--- See also:
--- <https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#workDoneProgress>
--- <https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#initiatingWorkDoneProgress>
--- <https://github.com/neovim/neovim/blob/v0.5.0/runtime/lua/vim/lsp/handlers.lua#L27-L77>
--- <https://github.com/neovim/neovim/blob/v0.5.0/runtime/lua/vim/lsp/util.lua#L183-L238>
--- <https://github.com/neoclide/coc.nvim/blob/c49acf35d8c32c16e1f14ab056a15308e0751688/src/model/status.ts>
--- <https://github.com/neoclide/coc.nvim/blob/c49acf35d8c32c16e1f14ab056a15308e0751688/src/language-client/progressPart.ts>
--- <https://github.com/neoclide/coc.nvim/blob/c49acf35d8c32c16e1f14ab056a15308e0751688/src/language-client/progress.ts>
--- <https://github.com/neoclide/coc.nvim/blob/c49acf35d8c32c16e1f14ab056a15308e0751688/src/window.ts#L324-L340>
--- <https://github.com/neoclide/coc.nvim/blob/c49acf35d8c32c16e1f14ab056a15308e0751688/src/language-client/client.ts#L3726-L3737>
--- <https://github.com/neoclide/coc.nvim/blob/c49acf35d8c32c16e1f14ab056a15308e0751688/src/handler/index.ts#L128-L167>
--- <https://github.com/doums/lsp_spinner.nvim/blob/880e72a3744bc11948ab46a16c682a3dd3d247a3/lua/lsp_spinner.lua>
--- <https://github.com/doums/lsp_spinner.nvim/blob/880e72a3744bc11948ab46a16c682a3dd3d247a3/lua/lsp_spinner/redraw.lua>
--- <https://github.com/nvim-lua/lsp-status.nvim/blob/e8e5303f9ee3d8dc327c97891eaa1257ba5d4eee/lua/lsp-status/messaging.lua>
--- <https://github.com/nvim-lua/lsp-status.nvim/blob/e8e5303f9ee3d8dc327c97891eaa1257ba5d4eee/lua/lsp-status/redraw.lua>
---
--- TODO:
--- <https://github.com/neoclide/coc.nvim/blob/c49acf35d8c32c16e1f14ab056a15308e0751688/src/handler/index.ts#L128-L167>
local M, MODULE_INFO = require('dotfiles.autoload')('dotfiles.lsp.progress')

local lsp_ignition = require('dotfiles.lsp.ignition')
local lsp = require('vim.lsp')
local utils = require('dotfiles.utils')
local lsp_utils = require('dotfiles.lsp.utils')
local uv = require('luv')


M.SPINNER_FRAMES = {'⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'}
M.SPINNER_SPEED = 20  -- ticks per second
M.HIDE_MESSAGES_AFTER = 300  -- ms

M.status_items = {}
M._timer = uv.new_timer()
M._spinner_tick = 0
M._cached_status_text = ''


local spinner_time_drift = 0
local prev_time = uv.now()
-- An over-engineered timer implementation which accounts for the fact that
-- timers don't get triggered precisely at the given intervals, especially when
-- the event loop has other blocking work to do. See also: game event loops
-- <https://gafferongames.com/post/fix_your_timestep/>. All times here are
-- calculated in milliseconds.
local function redraw_and_reschedule()
  local curr_time = uv.now()
  local delta_time = curr_time - prev_time
  prev_time = curr_time

  spinner_time_drift = spinner_time_drift + delta_time
  local spinner_interval = 1000 / M.SPINNER_SPEED
  M._spinner_tick = M._spinner_tick + math.floor(spinner_time_drift / spinner_interval)
  spinner_time_drift = spinner_time_drift % spinner_interval
  local redraw_spinners_at = curr_time + spinner_interval - spinner_time_drift

  local next_redraw_at = math.huge
  for i = #M.status_items, 1, -1 do
    local item = M.status_items[i]
    if item.hide_at ~= nil and curr_time >= item.hide_at then
      table.remove(M.status_items, i)
      goto continue
    end

    if item.hide_at ~= nil then
      next_redraw_at = math.min(next_redraw_at, item.hide_at)
    end
    if item.percentage ~= nil then
      next_redraw_at = math.min(next_redraw_at, redraw_spinners_at)
    end

    ::continue::
  end

  if next_redraw_at < math.huge then
    M._timer:start(math.max(1, next_redraw_at - curr_time), 0, redraw_and_reschedule)
  else
    M._timer:stop()
  end

  local prev_status_text = M._cached_status_text
  M.update_status_text()
  if M._cached_status_text ~= prev_status_text then
    -- Remember, we are still in the fast event context.
    vim.schedule(function()
      vim.cmd('doautocmd <nomodeline> User LspProgressUpdate')
    end)
  end
end

function M.resume_timer()
  if not M._timer:is_active() then
    M._timer:start(1, 0, redraw_and_reschedule)
  end
end

function M.create_status_item()
  local item = {
    before_text = '';
    title = '';
    message = '';
    after_text = '';
    -- nil: Not a progress item, hide the spinner.
    -- false: Indeterminate, the percentage is not known, but show a spinner.
    -- number: Progress percentage, from 0 to 100.
    percentage = nil;
    -- NOTE: Use `uv.now() + some_timeout` for this.
    hide_at = nil;
  }
  table.insert(M.status_items, item)
  M.resume_timer()
  return item
end

function M.delete_status_item(item)
  local idx = utils.list_index_of(M.status_items, item)
  if idx then
    table.remove(M.status_items, idx)
  end
end


function M.update_status_text()
  local spinner_frame = M.SPINNER_FRAMES[M._spinner_tick % #M.SPINNER_FRAMES + 1]
  local text_parts = {}
  for _, item in ipairs(M.status_items) do
    local item_parts = {}
    if item.percentage ~= nil then
      table.insert(item_parts, spinner_frame)
    end
    if item.before_text ~= '' then
      table.insert(item_parts, item.before_text)
    end
    if item.title ~= '' then
      table.insert(item_parts, item.title)
    end
    if type(item.percentage) == 'number' then
      table.insert(item_parts, string.format('[%d%%]', item.percentage))
    end
    if item.message ~= '' then
      table.insert(item_parts, item.message)
    end
    if item.after_text ~= '' then
      table.insert(item_parts, item.after_text)
    end
    table.insert(text_parts, table.concat(item_parts, ' '))
  end
  M._cached_status_text = table.concat(text_parts, '  ')
  return M._cached_status_text
end


function M.get_status_text()
  return M._cached_status_text
end


function M._hook_client_created(client)
  client.messages = nil
  client.dotfiles_progress_tokens = {}
  local item = M.create_status_item()
  item.percentage = false
  item.before_text = '[' .. lsp_utils.try_get_client_name(client) .. ']'
  item.message = 'Initializing'
  client.dotfiles_init_status_item = item
end

function M._hook_client_before_init(init_params, config)
  init_params.workDoneToken = M.random_token()
  config.strict_progress_token_tracking = utils.if_nil(config.strict_progress_token_tracking, true)
end

function M._hook_on_client_init(client)
  local item = client.dotfiles_init_status_item
  client.dotfiles_init_status_item = nil
  item.after_text = '[done]'
  item.percentage = nil
  item.hide_at = uv.now() + M.HIDE_MESSAGES_AFTER
end

table.insert(lsp_ignition.service_hooks.on_create, M._hook_client_created)
table.insert(lsp_ignition.service_hooks.before_init, M._hook_client_before_init)
table.insert(lsp_ignition.service_hooks.on_init, M._hook_on_client_init)


function lsp.util.get_progress_messages()
  error('the original progress implementation has been replaced by ' .. MODULE_INFO.name)
end


function M._client_add_token(client, token)
  if not (type(token) == 'string' or type(token) == 'number') then
    error('invalid progress token type: ' .. type(token))
  end
  if client.config.strict_progress_token_tracking and client.dotfiles_progress_tokens[token] ~= nil then
    error('progress token is already in use: ' .. tostring(token))
  end
  local token_data = {}
  client.dotfiles_progress_tokens[token] = token_data
  return token_data
end

-- <https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#window_workDoneProgress_create>
lsp.handlers['window/workDoneProgress/create'] = lsp_utils.wrap_handler_compat(function(err, result, ctx, config)
  if err then
    return lsp_utils.client_notify(ctx.client_id, err, vim.log.levels.ERROR)
  end
  local client = lsp_utils.assert_get_client_by_id(ctx.client_id)
  M._client_add_token(client, result.token)
  return vim.NIL
end)

-- <https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#window_workDoneProgress_cancel>
lsp.handlers['window/workDoneProgress/cancel'] = lsp_utils.wrap_handler_compat(function(err, result, ctx, config)
  if err then
    return lsp_utils.client_notify(ctx.client_id, err, vim.log.levels.ERROR)
  end
  local client = lsp_utils.assert_get_client_by_id(ctx.client_id)
  if client.dotfiles_progress_tokens[result.token] ~= nil then
    client.dotfiles_progress_tokens[result.token] = nil
  elseif client.config.strict_progress_token_tracking then
    error('no such progress token: ' .. tostring(result.token))
  end
  return vim.NIL
end)

-- <https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#progress>
-- <https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#workDoneProgress>
lsp.handlers['$/progress'] = lsp_utils.wrap_handler_compat(function(err, result, ctx, config)
  if err then
    return lsp_utils.client_notify(ctx.client_id, err, vim.log.levels.ERROR)
  end
  local client = lsp_utils.assert_get_client_by_id(ctx.client_id)
  local token_data = client.dotfiles_progress_tokens[result.token]
  if token_data == nil then
    -- TODO: 'begin' messages are special-cased here because I haven't yet come
    -- up with a clean way of registering tokens for client-initiated progress.
    -- if result.value.kind ~= 'begin' and client.config.strict_progress_token_tracking then
    --   error('no such progress token: ' .. tostring(result.token))
    -- else
      token_data = M._client_add_token(client, result.token)
    -- end
  end

  if result.value.kind == 'begin' or result.value.kind == 'report' then
    -- <https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#workDoneProgressBegin>
    -- <https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#workDoneProgressReport>
    -- These two kinds are almost the same in terms of fields and behavior, and
    -- I didn't want to also track token states (whether the progress has begun
    -- or not and so on), so I'm gonna handle them in one branch.
    local item = token_data.status_item
    if not item then
      item = M.create_status_item()
      item.before_text = '[' .. lsp_utils.try_get_client_name(client) .. ']'
      token_data.status_item = item
    end
    item.title = tostring(utils.if_nil(result.value.title, item.title))
    item.message = tostring(utils.if_nil(result.value.message, item.message))
    item.percentage = utils.if_nil(result.value.percentage, false)
  elseif result.value.kind == 'end' then
    -- <https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#workDoneProgressEnd>
    local item = token_data.status_item
    if item then
      item.percentage = nil
      item.after_text = '[done]'
      item.message = tostring(utils.if_nil(result.value.message, item.message))
      item.hide_at = uv.now() + M.HIDE_MESSAGES_AFTER
    end
    client.dotfiles_progress_tokens[result.token] = nil
  else
    error('unknown progress payload kind: ' .. tostring(result.value.kind))
  end

  M.resume_timer()
  return vim.NIL
end)


function M.random_token()
  local str_len = 16
  local str = nil
  if uv.random then
    str = uv.random(str_len)
  else
    local file = assert(io.open("/dev/urandom", "rb"))
    while #str < str_len do
      str = str .. file:read(str_len - #str)
    end
    file:close()
  end
  assert(#str == str_len)
  local result = {'nvimlsp/'}
  for i = 1, str_len do
    result[i + 1] = string.format('%02x', string.byte(str, i))
  end
  return table.concat(result)
end


return M
