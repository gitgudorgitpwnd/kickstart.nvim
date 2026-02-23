return {
  -- 3. VISUAL DEBUGGING
  -- Hooks into debugpy to provide breakpoints, stepping, and a visual UI.
  {
    'mfussenegger/nvim-dap',
    dependencies = {
      'rcarriga/nvim-dap-ui',
      'nvim-neotest/nvim-nio',
      'mfussenegger/nvim-dap-python',
    },
    config = function()
      local dap = require 'dap'
      local dapui = require 'dapui'

      require('dap-python').setup 'python'

      dapui.setup()
      --[[
      -- NEW: Podman Remote Debugging Configuration
      dap.configurations.python = {
        {
          type = 'python',
          request = 'attach',
          name = 'Podman: Remote Attach',
          connect = {
            port = 5678,
            host = '127.0.0.1',
          },
          pathMappings = {
            {
              localRoot = vim.fn.getcwd(), -- Your project folder on Fedora
              remoteRoot = '/app', -- Where the code sits in the container
            },
          },
        },
      }
      ]]
      -- Automatically open/close the UI when a debug session starts/ends
      dap.listeners.before.attach.dapui_config = function() dapui.open() end
      dap.listeners.before.launch.dapui_config = function() dapui.open() end
      dap.listeners.before.event_terminated.dapui_config = function() dapui.close() end
      dap.listeners.before.event_exited.dapui_config = function() dapui.close() end

      vim.keymap.set('n', '<F5>', dap.continue, { desc = 'Debug: Start/Continue' })
      vim.keymap.set('n', '<F10>', dap.step_over, { desc = 'Debug: Step Over' })
      vim.keymap.set('n', '<F11>', dap.step_into, { desc = 'Debug: Step Into' })
      vim.keymap.set('n', '<leader>db', dap.toggle_breakpoint, { desc = '[D]ebug [B]reakpoint' })
    end,
  },
}
