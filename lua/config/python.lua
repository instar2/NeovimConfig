local M = { overrides = {} }

function M.root(buf)
  return vim.fs.root(buf or 0, {
    "pyrightconfig.json",
    "pyproject.toml",
    "setup.py",
    "setup.cfg",
    "requirements.txt",
    "Pipfile",
    ".git",
  }) or vim.fn.getcwd()
end

function M.resolve(root)
  root = root or M.root()
  if M.overrides[root] then
    return M.overrides[root]
  end
  local candidates = {}
  if vim.env.VIRTUAL_ENV then
    candidates[#candidates + 1] = vim.env.VIRTUAL_ENV .. "/bin/python"
  end
  vim.list_extend(candidates, { root .. "/.venv/bin/python", root .. "/venv/bin/python" })
  candidates[#candidates + 1] = vim.fn.exepath("python3")
  for _, path in ipairs(candidates) do
    if vim.fn.executable(path) == 1 then
      return path
    end
  end
  return "python3"
end

function M.setup()
  vim.api.nvim_create_user_command("PythonPath", function(args)
    local path = vim.fn.fnamemodify(vim.fn.expand(args.args), ":p")
    if vim.fn.executable(path) ~= 1 then
      vim.notify("Not an executable Python interpreter: " .. path, vim.log.levels.ERROR)
      return
    end
    local root = M.root()
    M.overrides[root] = path
    for _, client in ipairs(vim.lsp.get_clients({ name = "basedpyright" })) do
      if client.root_dir == root then
        client.settings.python =
          vim.tbl_extend("force", client.settings.python or {}, { pythonPath = path })
        client:notify("workspace/didChangeConfiguration", { settings = client.settings })
      end
    end
    vim.notify("Python for " .. root .. ": " .. path)
  end, { nargs = 1, complete = "file", desc = "Set the current project's Python interpreter" })
end

return M
