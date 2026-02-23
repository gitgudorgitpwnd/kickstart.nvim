return {
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
}
