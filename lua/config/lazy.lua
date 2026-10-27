local path = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(path) then
  local out = vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "--branch=stable",
    "https://github.com/folke/lazy.nvim.git",
    path,
  })
  if vim.v.shell_error ~= 0 then
    error("Could not install lazy.nvim:\n" .. out)
  end
end
vim.opt.rtp:prepend(path)
require("lazy").setup({
  spec = { { import = "plugins" } },
  defaults = { lazy = false, version = false },
  rocks = { enabled = false },
  checker = { enabled = false },
  change_detection = { notify = false },
  install = { colorscheme = { "catppuccin-nvim", "habamax" } },
})
