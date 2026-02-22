local git = require('gim.git')

M = {}

local state = {
  list_win = nil,
  diff_win = nil,
  diff_buf = nil,
  list_buf = nil,
}

local cursor_move_group = 'cursor_move'

local insert_modes = { 'i', 'I', 'a', 'A', 'o', 'O', 'd', 'D', 'x', 'X' }

local function create_buf()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].modifiable = true
  vim.bo[buf].swapfile = false
  vim.bo[buf].buftype = 'nofile'
  vim.bo[buf].bufhidden = 'wipe'
  return buf
end

local function get_modal_config()
  local columns = vim.o.columns
  local lines = vim.o.lines

  local width = math.floor(columns * 0.8)
  local height = math.floor(lines * 0.8)

  local row = math.floor((lines - height) / 2)
  local col = math.floor((columns - width) / 2)

  return {
    width = width,
    height = height,
    col = col,
    row = row,
  }
end


local function disable_insert_mode(buf)
  for _, mode in ipairs(insert_modes) do
    vim.keymap.set('n', mode, '<nop>', { buffer = buf })
  end
end

local function set_win_options()
  local list_win, diff_win = state.list_win, state.diff_win
  vim.api.nvim_set_option_value('winhighlight', 'CursorLine:MyPluginCursorLine', { win = list_win })
  vim.api.nvim_set_option_value('winhighlight', 'CursorLine:MyPluginCursorLine', { win = diff_win })
  vim.api.nvim_set_option_value('cursorline', true, { win = list_win })
  vim.api.nvim_set_option_value('cursorline', true, { win = diff_win })
  vim.api.nvim_set_option_value('number', true, { win = list_win })
  vim.api.nvim_set_option_value('relativenumber', true, { win = list_win })
end

local function add_cursor_listener(files)
  local list_win, diff_buf = state.list_win, state.diff_buf
  if list_win == nil or diff_buf == nil then return end

  local group = vim.api.nvim_create_augroup(cursor_move_group, { clear = true })
  vim.api.nvim_create_autocmd('CursorMoved', {
    group = group,
    callback = function()
      local row = vim.api.nvim_win_get_cursor(list_win)[1]
      if #files == 0 then return end
      local current_file = files[row]
      local diff = git.get_file_diff(current_file.status, current_file.file)
      vim.api.nvim_buf_set_lines(diff_buf, 0, -1, true, diff and vim.split(diff, '\n') or { 'no changes' })
    end
  })
end

local function win_focus_listner()
  local list_win, diff_win, diff_buf, list_buf = state.list_win, state.diff_win, state.diff_buf, state.list_buf
  if list_win and diff_win then
    vim.keymap.set('n', '1', function() vim.api.nvim_set_current_win(list_win) end, { buffer = diff_buf })
    vim.keymap.set('n', '2', function() vim.api.nvim_set_current_win(diff_win) end, { buffer = list_buf })
  end
end

local function set_lines(files)
  table.sort(files, function (a, b)
    return a.file < b.file
  end)
  local files_with_status = {}
  for _, v in pairs(files) do
    table.insert(files_with_status, v.status .. ' ' .. v.file)
  end

  vim.api.nvim_buf_set_lines(state.list_buf, 0, -1, true,
    #files_with_status ~= 0 and files_with_status or { 'there are no changes' })
end

function M.open()
  local diff_buf = create_buf()
  vim.bo[diff_buf].filetype = 'diff'
  local list_buf = create_buf()

  local config = get_modal_config()
  local list_width = math.floor(config.width * 0.4)
  local diff_width = config.width - list_width - 1

  local diff_win = vim.api.nvim_open_win(diff_buf, true, {
    width = diff_width,
    height = config.height,
    col = config.col + list_width + 2,
    row = config.row,
    title = '2',
    title_pos = 'center',
    relative = 'editor',
    style = 'minimal',
    border = 'rounded',
  })

  local list_win = vim.api.nvim_open_win(list_buf, true, {
    width = list_width,
    height = config.height,
    col = config.col,
    row = config.row,
    title = '1',
    title_pos = 'center',
    relative = 'editor',
    style = 'minimal',
    border = 'rounded',
  })

  state.list_win = list_win
  state.diff_win = diff_win
  state.diff_buf = diff_buf
  state.list_buf = list_buf

  local files = git.get_files()
  set_lines(files)

  set_win_options()
  add_cursor_listener(files)
  disable_insert_mode(list_buf)
  win_focus_listner()

  vim.keymap.set('n', 'a', function()
    local row = vim.api.nvim_win_get_cursor(list_win)[1]
    local current_file = files[row].file
    local result = git.stage(current_file)
    if result.code == 0 then set_lines(git.get_files()) end
  end, { buffer = list_buf })

  vim.keymap.set('n', 'd', function()
    local row = vim.api.nvim_win_get_cursor(list_win)[1]
    local current_file = files[row].file
    local result = git.unstage(current_file)
    if result.code == 0 then set_lines(git.get_files()) end
  end, { buffer = list_buf })
end

function M.close()
  local list_win, diff_win = state.list_win, state.diff_win
  if list_win and diff_win then
    vim.api.nvim_win_close(state.list_win, true)
    vim.api.nvim_win_close(state.diff_win, true)
    vim.api.nvim_clear_autocmds({ group = cursor_move_group })
    state.list_win = nil
    state.diff_win = nil
    state.diff_buf = nil
    state.list_buf = nil
  end
end

return M
