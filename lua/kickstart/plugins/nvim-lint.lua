return {
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
}
