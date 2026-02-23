--=============================================================================
-- lua/custom/plugins/data-science.lua
-- Data Science & Machine Learning Toolchain
--
-- PURPOSE:
-- This module creates a Jupyter-notebook-like experience inside Neovim for
-- iterative ML development. It isolates these heavy dependencies from the
-- main `init.lua` to keep the core SaaS environment lightweight.
--
-- CAPABILITIES:
-- 1. Interactive Kernel (Molten): Run Python code cells and see output inline.
-- 2. Visualization (Image.nvim): Render Matplotlib/Seaborn plots in the buffer.
-- 3. Data Inspection (Rainbow CSV): Colorize CSV/TSV files for readability.
-- 4. REPL Integration (Vim-Slime): Send code blocks to a terminal (IPython).
--=============================================================================

return {
  -----------------------------------------------------------------------------
  -- 1. DATA INSPECTION
  -----------------------------------------------------------------------------
  {
    'cameron-wags/rainbow_csv.nvim',
    config = true,
    ft = { 'csv', 'tsv', 'dat' }, -- Lazy-load only on data files
    cmd = { 'RainbowDelim', 'RainbowMultiDelim' },
  },

  -----------------------------------------------------------------------------
  -- 2. INTERACTIVE COMPUTING (Jupyter Integration)
  -----------------------------------------------------------------------------
  -- Molten allows you to execute code cells (defined by # %%) and see the
  -- results (text or images) in a floating window, similar to VS Code or JupyterLab.
  {
    'benlubas/molten-nvim',
    version = '^1.0.0', -- Pin version to avoid breaking changes
    dependencies = { '3rd/image.nvim' }, -- Required for plotting support
    build = ':UpdateRemotePlugins',
    init = function()
      -- Configuration
      vim.g.molten_image_provider = 'image.nvim'
      vim.g.molten_output_win_max_height = 20
      vim.g.molten_auto_open_output = false -- Don't auto-show; use keymaps
      vim.g.molten_wrap_output = true
      vim.g.molten_virt_text_output = true
      vim.g.molten_virt_lines_off_by_1 = true

      -- Keymaps
      -- <leader>mi: Initialize the kernel (start the REPL background process)
      vim.keymap.set('n', '<leader>mi', ':MoltenInit<CR>', { desc = '[M]olten [I]nit', silent = true })

      -- <leader>me: Evaluate the operator (e.g., motion or text object)
      vim.keymap.set('n', '<leader>me', ':MoltenEvaluateOperator<CR>', { desc = '[M]olten [E]valuate Operator', silent = true })

      -- <leader>ml: Evaluate the current line
      vim.keymap.set('n', '<leader>ml', ':MoltenEvaluateLine<CR>', { desc = '[M]olten Evaluate [L]ine', silent = true })

      -- <leader>me (Visual): Evaluate the visual selection
      vim.keymap.set('v', '<leader>me', ':<C-u>MoltenEvaluateVisual<CR>gv', { desc = '[M]olten [E]valuate Visual', silent = true })

      -- <leader>mc: Re-evaluate the current cell (defined by # %% markers)
      vim.keymap.set('n', '<leader>mc', ':MoltenReevaluateCell<CR>', { desc = '[M]olten Re-evaluate [C]ell', silent = true })

      -- <leader>md: Delete the output of the current cell
      vim.keymap.set('n', '<leader>md', ':MoltenDelete<CR>', { desc = '[M]olten [D]elete Output', silent = true })

      -- <leader>mo: Show the output window for the current cell
      vim.keymap.set('n', '<leader>mo', ':MoltenShowOutput<CR>', { desc = '[M]olten Show [O]utput', silent = true })
    end,
  },

  -----------------------------------------------------------------------------
  -- 3. VISUALIZATION
  -----------------------------------------------------------------------------
  -- Enables rendering of images (PNG/JPG) within the Neovim buffer.
  -- Critical for viewing plots from Matplotlib/Seaborn via Molten.
  -- NOTE: Requires a terminal emulator with image protocol support
  -- (e.g., Kitty, WezTerm, Konsole, or iTerm2).
  {
    '3rd/image.nvim',
    opts = {
      backend = 'kitty', -- Change to "ueberzug" or "sixel" if not using Kitty/WezTerm
      integrations = {
        markdown = {
          enabled = true,
          clear_in_insert_mode = false,
          download_remote_images = true,
          only_render_image_at_cursor = false,
          filetypes = { 'markdown', 'vimwiki', 'quarto' },
        },
      },
      max_width = 100,
      max_height = 12,
      max_width_window_percentage = math.huge,
      max_height_window_percentage = math.huge,
      window_overlap_clear_enabled = false,
      window_overlap_clear_ft_ignore = { 'cmp_menu', 'cmp_docs', '' },
    },
  },

  -----------------------------------------------------------------------------
  -- 4. REPL INTEGRATION (Slime)
  -----------------------------------------------------------------------------
  -- Send code regions to a terminal buffer.
  -- Ideal for "classic" data science workflows using IPython.
  {
    'jpalardy/vim-slime',
    init = function()
      -- Suggested config for Slime + ML (Tmux target)
      -- This assumes you are running Neovim inside Tmux.
      -- If not, change "tmux" to "neovim" to target a terminal split.
      vim.g.slime_target = 'tmux'

      -- Optimized for IPython (ensures correct indentation pasting)
      vim.g.slime_python_ipython = 1

      -- Fix potential race conditions when pasting large blocks
      vim.g.slime_dispatch_ipython_pause = 100

      -- Fix paste issues in some environments
      vim.g.slime_no_mappings = 1
    end,
    -- Custom keymaps for Slime
    config = function()
      vim.keymap.set('x', '<leader>rs', '<Plug>SlimeRegionSend', { desc = '[S]lime Send Region' })
      vim.keymap.set('n', '<leader>rs', '<Plug>SlimeParagraphSend', { desc = '[S]lime Send Paragraph' })
    end,
  },
}
