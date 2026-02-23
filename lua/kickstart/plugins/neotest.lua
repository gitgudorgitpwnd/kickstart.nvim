return {
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
          -- Fixed the syntax error here with proper parentheses
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
}
