if vim.fn.has("nvim-0.12") ~= 1 then
  error("This configuration requires Neovim 0.12 or newer")
end

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

require("config.platform").setup()
require("config.options")
require("config.autocmds")
require("config.keymaps")
require("config.lazy")
