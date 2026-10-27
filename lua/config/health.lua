local M = {}

local function executable(name, advice)
  if vim.fn.executable(name) == 1 then
    vim.health.ok(name .. ": " .. vim.fn.exepath(name))
    return true
  end
  vim.health.warn(name .. " is missing", advice)
  return false
end

function M.check()
  local platform = require("config.platform")
  vim.health.start("Neovim configuration")
  if vim.fn.has("nvim-0.12") == 1 then
    vim.health.ok("Neovim 0.12 or newer")
  else
    vim.health.error(
      "Neovim 0.12 or newer is required (including by the pinned Tree-sitter plugin)"
    )
  end
  local os = vim.uv.os_uname()
  vim.health.info(os.sysname .. " / " .. os.machine)
  vim.health.info("See README.md for macOS and Kali installation steps")

  vim.health.start("System dependencies")
  for _, name in ipairs({ "git", "curl", "tar", "unzip", "node", "npm", "python3", "rg", "make" }) do
    executable(name, "Install the system dependencies listed in README.md")
  end
  if vim.fn.executable("fd") == 0 and vim.fn.executable("fdfind") == 0 then
    vim.health.warn("fd/fdfind is missing", "Install fd (Homebrew) or fd-find (apt)")
  else
    vim.health.ok("fd/fdfind is available")
  end
  if
    vim.fn.executable("cc") == 0
    and vim.fn.executable("gcc") == 0
    and vim.fn.executable("clang") == 0
  then
    vim.health.warn(
      "A C compiler is required to build parsers",
      "Install Xcode command line tools or build-essential"
    )
  else
    vim.health.ok("C compiler is available")
  end
  if
    executable("tree-sitter", "Install tree-sitter-cli >= 0.26.1 using Homebrew or Cargo, not npm")
  then
    local result = vim.system({ "tree-sitter", "--version" }, { text = true }):wait(3000)
    local version = (result.stdout or ""):match("(%d+%.%d+%.%d+)")
    if result.code == 0 and version and vim.version.ge(version, "0.26.1") then
      vim.health.ok("Tree-sitter CLI " .. version)
    else
      vim.health.warn(
        "Could not confirm Tree-sitter CLI >= 0.26.1",
        "Update tree-sitter-cli before :ConfigInstall"
      )
    end
  end
  for _, name in ipairs({ "cargo", "rustc", "rustfmt", "rust-analyzer" }) do
    executable(
      name,
      "Install Rust with rustup, then: rustup component add rustfmt clippy rust-analyzer"
    )
  end

  vim.health.start("Clipboard")
  if vim.g.clipboard ~= nil then
    vim.health.info("Clipboard override: " .. vim.inspect(vim.g.clipboard))
  elseif platform.is_mac() then
    vim.health.warn("pbcopy/pbpaste is unavailable", "Check the macOS system PATH")
  elseif platform.is_x11() then
    vim.health.warn("No X11 clipboard tool found", "sudo apt install xclip; then restart Neovim")
  else
    vim.health.info(
      "Using Neovim clipboard auto-detection (headless, SSH, or another display server)"
    )
  end
  vim.health.info(
    "Use :checkhealth vim.provider to test the provider; VM host sharing also needs guest integration"
  )
  vim.health.info("Use :checkhealth mason and :ConfigInstall for language tools and debuggers")
end

return M
