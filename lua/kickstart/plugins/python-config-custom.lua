return {

  -- =====================================================================
  -- ================= START PYTHON IDE CONFIGURATION ====================
  -- =====================================================================

  -- 1. VIRTUAL ENVIRONMENT SELECTOR
  -- Automatically discovers and applies Python virtual environments.
  -- Keymap: <Space> vs to open the picker.
  {
    'linux-cultist/venv-selector.nvim',
    dependencies = {
      'neovim/nvim-lspconfig',
      'nvim-telescope/telescope.nvim',
      'nvim-lua/plenary.nvim',
    },
    -- branch = 'regexp', -- This causes error.
    event = 'VeryLazy',
    opts = {},
    keys = {
      { '<leader>vs', '<cmd>VenvSelect<cr>', desc = '[V]env [S]elect' },
    },
  },

  --[[
  -- 2. BACKGROUND LINTING
  -- Runs Ruff in the background to catch logic errors and unused variables.
  {
    'mfussenegger/nvim-lint',
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      local lint = require 'lint'

      -- Tell nvim-lint to use Ruff for Python files
      lint.linters_by_ft = {
        python = {
          --'ruff',
          'pylint',
        },
      }

      -- Automatically trigger linting when you save or leave insert mode
      local lint_augroup = vim.api.nvim_create_augroup('lint', { clear = true })
      vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'InsertLeave' }, {
        group = lint_augroup,
        callback = function() lint.try_lint() end,
      })
    end,
  },

  ]]
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

  -- 4. INTERACTIVE TEST RUNNER
  -- Visual test runner for pytest/unittest that shows results in the gutter.
  {
    'nvim-neotest/neotest',
    dependencies = {
      'nvim-neotest/nvim-nio',
      'nvim-lua/plenary.nvim',
      'antoinemadec/FixCursorHold.nvim',
      'nvim-treesitter/nvim-treesitter',
      'nvim-neotest/neotest-python',
    },
    config = function()
      require('neotest').setup {
        adapters = {
          require 'neotest-python' {
            dap = { justMyCode = false },
          },
        },
      }

      vim.keymap.set('n', '<leader>tr', function() require('neotest').run.run() end, { desc = '[T]est [R]un nearest' })
      vim.keymap.set('n', '<leader>tf', function() require('neotest').run.run(vim.fn.expand '%') end, { desc = '[T]est [F]ile' })
      vim.keymap.set('n', '<leader>ts', function() require('neotest').summary.toggle() end, { desc = '[T]est [S]ummary' })
    end,
  },

  -- 5. INTERACTIVE EXECUTION (REPL)
  -- Sends chunks of code from your Neovim buffer to a separate terminal pane.
  {
    'jpalardy/vim-slime',
    init = function()
      vim.g.slime_target = 'neovim'
      vim.g.slime_bracketed_paste = 1
      vim.g.slime_python_ipython = 1
    end,
    config = function()
      vim.keymap.set('n', '<leader>rr', '<Plug>SlimeParagraphSend', { desc = '[R]EPL Send [R]egion' })
      vim.keymap.set('v', '<leader>rr', '<Plug>SlimeRegionSend', { desc = '[R]EPL Send [R]egion' })
      vim.keymap.set('n', '<leader>rc', '<cmd>SlimeConfig<cr>', { desc = '[R]EPL [C]onfig' })
    end,
  },

  -- =====================================================================
  -- ================== END PYTHON IDE CONFIGURATION =====================
  -- =====================================================================
}
