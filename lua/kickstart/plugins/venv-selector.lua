return {
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
}
