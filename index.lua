local state = {
  left_win = nil,
  left_buf = nil,

  right_win = nil,
  right_buf = nil,
}

local cursor_move_group = 'cursor_move'

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

local function get_files()
  -- TODO: use vim.system for this
  return vim.fn.systemlist('git diff --name-only')
end

local function get_file_diff(file)
  local result = vim.system(
    { 'git', 'diff', '--', file },
    { text = true }
  ):wait()
  if result.code ~= 0 then return nil end
  return result.stdout
end

local insert_modes = { 'i', 'I', 'a', 'A', 'o', "O" }

local function disable_insert_mode(buf)
  for _, mode in ipairs(insert_modes) do
    vim.keymap.set('n', mode, '<nop>', { buffer = buf })
  end
end

local function open_modal()
  local right_buf = create_buf()
  vim.bo[right_buf].filetype = 'diff'
  local left_buf = create_buf()

  local config = get_modal_config()
  local left_width = math.floor(config.width * 0.4)
  local right_width = config.width - left_width - 1

  local right_win = vim.api.nvim_open_win(right_buf, true, {
    width = right_width,
    height = config.height,
    col = config.col + left_width + 2,
    row = config.row,
    relative = 'editor',
    style = 'minimal',
    border = 'rounded',
  })

  local left_win = vim.api.nvim_open_win(left_buf, true, {
    width = left_width,
    height = config.height,
    col = config.col,
    row = config.row,
    relative = 'editor',
    style = 'minimal',
    border = 'rounded',
  })

  state.left_win = left_win
  state.right_win = right_win

  state.left_buf = left_buf
  state.right_buf = right_buf

  local files = get_files()

  vim.api.nvim_buf_set_lines(state.left_buf, 0, -1, true, files)
  vim.api.nvim_buf_set_lines(state.right_buf, 0, -1, true, { 'diffs will apear here' })

  vim.api.nvim_set_option_value('winhighlight', 'CursorLine:MyPluginCursorLine', { win = left_win })
  vim.api.nvim_set_option_value('cursorline', true, { win = left_win })
  vim.api.nvim_set_option_value('number', true, { win = left_win })
  vim.api.nvim_set_option_value('relativenumber', true, { win = left_win })

  local group = vim.api.nvim_create_augroup(cursor_move_group, { clear = true })
  vim.api.nvim_create_autocmd('CursorMoved', {
    group = group,
    callback = function()
      local row = vim.api.nvim_win_get_cursor(left_win)[1]
      local current_file = files[row]
      local diff = get_file_diff(current_file)
      vim.api.nvim_buf_set_lines(state.right_buf, 0, -1, true, diff and vim.split(diff, '\n') or { 'no changes' })
    end
  })

  disable_insert_mode(left_buf)
  -- disable_insert_mode()
end

local function close_win()
  vim.api.nvim_win_close(state.left_win, true)
  vim.api.nvim_win_close(state.right_win, true)
  vim.o.highlight = nil
  vim.api.nvim_clear_autocmds({ group = cursor_move_group })
end

local function setup()
  vim.keymap.set('n', '<leader>a', open_modal)
  vim.keymap.set('n', 'q', close_win)
  local group = vim.api.nvim_create_augroup('hot_reload', { clear = true })
  vim.api.nvim_create_autocmd('BufWritePost', { group = group, callback = function() vim.cmd('luafile %') end })
  vim.api.nvim_set_hl(0, 'MyPluginCursorLine', { bg = '#2a2a3a' })
end

setup();
