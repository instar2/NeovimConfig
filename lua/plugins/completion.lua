return {
  {
    "saghen/blink.cmp",
    version = "1.*",
    event = "InsertEnter",
    dependencies = { "rafamadriz/friendly-snippets" },
    opts = {
      keymap = {
        preset = "default",
        ["<C-space>"] = false,
        ["<C-j>"] = { "show", "show_documentation", "hide_documentation" },
      },
      completion = {
        documentation = { auto_show = true, auto_show_delay_ms = 300 },
        list = { selection = { preselect = false, auto_insert = false } },
      },
      sources = { default = { "lsp", "path", "snippets", "buffer" } },
      signature = { enabled = true },
      fuzzy = { implementation = "prefer_rust_with_warning" },
      cmdline = { enabled = false },
    },
  },
}
