-- Neo-tree is a Neovim plugin to browse the file system
-- https://github.com/nvim-neo-tree/neo-tree.nvim

return {
  'nvim-neo-tree/neo-tree.nvim',
  version = '*',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-tree/nvim-web-devicons', -- not strictly required, but recommended
    'MunifTanjim/nui.nvim',
  },
  lazy = false,
  keys = {
    { '\\', ':Neotree reveal<CR>', desc = 'NeoTree reveal', silent = true },
  },
  opts = {
    filesystem = {
      window = {
        mappings = {
          ['\\'] = 'close_window',
        },
      },
    },
    window = {
      mappings = {
        ['a'] = 'none',
        ['d'] = 'none',
        ['r'] = 'none',
        ['c'] = 'none',
        ['p'] = 'none',
        ['m'] = 'none',
        ['A'] = 'add',
        ['D'] = 'delete',
        ['R'] = 'rename',
        ['C'] = 'copy',
        ['P'] = 'paste_from_clipboard',
        ['M'] = 'move',
      },
    },
  },
}
