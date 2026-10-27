return {
  {
    "stevearc/conform.nvim",
    event = { "BufReadPre", "BufNewFile" },
    cmd = {
      "ConformInfo",
      "Format",
      "Fix",
      "OrganizeImports",
      "SaveActionsToggle",
      "SaveActionsToggleBuffer",
    },
    keys = {
      { "<leader>cf", "<cmd>Format<CR>", desc = "Format buffer" },
      { "<leader>cx", "<cmd>Fix<CR>", desc = "Apply lint fixes" },
      { "<leader>co", "<cmd>OrganizeImports<CR>", desc = "Organize imports" },
      { "<leader>uf", "<cmd>SaveActionsToggle<CR>", desc = "Toggle save actions globally" },
      { "<leader>uF", "<cmd>SaveActionsToggleBuffer<CR>", desc = "Toggle save actions for buffer" },
    },
    config = function()
      local function ruff_command(_, ctx)
        local root =
          vim.fs.root(ctx.filename, { "pyproject.toml", "ruff.toml", ".ruff.toml", ".git" })
        if root and vim.fn.executable(root .. "/.venv/bin/ruff") == 1 then
          return root .. "/.venv/bin/ruff"
        end
        if vim.env.VIRTUAL_ENV and vim.fn.executable(vim.env.VIRTUAL_ENV .. "/bin/ruff") == 1 then
          return vim.env.VIRTUAL_ENV .. "/bin/ruff"
        end
        return "ruff"
      end
      require("conform").setup({
        formatters_by_ft = {
          python = { "ruff_format" },
          c = { "clang_format" },
          cpp = { "clang_format" },
          rust = { "rustfmt" },
          lua = { "stylua" },
          javascript = { "prettier" },
          javascriptreact = { "prettier" },
          typescript = { "prettier" },
          typescriptreact = { "prettier" },
          html = { "prettier" },
          css = { "prettier" },
          scss = { "prettier" },
          markdown = { "prettier" },
          json = { "prettier" },
          jsonc = { "prettier" },
          yaml = { "prettier" },
        },
        default_format_opts = { lsp_format = "never", timeout_ms = 2000 },
        formatters = {
          ruff_fix = { command = ruff_command, append_args = { "--no-unsafe-fixes" } },
          ruff_organize_imports = { command = ruff_command, append_args = { "--no-unsafe-fixes" } },
          ruff_format = { command = ruff_command },
        },
      })
      require("config.save").setup()
    end,
  },
}
