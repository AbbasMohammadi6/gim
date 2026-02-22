local ui = require('gim.ui')
local open, close = ui.open, ui.close

M = {}

function M.setup()
  vim.keymap.set('n', '<leader>a', open)
  vim.keymap.set('n', 'q', close)
  local group = vim.api.nvim_create_augroup('hot_reload', { clear = true })
  vim.api.nvim_set_hl(0, 'MyPluginCursorLine', { bg = '#2a2a3a' })
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = group,
    pattern = "*/lua/gim/*.lua",
    callback = function()
      for name, _ in pairs(package.loaded) do
        if name:match("^gim") then
          package.loaded[name] = nil
        end
      end
      require("gim").setup()
    end,
  })
end

return M
