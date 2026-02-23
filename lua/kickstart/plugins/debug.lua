-- nvim-dap.lua
-- Unified Debugging Configuration (Python & Go)

return {
  'mfussenegger/nvim-dap',
  dependencies = {
    -- Creates a beautiful debugger UI
    'rcarriga/nvim-dap-ui',
    -- Required dependency for nvim-dap-ui
    'nvim-neotest/nvim-nio',
    -- Installs the debug adapters for you via Mason
    'williamboman/mason.nvim',
    'jay-babu/mason-nvim-dap.nvim',
    -- Language-specific configurations
    'mfussenegger/nvim-dap-python',
    'leoluz/nvim-dap-go',
  },
  keys = {
    -- Basic debugging keymaps
    { '<F5>', function() require('dap').continue() end, desc = 'Debug: Start/Continue' },
    { '<F1>', function() require('dap').step_into() end, desc = 'Debug: Step Into' },
    { '<F2>', function() require('dap').step_over() end, desc = 'Debug: Step Over' },
    { '<F3>', function() require('dap').step_out() end, desc = 'Debug: Step Out' },
    { '<F7>', function() require('dapui').toggle() end, desc = 'Debug: See last session result' },
    { '<leader>db', function() require('dap').toggle_breakpoint() end, desc = 'Debug: [D]ebug [B]reakpoint' },
    { '<leader>dB', function() require('dap').set_breakpoint(vim.fn.input 'Breakpoint condition: ') end, desc = 'Debug: Set Breakpoint' },
  },
  config = function()
    local dap = require 'dap'
    local dapui = require 'dapui'

    require('mason-nvim-dap').setup {
      -- Makes a best effort to setup the various debuggers with
      -- reasonable debug configurations
      automatic_installation = true,

      -- Handlers for specific adapters
      handlers = {},

      -- Ensure these are installed by Mason
      ensure_installed = {
        'delve', -- Go debugger
        'debugpy', -- Python debugger
      },
    }

    -- Dap UI setup
    -- For more information, see |:help nvim-dap-ui|
    dapui.setup {
      icons = { expanded = '▾', collapsed = '▸', current_frame = '*' },
      controls = {
        icons = {
          pause = '⏸',
          play = '▶',
          step_into = '⏎',
          step_over = '⏭',
          step_out = '⏮',
          step_back = 'b',
          run_last = '▶▶',
          terminate = '⏹',
          disconnect = '⏏',
        },
      },
    }

    -- Set up Language-Specific Helpers
    -- Python: This will use the debugpy installed by Mason
    require('dap-python').setup 'python'

    -- Go: This handles delving into Go binaries
    require('dap-go').setup {
      delve = {
        -- On Windows delve must be run attached or it crashes.
        detached = vim.fn.has 'win32' == 0,
      },
    }

    -- Automatic UI behavior: open on start, close on exit
    dap.listeners.after.event_initialized['dapui_config'] = dapui.open
    dap.listeners.before.event_terminated['dapui_config'] = dapui.close
    dap.listeners.before.event_exited['dapui_config'] = dapui.close
  end,
}
