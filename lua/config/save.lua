local M = {}
local web = { javascript = true, javascriptreact = true, typescript = true, typescriptreact = true }

local function warn(message)
  vim.schedule(function()
    vim.notify(message, vim.log.levels.WARN, { title = "Save actions" })
  end)
end

function M.enabled(buf)
  return vim.g.save_actions ~= false and vim.b[buf].save_actions ~= false
end

function M.format(buf, formatters, timeout)
  local err
  require("conform").format({
    bufnr = buf,
    async = false,
    timeout_ms = timeout or 2000,
    lsp_format = "never",
    formatters = formatters,
  }, function(e)
    err = e
  end)
  return not err
end

-- Only apply returned edits. Executing server commands here could cause edits
-- after a timeout and race the write; explicit interactive actions still allow them.
function M.imports(buf, timeout)
  local ft = vim.bo[buf].filetype
  if ft == "python" then
    return M.format(buf, { "ruff_organize_imports" }, timeout)
  end
  if not web[ft] then
    return true
  end
  local client = vim.lsp.get_clients({ bufnr = buf, name = "ts_ls" })[1]
  if not client then
    return true
  end
  local tick = vim.api.nvim_buf_get_changedtick(buf)
  local result, err = client:request_sync("textDocument/codeAction", {
    textDocument = { uri = vim.uri_from_bufnr(buf) },
    range = { start = { line = 0, character = 0 }, ["end"] = { line = 0, character = 0 } },
    context = { diagnostics = {}, only = { "source.organizeImports.ts" }, triggerKind = 1 },
  }, timeout or 1500, buf)
  if not result or result.err then
    warn(
      "Import organization failed: "
        .. tostring(err or (result and result.err and result.err.message) or "empty response")
    )
    return false
  end
  if vim.api.nvim_buf_get_changedtick(buf) ~= tick then
    warn("Buffer changed while organizing imports; skipped stale edits")
    return false
  end
  for _, action in ipairs(result.result or {}) do
    if not action.disabled and action.edit then
      vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding)
      return true
    end
  end
  return true
end

function M.run(buf)
  if
    not M.enabled(buf)
    or vim.bo[buf].buftype ~= ""
    or not vim.bo[buf].modifiable
    or vim.bo[buf].filetype == "bigfile"
  then
    return
  end
  if vim.bo[buf].filetype == "python" then
    -- A single Conform call gives the whole chain one timeout budget.
    M.format(buf, { "ruff_organize_imports", "ruff_format" }, 2500)
  else
    -- Rustfmt retains its import ordering; other languages only run their formatter.
    M.format(buf, nil, 2500)
  end
end

function M.setup()
  local commands = {
    Format = function()
      M.format(vim.api.nvim_get_current_buf())
    end,
    OrganizeImports = function()
      M.imports(vim.api.nvim_get_current_buf())
    end,
    Fix = function()
      if vim.bo.filetype == "python" then
        M.format(vim.api.nvim_get_current_buf(), { "ruff_fix" })
      else
        vim.lsp.buf.code_action({
          context = { only = { "source.fixAll.eslint" }, diagnostics = {} },
          apply = true,
        })
      end
    end,
    SaveActionsToggle = function()
      vim.g.save_actions = not (vim.g.save_actions ~= false)
      vim.notify("Automatic save actions: " .. (vim.g.save_actions and "on" or "off"))
    end,
    SaveActionsToggleBuffer = function()
      vim.b.save_actions = not (vim.b.save_actions ~= false)
      vim.notify("Buffer save actions: " .. (vim.b.save_actions and "on" or "off"))
    end,
  }
  for name, fn in pairs(commands) do
    vim.api.nvim_create_user_command(name, fn, { desc = name })
  end
  vim.api.nvim_create_autocmd("BufWritePre", {
    group = vim.api.nvim_create_augroup("UserSaveActions", { clear = true }),
    callback = function(ev)
      local ok, err = pcall(M.run, ev.buf)
      if not ok then
        warn("Saved without completing automatic actions: " .. tostring(err))
      end
    end,
  })
end

return M
