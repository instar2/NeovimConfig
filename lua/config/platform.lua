local M = {}

function M.is_mac()
  return vim.fn.has("macunix") == 1
end

function M.is_x11()
  return vim.fn.has("unix") == 1
    and not M.is_mac()
    and (vim.env.DISPLAY or "") ~= ""
    and (vim.env.XDG_SESSION_TYPE == "x11" or (vim.env.WAYLAND_DISPLAY or "") == "")
end

function M.setup_path()
  if vim.fn.has("unix") ~= 1 then
    return
  end
  local home = vim.uv.os_homedir()
  local candidates = {}
  if home then
    candidates = { (vim.env.CARGO_HOME or home .. "/.cargo") .. "/bin", home .. "/.local/bin" }
  end
  if M.is_mac() then
    -- Add the native Homebrew prefix only; do not mix Intel and ARM binaries.
    local arm = vim.uv.os_uname().machine == "arm64"
    local prefix = arm and "/opt/homebrew" or "/usr/local"
    candidates[#candidates + 1] = prefix .. "/bin"
    candidates[#candidates + 1] = prefix .. "/sbin"
  end
  local path = vim.env.PATH or ""
  local present = {}
  for entry in path:gmatch("[^:]+") do
    present[entry:gsub("/+$", "")] = true
  end
  for _, dir in ipairs(candidates) do
    if not present[dir] and vim.fn.isdirectory(dir) == 1 then
      -- Preserve activated environments and the user's existing tool precedence.
      path = path == "" and dir or path .. ":" .. dir
      present[dir] = true
    end
  end
  vim.env.PATH = path
end

function M.clipboard_provider()
  if M.is_mac() and vim.fn.executable("pbcopy") == 1 and vim.fn.executable("pbpaste") == 1 then
    return "pbcopy"
  end
  if M.is_x11() then
    if vim.fn.executable("xclip") == 1 then
      return "xclip"
    elseif vim.fn.executable("xsel") == 1 then
      return "xsel"
    end
  end
end

function M.setup()
  M.setup_path()
  -- Set this before any plugin initializes Neovim's clipboard provider.
  -- Keep user overrides; other sessions retain Neovim's automatic detection.
  if vim.g.clipboard == nil then
    vim.g.clipboard = M.clipboard_provider()
  end
end

return M
