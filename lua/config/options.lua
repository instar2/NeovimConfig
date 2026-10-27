local opt = vim.opt
opt.number = true
opt.relativenumber = true
opt.mouse = "a"
-- Native macOS or X11 clipboard, selected before plugins by config.platform.
opt.clipboard = "unnamedplus"
opt.termguicolors = true
-- Keep a dark background regardless of the terminal theme.
opt.background = "dark"
opt.signcolumn = "yes"
opt.cursorline = true
opt.laststatus = 3
opt.showmode = false
opt.winborder = "rounded"
opt.wrap = false
opt.breakindent = true
opt.scrolloff = 6
opt.sidescrolloff = 8
opt.splitright = true
opt.splitbelow = true
opt.splitkeep = "screen"
opt.ignorecase = true
opt.smartcase = true
opt.inccommand = "split"
opt.undofile = true
opt.updatetime = 250
opt.timeoutlen = 400
-- Allow for delayed terminal key sequences in the VM.
opt.ttimeoutlen = 50
opt.confirm = true
opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.softtabstop = -1
opt.list = true
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
opt.fillchars:append({ eob = " " })
opt.completeopt = { "menu", "menuone", "noselect" }
opt.foldlevel = 99
opt.foldlevelstart = 99
opt.spelllang = { "en_gb", "en_us" }

vim.diagnostic.config({
  severity_sort = true,
  update_in_insert = false,
  virtual_text = { spacing = 2, source = "if_many" },
  float = { source = true },
  underline = true,
})
