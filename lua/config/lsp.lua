local M = {}

function M.setup()
  local python = require("config.python")
  python.setup()

  vim.lsp.config("*", { capabilities = require("blink.cmp").get_lsp_capabilities() })

  vim.lsp.config("basedpyright", {
    root_dir = function(buf, on_dir)
      on_dir(python.root(buf))
    end,
    before_init = function(_, config)
      config.settings.python = vim.tbl_extend("force", config.settings.python or {}, {
        pythonPath = python.resolve(config.root_dir),
      })
    end,
    settings = {
      basedpyright = {
        disableOrganizeImports = true,
        analysis = { typeCheckingMode = "standard" },
      },
    },
  })

  vim.lsp.config("ruff", {
    on_attach = function(client)
      client.server_capabilities.hoverProvider = false
    end,
  })

  vim.lsp.config("clangd", {
    cmd = { "clangd", "--background-index", "--clang-tidy" },
    filetypes = { "c", "cpp", "objc", "objcpp", "cuda" },
  })

  vim.lsp.config("rust_analyzer", {
    settings = { ["rust-analyzer"] = { check = { command = "clippy" } } },
  })

  vim.lsp.config("eslint", { settings = { format = false, codeActionOnSave = { enable = false } } })

  vim.lsp.config("marksman", { filetypes = { "markdown" } })

  vim.lsp.config("lua_ls", {
    on_init = function(client)
      local root = client.root_dir
      if
        root and (vim.uv.fs_stat(root .. "/.luarc.json") or vim.uv.fs_stat(root .. "/.luarc.jsonc"))
      then
        return
      end
      client.settings.Lua = vim.tbl_deep_extend("force", client.settings.Lua or {}, {
        runtime = { version = "LuaJIT" },
        workspace = { checkThirdParty = false, library = { vim.env.VIMRUNTIME } },
      })
      client:notify("workspace/didChangeConfiguration", { settings = client.settings })
    end,
    settings = { Lua = {} },
  })

  vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("UserLsp", { clear = true }),
    callback = function(ev)
      local function map(key, fn, desc)
        vim.keymap.set("n", key, fn, { buffer = ev.buf, desc = desc })
      end
      map("gd", function()
        Snacks.picker.lsp_definitions()
      end, "Go to definition")
      map("gD", vim.lsp.buf.declaration, "Go to declaration")
      map("<leader>cr", vim.lsp.buf.rename, "Rename symbol")
      map("<leader>ca", vim.lsp.buf.code_action, "Code actions")
      -- K, grn, gra, grr, gri, grt and diagnostic motions keep their native behavior.
    end,
  })

  vim.lsp.enable(require("config.tools").servers)
end

return M
