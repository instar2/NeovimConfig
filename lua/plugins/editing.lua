return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      local ts = require("nvim-treesitter")
      ts.setup({})
      require("config.indent").setup()
      -- Missing parsers are installed explicitly by :ConfigInstall or :TSInstall.
      -- Opening the editor never needs a network connection.
      local group = vim.api.nvim_create_augroup("UserTreesitter", { clear = true })
      vim.api.nvim_create_autocmd("FileType", {
        group = group,
        callback = function(ev)
          if vim.bo[ev.buf].filetype == "bigfile" then
            return
          end
          local lang = vim.treesitter.language.get_lang(vim.bo[ev.buf].filetype)
          local ok, parser = pcall(vim.treesitter.get_parser, ev.buf, lang)
          if ok and parser then
            vim.treesitter.start(ev.buf, lang)
            vim.wo[0][0].foldmethod = "expr"
            vim.wo[0][0].foldexpr = "v:lua.vim.treesitter.foldexpr()"
          end
          require("config.indent").attach(ev.buf)
        end,
      })
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
      require("nvim-treesitter-textobjects").setup({
        select = { lookahead = true },
        move = { set_jumps = true },
      })
      for key, capture in pairs({
        af = "@function.outer",
        ["if"] = "@function.inner",
        ac = "@class.outer",
        ic = "@class.inner",
        aa = "@parameter.outer",
        ia = "@parameter.inner",
      }) do
        vim.keymap.set({ "x", "o" }, key, function()
          require("nvim-treesitter-textobjects.select").select_textobject(capture, "textobjects")
        end, { desc = capture })
      end
      -- Use ]f/[f to avoid overriding filetype-provided ]m/[m mappings.
      for key, method in pairs({
        ["]f"] = "goto_next_start",
        ["[f"] = "goto_previous_start",
        ["]F"] = "goto_next_end",
        ["[F"] = "goto_previous_end",
      }) do
        vim.keymap.set({ "n", "x", "o" }, key, function()
          require("nvim-treesitter-textobjects.move")[method]("@function.outer", "textobjects")
        end, { desc = method .. " function" })
      end
      vim.keymap.set("n", "<leader>c>", function()
        require("nvim-treesitter-textobjects.swap").swap_next("@parameter.inner")
      end, { desc = "Swap parameter forward" })
      vim.keymap.set("n", "<leader>c<", function()
        require("nvim-treesitter-textobjects.swap").swap_previous("@parameter.inner")
      end, { desc = "Swap parameter backward" })
    end,
  },
  { "windwp/nvim-ts-autotag", event = { "BufReadPre", "BufNewFile" }, opts = {} },
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = "markdown",
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-mini/mini.nvim" },
    opts = { latex = { enabled = false } },
    keys = {
      { "<leader>um", "<cmd>RenderMarkdown toggle<CR>", desc = "Toggle Markdown rendering" },
    },
  },
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      on_attach = function(buf)
        local gs = require("gitsigns")
        local function map(key, fn, desc)
          vim.keymap.set("n", key, fn, { buffer = buf, desc = desc })
        end
        for key, direction in pairs({ ["]c"] = "next", ["[c"] = "prev" }) do
          map(key, function()
            if vim.wo.diff then
              vim.cmd.normal({ key, bang = true })
            else
              gs.nav_hunk(direction)
            end
          end, direction .. " Git hunk")
        end
        map("<leader>gh", gs.preview_hunk, "Preview hunk")
        map("<leader>ga", gs.stage_hunk, "Stage/unstage hunk")
        map("<leader>gr", gs.reset_hunk, "Reset hunk")
        map("<leader>gb", function()
          gs.blame_line({ full = true })
        end, "Blame line")
        map("<leader>gd", gs.diffthis, "Diff file")
        vim.keymap.set("x", "<leader>ga", function()
          gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end, { buffer = buf, desc = "Stage selected lines" })
      end,
    },
  },
}
