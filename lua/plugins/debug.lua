return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "nvim-neotest/nvim-nio",
      "mfussenegger/nvim-dap-python",
    },
    keys = {
      -- Leader mappings avoid terminal menu/fullscreen function-key conflicts.
      {
        "<leader>dc",
        function()
          require("dap").continue()
        end,
        desc = "Debug continue/start",
      },
      {
        "<leader>db",
        function()
          require("dap").toggle_breakpoint()
        end,
        desc = "Toggle breakpoint",
      },
      {
        "<leader>dB",
        function()
          vim.ui.input({ prompt = "Breakpoint condition: " }, function(value)
            if value then
              require("dap").set_breakpoint(value)
            end
          end)
        end,
        desc = "Conditional breakpoint",
      },
      {
        "<leader>dn",
        function()
          require("dap").step_over()
        end,
        desc = "Step over",
      },
      {
        "<leader>di",
        function()
          require("dap").step_into()
        end,
        desc = "Step into",
      },
      {
        "<leader>do",
        function()
          require("dap").step_out()
        end,
        desc = "Step out",
      },
      {
        "<leader>dq",
        function()
          require("dap").terminate()
        end,
        desc = "Terminate debugger",
      },
      {
        "<leader>du",
        function()
          require("dapui").toggle()
        end,
        desc = "Toggle debugger UI",
      },
      {
        "<leader>de",
        function()
          require("dapui").eval()
        end,
        mode = { "n", "x" },
        desc = "Evaluate expression",
      },
      {
        "<leader>dr",
        function()
          require("dap").repl.toggle()
        end,
        desc = "Debug console",
      },
    },
    config = function()
      local dap, ui = require("dap"), require("dapui")
      ui.setup()
      dap.listeners.before.attach.user_ui = function()
        ui.open()
      end
      dap.listeners.before.launch.user_ui = function()
        ui.open()
      end
      dap.listeners.before.event_terminated.user_ui = function()
        ui.close()
      end
      dap.listeners.before.event_exited.user_ui = function()
        ui.close()
      end
      dap.adapters.codelldb = { type = "executable", command = "codelldb" }
      for _, ft in ipairs({ "c", "cpp", "rust" }) do
        dap.configurations[ft] = {
          {
            name = "Launch executable",
            type = "codelldb",
            request = "launch",
            program = function()
              local path = vim.fn.input("Executable: ", vim.fn.getcwd() .. "/", "file")
              if path == "" then
                return dap.ABORT
              end
              return vim.fn.fnamemodify(path, ":p")
            end,
            cwd = "${workspaceFolder}",
            stopOnEntry = false,
          },
          {
            name = "Attach to process",
            type = "codelldb",
            request = "attach",
            pid = require("dap.utils").pick_process,
          },
        }
      end
      local python = require("config.python")
      require("dap-python").setup("debugpy-adapter")
      require("dap-python").resolve_python = function()
        return python.resolve()
      end
      dap.configurations.python = {
        {
          name = "Launch current file",
          type = "python",
          request = "launch",
          program = "${file}",
          cwd = function()
            return python.root()
          end,
          pythonPath = function()
            return python.resolve()
          end,
          console = "integratedTerminal",
          justMyCode = true,
        },
        {
          name = "Attach to debugpy (localhost)",
          type = "python",
          request = "attach",
          connect = function()
            return {
              host = "127.0.0.1",
              port = tonumber(vim.fn.input("debugpy port: ", "5678")) or 5678,
            }
          end,
          justMyCode = true,
        },
      }
      vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DiagnosticError" })
      vim.fn.sign_define(
        "DapStopped",
        { text = "▶", texthl = "DiagnosticWarn", linehl = "Visual" }
      )
    end,
  },
}
