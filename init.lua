local ui = require('lua.ui')
local open, close = ui.open, ui.close

local function setup()
  vim.keymap.set('n', '<leader>a', open)
  vim.keymap.set('n', 'q', close)
  local group = vim.api.nvim_create_augroup('hot_reload', { clear = true })
  vim.api.nvim_create_autocmd('BufWritePost', { group = group, callback = function() vim.cmd('luafile %') end })
  vim.api.nvim_set_hl(0, 'MyPluginCursorLine', { bg = '#2a2a3a' })
end

setup()
