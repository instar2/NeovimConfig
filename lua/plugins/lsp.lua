return {
  {
    "mason-org/mason.nvim",
    lazy = false,
    opts = {},
  },
  {
    "mason-org/mason-lspconfig.nvim",
    dependencies = { "mason-org/mason.nvim", "neovim/nvim-lspconfig" },
    opts = { automatic_enable = false, ensure_installed = {} },
  },
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = { "mason-org/mason.nvim" },
    opts = {
      ensure_installed = require("config.tools").packages,
      auto_update = false,
      run_on_start = false,
      integrations = {
        ["mason-lspconfig"] = false,
        ["mason-null-ls"] = false,
        ["mason-nvim-dap"] = false,
      },
    },
    config = function(_, opts)
      require("mason-tool-installer").setup(opts)
      vim.api.nvim_create_user_command("ConfigInstall", function()
        require("mason-tool-installer").check_install(false)
        require("nvim-treesitter").install(require("config.tools").parsers)
      end, { desc = "Install missing language tools and parsers" })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = { "mason-org/mason.nvim", "saghen/blink.cmp" },
    config = function()
      require("config.lsp").setup()
    end,
  },
}
