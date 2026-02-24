--=============================================================================
-- init-monolith.lua
-- Metadata-Driven, Comment-Heavy, Beginner-Friendly Neovim Configuration
--
-- WHAT THIS FILE IS
-- -----------------
-- This is a monolithic (single-file) version of a Kickstart-based setup.
-- It preserves the same behavior from:
--   * init.lua
--   * kickstart/plugins/*.lua (the uploaded companion plugin files)
-- while making the configuration easier to audit and toggle from one place.
--
-- WHY THIS FILE EXISTS
-- --------------------
-- A setup that is:
--   1) config-driven
--   2) modular in design (even inside one file)
--   3) scalable as the plugin count grows
--   4) understandable to a beginner
--
-- This file follows that design by:
--   * keeping a single feature switchboard at the top
--   * keeping language tooling in a metadata registry
--   * compiling metadata into plugin configs automatically
--   * separating "core plugins" from "optional plugin vault" specs
--   * validating feature combinations (to prevent invalid states)
--   * preserving an optional future custom plugin import hook
--=============================================================================

--=============================================================================
-- 1. MASTER SWITCHBOARD (FEATURE FLAGS)
--=============================================================================
-- This is the only section most users need to edit.
--
-- RULE OF THUMB
-- -------------
-- `true`  = include plugin/config
-- `false` = completely exclude plugin/config (and any related wiring where safe)
--
-- The `validation` section below prevents invalid combinations, such as enabling
-- Molten while disabling image.nvim (Molten expects image.nvim in the setup).
--=============================================================================
local FEATURES = {
  -- Individual plugin toggles (primary control plane)
  plugins = {
    -- Editor Enhancements
    autopairs = true, -- windwp/nvim-autopairs
    autotag = true, -- windwp/nvim-ts-autotag
    indent_line = true, -- lukas-reineke/indent-blankline.nvim

    -- Navigation / Git
    neo_tree = true, -- nvim-neo-tree/neo-tree.nvim
    gitsigns = true, -- lewis6991/gitsigns.nvim (signs + keymaps)

    -- Dev Tools (Python/general)
    dap = true, -- mfussenegger/nvim-dap
    neotest = true, -- nvim-neotest/neotest
    venv_selector = true, -- linux-cultist/venv-selector.nvim
    schemastore = true, -- b0o/SchemaStore.nvim (JSON/YAML schema enrichment)

    -- Data Science Toolchain (from data-science.lua)
    rainbow_csv = true, -- cameron-wags/rainbow_csv.nvim
    molten = true, -- benlubas/molten-nvim
    image_nvim = true, -- 3rd/image.nvim (Molten plot/image rendering)
    vim_slime = true, -- jpalardy/vim-slime
  },

  -- Optional imports for future extensibility.
  -- KEEP THIS FALSE while migrating from old modular setup unless
  -- removed any duplicate plugin specs (especially custom/plugins/data-science.lua).
  imports = {
    custom_plugins = false, -- if true, adds `{ import = 'custom.plugins' }` when the folder exists
  },

  -- Validation behavior for feature combinations
  validation = {
    strict = true, -- true = raise an error for invalid combinations
  },
}

-- Ordered list of optional plugins.
-- We keep this separate from FEATURES.plugins so plugin assembly is deterministic.
-- (Iterating `pairs()` is NOT ordered in Lua.)
local OPTIONAL_PLUGIN_ORDER = {
  -- Match the spirit of original modular order, then add gitsigns/schemastore
  'indent_line',
  'autopairs',
  'neo_tree',
  'venv_selector',
  'dap',
  'neotest',
  'autotag',
  'gitsigns',
  'schemastore',

  -- Data science bundle
  'rainbow_csv',
  'molten',
  'image_nvim',
  'vim_slime',
}

-- Convenience alias. Using a separate table makes it easy to add future profile
-- logic later (e.g., "full", "minimal", "data-science") without changing the
-- rest of the file.
local ENABLED_PLUGINS = vim.deepcopy(FEATURES.plugins)

-- Small helper to make conditionals read naturally.
local function is_enabled(feature_name) return ENABLED_PLUGINS[feature_name] == true end

-- netrw tweaks (kept as comments for future fallback/testing)
-- vim.cmd 'let g:netrw_winsize = 25' -- width %
-- vim.cmd 'let g:netrw_banner = 0' -- hide banner
-- vim.keymap.set('n', ':Vex', ':Vex | wincmd H<CR>')

--=============================================================================
-- 2. GLOBAL VARIABLES & CORE OPTIONS
--=============================================================================
-- Sourced from: init.lua (Section 1)

-- Map <space> as the leader key. Must happen before plugins are loaded.
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Enable Nerd Font integration for icons across the UI
vim.g.have_nerd_font = true

--- UI & Aesthetics
vim.o.number = true -- Show absolute line numbers
vim.o.signcolumn = 'yes' -- Always show signcolumn
vim.o.showmode = false -- Hide default mode text
vim.o.cursorline = true -- Highlight the line under cursor
vim.o.scrolloff = 10 -- Maintain context lines
vim.o.list = true -- Display hidden whitespace characters
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

--- Editing Behavior & Reliability
vim.o.mouse = 'a' -- Enable mouse support in all modes
vim.o.breakindent = true -- Wrapped lines continue with visual indent
vim.o.undofile = true -- Durable undo history
vim.o.updatetime = 250 -- Decrease wait time for CursorHold events
vim.o.timeoutlen = 300 -- Decrease wait time for mapped key sequences
vim.o.confirm = true -- Prompt to save changes on exit

-- Sync OS clipboard (scheduled to reduce startup impact)
vim.schedule(function() vim.o.clipboard = 'unnamedplus' end)

--- Search, Replace & Window Splits
vim.o.ignorecase = true -- Case-insensitive search by default
vim.o.smartcase = true -- Case-sensitive if search contains capitals
vim.o.inccommand = 'split' -- Live preview of substitutions
vim.o.splitright = true -- Vertical splits open to the right
vim.o.splitbelow = true -- Horizontal splits open below

--- General Keymaps
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>', { desc = 'Clear search highlights' })
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- Window Navigation (<Ctrl> + hjkl)
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

--Remaps
vim.keymap.set('i', ';;', '<C-[>', { desc = 'Escape into normal mode.' })
vim.keymap.set('n', '09', '$', { noremap = true, desc = '09 is $ - end of line' })
vim.keymap.set('n', '00', '^', { noremap = true, desc = '00 is ^ - first char of line' })
vim.keymap.set('n', 'U', '<C-r>', { noremap = true, desc = 'Redo last undone change' })

--- Diagnostic Config
vim.diagnostic.config {
  update_in_insert = false,
  severity_sort = true,
  float = { border = 'rounded', source = 'if_many' },
  underline = { severity = vim.diagnostic.severity.ERROR },
  virtual_text = true,
  virtual_lines = false,
  jump = { float = true },
}
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

-- Visual feedback on yank
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function() vim.hl.on_yank() end,
})

--=============================================================================
-- 3. LANGUAGE METADATA REGISTRY
--=============================================================================
-- Sourced from: init.lua (Section 2)
-- Defines LSPs, Treesitter parsers, Formatters, and Linters.
--=============================================================================
local lang_registry = {
  lua = {
    treesitter = { 'lua', 'luadoc', 'luap' },
    lsp = { lua_ls = { settings = { Lua = {} } } },
    formatters = { lua = { 'stylua' } },
  },
  python = {
    treesitter = { 'python', 'ninja', 'rst' },
    lsp = {
      basedpyright = {
        settings = {
          basedpyright = {
            analysis = {
              autoSearchPaths = true,
              typeCheckingMode = 'standard',
              diagnosticMode = 'openFilesOnly',
            },
          },
        },
      },
      ruff = {},
    },
    formatters = {
      -- 'ruff_format' and 'ruff_organize_imports' are virtual names
      python = { 'ruff_format', 'ruff_organize_imports' },
    },
    linters = { python = { 'pylint' } },
  },
  frontend = {
    treesitter = { 'javascript', 'typescript', 'tsx', 'html', 'css', 'scss' },
    lsp = {
      ts_ls = {},
      tailwindcss = {
        filetypes = { 'html', 'css', 'scss', 'javascript', 'javascriptreact', 'typescript', 'typescriptreact', 'tsx' },
      },
    },
    formatters = {
      javascript = { 'prettierd', 'prettier', stop_after_first = true },
      typescript = { 'prettierd', 'prettier', stop_after_first = true },
      javascriptreact = { 'prettierd', 'prettier', stop_after_first = true },
      typescriptreact = { 'prettierd', 'prettier', stop_after_first = true },
      css = { 'prettierd', 'prettier', stop_after_first = true },
      html = { 'prettierd', 'prettier', stop_after_first = true },
    },
  },
  data_markup = {
    treesitter = { 'json', 'json5', 'yaml', 'toml', 'markdown', 'markdown_inline' },
    lsp = {
      jsonls = { settings = { json = { validate = true } } },
      yamlls = { settings = { yaml = { validate = true, completion = true, hover = true } } },
      taplo = {},
      marksman = {},
    },
    formatters = {
      json = { 'prettierd', 'prettier', stop_after_first = true },
      yaml = { 'prettierd', 'prettier', stop_after_first = true },
      markdown = { 'prettierd', 'prettier', stop_after_first = true },
      toml = { 'taplo' },
    },
    linters = { markdown = { 'markdownlint' } },
  },
  infra_shell = {
    treesitter = { 'bash', 'dockerfile', 'hcl', 'terraform', 'sql' },
    lsp = { bashls = {}, dockerls = {}, terraformls = {}, sqls = {} },
    formatters = { sh = { 'shfmt' } },
  },
  core = {
    treesitter = { 'c', 'diff', 'query', 'vim', 'vimdoc', 'regex' },
  },
}

-- Helper: return sorted string keys for deterministic iteration.
-- This improves reproducibility (Mason install list order, LSP setup order, etc.).
local function sorted_keys(tbl)
  local keys = vim.tbl_keys(tbl)
  table.sort(keys)
  return keys
end

-- Explicit language order so the compiler output is deterministic and easy to audit.
-- This also makes future code reviews easier because generated lists won't shuffle.
local LANGUAGE_ORDER = { 'lua', 'python', 'frontend', 'data_markup', 'infra_shell', 'core' }

--=============================================================================
-- 4. METADATA COMPILER ENGINE
--=============================================================================
-- Sourced from: init.lua (Section 4)
-- Parses registries into deterministic configurations.
--=============================================================================
local compiled = {
  treesitter_parsers = {},
  lsps = {},
  formatters_by_ft = {},
  linters_by_ft = {},
  mason_tools = {},
}

-- Mapping table for when Conform formatter names differ from Mason package names
local mason_package_map = {
  ['ruff_format'] = 'ruff',
  ['ruff_organize_imports'] = 'ruff',
}

local mason_seen = {}
local function register_mason_tool(tool)
  local actual_tool = mason_package_map[tool] or tool
  if type(actual_tool) == 'string' and not mason_seen[actual_tool] then
    table.insert(compiled.mason_tools, actual_tool)
    mason_seen[actual_tool] = true
  end
end

for _, lang_name in ipairs(LANGUAGE_ORDER) do
  local config = lang_registry[lang_name]
  if config.treesitter then
    for _, parser in ipairs(config.treesitter) do
      table.insert(compiled.treesitter_parsers, parser)
    end
  end

  if config.lsp then
    for _, lsp_name in ipairs(sorted_keys(config.lsp)) do
      local lsp_opts = config.lsp[lsp_name]
      compiled.lsps[lsp_name] = lsp_opts
      register_mason_tool(lsp_name)
    end
  end

  if config.formatters then
    for _, ft in ipairs(sorted_keys(config.formatters)) do
      local formatters = config.formatters[ft]
      compiled.formatters_by_ft[ft] = formatters
      for _, fmt in ipairs(formatters) do
        register_mason_tool(fmt)
      end
    end
  end

  if config.linters then
    for _, ft in ipairs(sorted_keys(config.linters)) do
      local linter_list = config.linters[ft]
      local normalized_list = type(linter_list) == 'table' and linter_list or { linter_list }
      compiled.linters_by_ft[ft] = compiled.linters_by_ft[ft] or {}
      vim.list_extend(compiled.linters_by_ft[ft], normalized_list)
      for _, linter in ipairs(normalized_list) do
        register_mason_tool(linter)
      end
    end
  end
end

--=============================================================================
-- 5. PLUGIN VAULT (The Optional Plugins)
--=============================================================================
-- These plugins are sourced from specific kickstart/plugins/*.lua files.
-- They are only loaded if enabled in the FEATURES table at the top.
--=============================================================================
local OPTIONAL_PLUGINS = {

  autopairs = {
    'windwp/nvim-autopairs',
    event = 'InsertEnter',
    opts = {},
  },

  autotag = {
    'windwp/nvim-ts-autotag',
    event = { 'BufReadPre', 'BufNewFile' },
    config = function() require('nvim-ts-autotag').setup() end,
  },

  indent_line = {
    'lukas-reineke/indent-blankline.nvim',
    main = 'ibl',
    opts = {},
  },

  -- NOTE: Strictly preserved window.mappings
  neo_tree = {
    'nvim-neo-tree/neo-tree.nvim',
    version = '*',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-tree/nvim-web-devicons',
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
  },

  -- NOTE: Merges the 'signs' config from init.lua with the 'on_attach' logic from gitsigns.lua
  gitsigns = {
    'lewis6991/gitsigns.nvim',
    opts = {
      -- Visual signs (From init.lua)
      signs = {
        add = { text = '+' },
        change = { text = '~' },
        delete = { text = '_' },
        topdelete = { text = '‾' },
        changedelete = { text = '~' },
      },
      -- Logic (From gitsigns.lua)
      on_attach = function(bufnr)
        local gitsigns = require 'gitsigns'

        local function map(mode, l, r, opts)
          opts = opts or {}
          opts.buffer = bufnr
          vim.keymap.set(mode, l, r, opts)
        end

        -- Navigation
        map('n', ']c', function()
          if vim.wo.diff then
            vim.cmd.normal { ']c', bang = true }
          else
            gitsigns.nav_hunk 'next'
          end
        end, { desc = 'Jump to next git [c]hange' })

        map('n', '[c', function()
          if vim.wo.diff then
            vim.cmd.normal { '[c', bang = true }
          else
            gitsigns.nav_hunk 'prev'
          end
        end, { desc = 'Jump to previous git [c]hange' })

        -- Actions
        -- visual mode
        map('v', '<leader>hs', function() gitsigns.stage_hunk { vim.fn.line '.', vim.fn.line 'v' } end, { desc = 'git [s]tage hunk' })
        map('v', '<leader>hr', function() gitsigns.reset_hunk { vim.fn.line '.', vim.fn.line 'v' } end, { desc = 'git [r]eset hunk' })
        -- normal mode
        map('n', '<leader>hs', gitsigns.stage_hunk, { desc = 'git [s]tage hunk' })
        map('n', '<leader>hr', gitsigns.reset_hunk, { desc = 'git [r]eset hunk' })
        map('n', '<leader>hS', gitsigns.stage_buffer, { desc = 'git [S]tage buffer' })
        -- NOTE: Preserved exactly from gitsigns.lua source. The mapping label says
        -- "undo stage hunk" but the function is `stage_hunk` (not `undo_stage_hunk`).
        -- Change this intentionally later only for behavior update.
        map('n', '<leader>hu', gitsigns.stage_hunk, { desc = 'git [u]ndo stage hunk' })
        map('n', '<leader>hR', gitsigns.reset_buffer, { desc = 'git [R]eset buffer' })
        map('n', '<leader>hp', gitsigns.preview_hunk, { desc = 'git [p]review hunk' })
        map('n', '<leader>hb', gitsigns.blame_line, { desc = 'git [b]lame line' })
        map('n', '<leader>hd', gitsigns.diffthis, { desc = 'git [d]iff against index' })
        map('n', '<leader>hD', function() gitsigns.diffthis '@' end, { desc = 'git [D]iff against last commit' })
        -- Toggles
        map('n', '<leader>tb', gitsigns.toggle_current_line_blame, { desc = '[T]oggle git show [b]lame line' })
        map('n', '<leader>tD', gitsigns.preview_hunk_inline, { desc = '[T]oggle git show [D]eleted' })
      end,
    },
  },

  -- NOTE: Config function is copied VERBATIM to ensure no loss of logic/keymaps/listeners
  dap = {
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

      -- OPTIONAL TEMPLATE (preserved from modular nvim-dap.lua):
      -- Remote attach example for Python running inside a Podman container.
      -- Uncomment and adapt if/when container debugging.
      --[[
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
              localRoot = vim.fn.getcwd(), -- Project folder on the host
              remoteRoot = '/app', -- Where the code lives in the container
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

  -- NOTE: Config preserved including adapter setup and keymaps
  neotest = {
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

  venv_selector = {
    'linux-cultist/venv-selector.nvim',
    dependencies = {
      'neovim/nvim-lspconfig',
      'nvim-telescope/telescope.nvim',
      'nvim-lua/plenary.nvim',
    },
    event = 'VeryLazy',
    opts = {},
    keys = {
      { '<leader>vs', '<cmd>VenvSelect<cr>', desc = '[V]env [S]elect' },
    },
  },

  schemastore = {
    'b0o/SchemaStore.nvim',
    -- Loaded lazily and only wired into jsonls/yamlls when the feature toggle is on.
    lazy = true,
  },

  -----------------------------------------------------------------------------
  -- DATA SCIENCE PLUGINS (Sourced from data-science.lua)
  -----------------------------------------------------------------------------

  -- 1. Rainbow CSV
  rainbow_csv = {
    'cameron-wags/rainbow_csv.nvim',
    -- Lightweight plugin: lazy-load only for tabular text files or explicit commands.
    config = true,
    ft = { 'csv', 'tsv', 'dat' },
    cmd = { 'RainbowDelim', 'RainbowMultiDelim' },
  },

  -- 2. Molten (Interactive Kernel)
  -- NOTE: init function copied VERBATIM to preserve all global variables and keymaps
  molten = {
    'benlubas/molten-nvim',
    version = '^1.0.0',
    -- Keep image.nvim as an explicit dependency. Feature validation above ensures
    -- `molten` cannot be enabled while `image_nvim` is disabled.
    dependencies = { '3rd/image.nvim' },
    build = ':UpdateRemotePlugins',
    init = function()
      -- Configuration
      vim.g.molten_image_provider = 'image.nvim'
      vim.g.molten_output_win_max_height = 20
      vim.g.molten_auto_open_output = false
      vim.g.molten_wrap_output = true
      vim.g.molten_virt_text_output = true
      vim.g.molten_virt_lines_off_by_1 = true

      -- Keymaps
      vim.keymap.set('n', '<leader>mi', ':MoltenInit<CR>', { desc = '[M]olten [I]nit', silent = true })
      vim.keymap.set('n', '<leader>me', ':MoltenEvaluateOperator<CR>', { desc = '[M]olten [E]valuate Operator', silent = true })
      vim.keymap.set('n', '<leader>ml', ':MoltenEvaluateLine<CR>', { desc = '[M]olten Evaluate [L]ine', silent = true })
      vim.keymap.set('v', '<leader>me', ':<C-u>MoltenEvaluateVisual<CR>gv', { desc = '[M]olten [E]valuate Visual', silent = true })
      vim.keymap.set('n', '<leader>mc', ':MoltenReevaluateCell<CR>', { desc = '[M]olten Re-evaluate [C]ell', silent = true })
      vim.keymap.set('n', '<leader>md', ':MoltenDelete<CR>', { desc = '[M]olten [D]elete Output', silent = true })
      vim.keymap.set('n', '<leader>mo', ':MoltenShowOutput<CR>', { desc = '[M]olten Show [O]utput', silent = true })
    end,
  },

  -- 3. Image.nvim
  image_nvim = {
    '3rd/image.nvim',
    enabled = function() return FEATURES.plugins.image_nvim end,
    opts = {
      -- LuaLS warning fix: image.nvim's Options type expects these fields
      backend = 'kitty', -- or 'ueberzug' depending on your terminal setup
      kitty_method = 'normal', -- common default for kitty backend
      integrations = {
        markdown = {
          enabled = true,
          clear_in_insert_mode = false,
          download_remote_images = true,
          only_render_image_at_cursor = false,
          filetypes = { 'markdown', 'vimwiki' },
        },
        neorg = {
          enabled = true,
        },
        html = {
          enabled = false,
        },
        css = {
          enabled = false,
        },
      },

      -- Keep your existing settings below (preserve what you already had)
      max_width = 100,
      max_height = 12,
      max_width_window_percentage = math.huge,
      max_height_window_percentage = math.huge,
      window_overlap_clear_enabled = true,
      window_overlap_clear_ft_ignore = { 'cmp_menu', 'cmp_docs', '' },
    },
  },
  -- 4. Vim Slime (REPL)
  -- NOTE: init/config functions copied VERBATIM
  vim_slime = {
    'jpalardy/vim-slime',
    init = function()
      vim.g.slime_target = 'tmux'
      vim.g.slime_python_ipython = 1
      vim.g.slime_dispatch_ipython_pause = 100
      vim.g.slime_no_mappings = 1
    end,
    config = function()
      vim.keymap.set('x', '<leader>rs', '<Plug>SlimeRegionSend', { desc = '[S]lime Send Region' })
      vim.keymap.set('n', '<leader>rs', '<Plug>SlimeParagraphSend', { desc = '[S]lime Send Paragraph' })
    end,
  },
}

--=============================================================================
-- 5A. FEATURE VALIDATION & SELF-DIAGNOSTICS
--=============================================================================
-- These helpers make the monolith safer to maintain:
--   * validation: catch incompatible feature combinations early
--   * ConfigAudit: print a human-readable summary of enabled features/tools
--
-- The goal is to fail fast with a clear message instead of silently loading a
-- partially broken setup.
--=============================================================================

local function validate_feature_matrix()
  local issues = {}

  -- Hard dependency: Molten setup is explicitly configured to use image.nvim
  if is_enabled 'molten' and not is_enabled 'image_nvim' then
    table.insert(issues, 'FEATURES.plugins.molten=true requires FEATURES.plugins.image_nvim=true (Molten is configured with image.nvim as the image provider).')
  end

  -- Ensure every listed optional plugin toggle actually has a plugin spec
  for feature_name, enabled in pairs(ENABLED_PLUGINS) do
    if enabled and OPTIONAL_PLUGINS[feature_name] == nil then
      table.insert(issues, ("FEATURES.plugins.%s=true but no OPTIONAL_PLUGINS spec exists for '%s'."):format(feature_name, feature_name))
    end
  end

  if #issues > 0 then
    local msg = 'Invalid Neovim feature configuration:\n- ' .. table.concat(issues, '\n- ')
    if FEATURES.validation and FEATURES.validation.strict then
      error(msg)
    else
      vim.schedule(function() vim.notify(msg, vim.log.levels.ERROR) end)
    end
  end
end

local function register_config_audit_command()
  vim.api.nvim_create_user_command('ConfigAudit', function()
    local enabled_feature_names = {}
    for _, name in ipairs(OPTIONAL_PLUGIN_ORDER) do
      if is_enabled(name) then table.insert(enabled_feature_names, name) end
    end

    local lines = {
      'Neovim Config Audit',
      string.rep('=', 40),
      '',
      'Enabled optional plugins (' .. tostring(#enabled_feature_names) .. '):',
      '  ' .. (next(enabled_feature_names) and table.concat(enabled_feature_names, ', ') or '(none)'),
      '',
      'Compiled Mason tools (' .. tostring(#compiled.mason_tools) .. '):',
      '  ' .. table.concat(compiled.mason_tools, ', '),
      '',
      'Compiled LSP servers (' .. tostring(vim.tbl_count(compiled.lsps)) .. '):',
      '  ' .. table.concat(sorted_keys(compiled.lsps), ', '),
      '',
      'Compiled Treesitter parsers (' .. tostring(#compiled.treesitter_parsers) .. '):',
      '  ' .. table.concat(compiled.treesitter_parsers, ', '),
    }

    vim.notify(table.concat(lines, '\n'), vim.log.levels.INFO, { title = 'ConfigAudit' })
  end, {
    desc = 'Print a summary of enabled features and compiled tool metadata',
  })
end

-- Run validation and register diagnostics command early (before Lazy setup)
validate_feature_matrix()
register_config_audit_command()

--=============================================================================
-- 6. CORE PLUGINS (Always Loaded)
--=============================================================================
-- These plugins come from original `init.lua` and are always loaded.
-- Think of this as the stable platform layer (editor UX, LSP, completion, etc.)
-- while OPTIONAL_PLUGINS above acts like feature modules.
--=============================================================================
local plugins = {

  -- Core Editor Utilities
  { 'NMAC427/guess-indent.nvim', opts = {} },

  {
    'folke/which-key.nvim',
    event = 'VimEnter',
    opts = function()
      -- Build which-key groups dynamically so the UI matches the feature flags.
      -- Example: if gitsigns is disabled, we do not advertise <leader>h groups.
      local spec = {
        { '<leader>s', group = '[S]earch', mode = { 'n', 'v' } },
        { '<leader>t', group = '[T]oggle' },
      }

      if is_enabled 'gitsigns' then table.insert(spec, { '<leader>h', group = 'Git [H]unk', mode = { 'n', 'v' } }) end
      if is_enabled 'molten' then table.insert(spec, { '<leader>m', group = '[M]olten (Data Science)', mode = { 'n', 'v' } }) end
      if is_enabled 'vim_slime' then table.insert(spec, { '<leader>r', group = '[R]EPL / Slime', mode = { 'n', 'v' } }) end
      if is_enabled 'dap' then table.insert(spec, { '<leader>d', group = '[D]ebug' }) end
      if is_enabled 'venv_selector' then table.insert(spec, { '<leader>v', group = '[V]env' }) end

      return {
        delay = 0,
        icons = { mappings = vim.g.have_nerd_font },
        spec = spec,
      }
    end,
  },

  --- Telescope: Fuzzy Finder
  {
    'nvim-telescope/telescope.nvim',
    enabled = true,
    event = 'VimEnter',
    dependencies = {
      'nvim-lua/plenary.nvim',
      { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make', cond = function() return vim.fn.executable 'make' == 1 end },
      { 'nvim-telescope/telescope-ui-select.nvim' },
      { 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },
    },
    config = function()
      require('telescope').setup {
        extensions = {
          ['ui-select'] = { require('telescope.themes').get_dropdown() },
        },
      }
      pcall(require('telescope').load_extension, 'fzf')
      pcall(require('telescope').load_extension, 'ui-select')

      local builtin = require 'telescope.builtin'
      vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
      vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
      vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
      vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
      vim.keymap.set({ 'n', 'v' }, '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
      vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
      vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
      vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
      vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files' })
      vim.keymap.set('n', '<leader>sc', builtin.commands, { desc = '[S]earch [C]ommands' })
      vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = '[ ] Find existing buffers' })
      vim.keymap.set('n', '<leader>sn', function() builtin.find_files { cwd = vim.fn.stdpath 'config' } end, { desc = '[S]earch [N]eovim files' })

      vim.keymap.set(
        'n',
        '<leader>/',
        function() builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown { winblend = 10, previewer = false }) end,
        { desc = '[/] Fuzzily search in current buffer' }
      )
      vim.keymap.set(
        'n',
        '<leader>s/',
        function() builtin.live_grep { grep_open_files = true, prompt_title = 'Live Grep in Open Files' } end,
        { desc = '[S]earch [/] in Open Files' }
      )

      -- Contextual LSP Keymaps
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('telescope-lsp-attach', { clear = true }),
        callback = function(event)
          local buf = event.buf
          vim.keymap.set('n', 'grr', builtin.lsp_references, { buffer = buf, desc = '[G]oto [R]eferences' })
          vim.keymap.set('n', 'gri', builtin.lsp_implementations, { buffer = buf, desc = '[G]oto [I]mplementation' })
          vim.keymap.set('n', 'grd', builtin.lsp_definitions, { buffer = buf, desc = '[G]oto [D]efinition' })
          vim.keymap.set('n', 'gO', builtin.lsp_document_symbols, { buffer = buf, desc = 'Open Document Symbols' })
          vim.keymap.set('n', 'gW', builtin.lsp_dynamic_workspace_symbols, { buffer = buf, desc = 'Open Workspace Symbols' })
          vim.keymap.set('n', 'grt', builtin.lsp_type_definitions, { buffer = buf, desc = '[G]oto [T]ype Definition' })
        end,
      })
    end,
  },

  --- Treesitter
  {
    'nvim-treesitter/nvim-treesitter',
    config = function()
      require('nvim-treesitter').install(compiled.treesitter_parsers)
      vim.api.nvim_create_autocmd('FileType', {
        pattern = compiled.treesitter_parsers,
        callback = function() vim.treesitter.start() end,
      })
    end,
  },

  --- Formatting (Conform.nvim)
  {
    'stevearc/conform.nvim',
    event = { 'BufWritePre' },
    cmd = { 'ConformInfo' },
    keys = {
      { '<leader>f', function() require('conform').format { async = true, lsp_format = 'fallback' } end, mode = '', desc = '[F]ormat buffer' },
    },
    opts = {
      notify_on_error = false,
      format_on_save = function(bufnr)
        local disable_filetypes = { c = true, cpp = true }
        if disable_filetypes[vim.bo[bufnr].filetype] then return nil end
        return { timeout_ms = 500, lsp_format = 'fallback' }
      end,
      formatters_by_ft = compiled.formatters_by_ft,
    },
  },

  --- Autocompletion (Blink.cmp)
  {
    'saghen/blink.cmp',
    build = 'cargo +nightly build --release',
    event = 'VimEnter',
    version = '1.*',
    dependencies = {
      {
        'L3MON4D3/LuaSnip',
        version = '2.*',
        build = (function()
          if vim.fn.has 'win32' == 1 or vim.fn.executable 'make' == 0 then return end
          return 'make install_jsregexp'
        end)(),
        opts = {},
      },
    },
    opts = {
      keymap = {
        preset = 'super-tab',
        ['<A-j>'] = { 'select_next', 'snippet_forward', 'fallback' },
        ['<A-k>'] = { 'select_prev', 'snippet_backward', 'fallback' },
      },
      appearance = { nerd_font_variant = 'mono' },
      completion = { documentation = { auto_show = false, auto_show_delay_ms = 500 } },
      sources = { default = { 'lsp', 'path', 'snippets' } },
      snippets = { preset = 'luasnip' },
      fuzzy = { implementation = 'prefer_rust_with_warning' },
      signature = { enabled = true },
    },
  },

  --- Linting (nvim-lint)
  {
    'mfussenegger/nvim-lint',
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      local lint = require 'lint'

      -- Mapping the metadata directly to the plugin
      lint.linters_by_ft = compiled.linters_by_ft

      -- Create the automation to trigger linting
      local lint_augroup = vim.api.nvim_create_augroup('lint-logic', { clear = true })
      vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'InsertLeave' }, {
        group = lint_augroup,
        callback = function()
          if vim.bo.modifiable then lint.try_lint() end
        end,
      })
    end,
  },

  --- LSP Configuration
  {
    'neovim/nvim-lspconfig',
    dependencies = (function()
      -- Build LSP dependencies dynamically so SchemaStore is truly optional.
      local deps = {
        { 'mason-org/mason.nvim', opts = {} },
        'williamboman/mason-lspconfig.nvim',
        'WhoIsSethDaniel/mason-tool-installer.nvim',
        { 'j-hui/fidget.nvim', opts = {} },
        'saghen/blink.cmp',
      }

      if is_enabled 'schemastore' then table.insert(deps, 'b0o/SchemaStore.nvim') end

      return deps
    end)(),
    config = function()
      -- LSP Attach Autocommands
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
        callback = function(event)
          local map = function(keys, func, desc, mode) vim.keymap.set(mode or 'n', keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc }) end
          map('grn', vim.lsp.buf.rename, '[R]e[n]ame')
          map('gra', vim.lsp.buf.code_action, '[G]oto Code [A]ction', { 'n', 'x' })
          map('grD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if client and client:supports_method('textDocument/documentHighlight', event.buf) then
            local hl_group = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
            vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, { buffer = event.buf, group = hl_group, callback = vim.lsp.buf.document_highlight })
            vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, { buffer = event.buf, group = hl_group, callback = vim.lsp.buf.clear_references })
            vim.api.nvim_create_autocmd('LspDetach', {
              group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
              callback = function(event2)
                vim.lsp.buf.clear_references()
                vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
              end,
            })
          end

          if client and client:supports_method('textDocument/inlayHint', event.buf) then
            map('<leader>th', function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf }) end, '[T]oggle Inlay [H]ints')
          end
        end,
      })

      -- Install tools via Mason based on Registry
      require('mason-tool-installer').setup { ensure_installed = compiled.mason_tools }
      require('mason-lspconfig').setup { ensure_installed = sorted_keys(compiled.lsps), automatic_installation = true }

      -- Wire up servers
      local capabilities = require('blink.cmp').get_lsp_capabilities()
      for _, name in ipairs(sorted_keys(compiled.lsps)) do
        local config = compiled.lsps[name]
        config.capabilities = vim.tbl_deep_extend('force', {}, capabilities, config.capabilities or {})

        -- Dynamic server-specific configs
        -- SchemaStore wiring is conditional so disabling the feature truly removes
        -- both the plugin dependency and the schema injection logic.
        if name == 'jsonls' and is_enabled 'schemastore' then
          config.settings.json.schemas = require('schemastore').json.schemas()
        elseif name == 'yamlls' and is_enabled 'schemastore' then
          config.settings.yaml.schemaStore = { enable = false, url = '' }
          config.settings.yaml.schemas = require('schemastore').yaml.schemas()
        elseif name == 'lua_ls' then
          config.on_init = function(client)
            if client.workspace_folders then
              local path = client.workspace_folders[1].name
              if path ~= vim.fn.stdpath 'config' and (vim.uv.fs_stat(path .. '/.luarc.json') or vim.uv.fs_stat(path .. '/.luarc.jsonc')) then return end
            end
            client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua or {}, {
              runtime = { version = 'LuaJIT', path = { 'lua/?.lua', 'lua/?/init.lua' } },
              workspace = { checkThirdParty = false, library = vim.api.nvim_get_runtime_file('', true) },
            })
          end
        end

        vim.lsp.config(name, config)
        vim.lsp.enable(name)
      end
    end,
  },

  --- UI, Aesthetics
  {
    'folke/tokyonight.nvim',
    priority = 1000,
    config = function()
      require('tokyonight').setup { styles = { comments = { italic = false } } }
      vim.cmd.colorscheme 'unokai'
    end,
  },
  { 'folke/todo-comments.nvim', event = 'VimEnter', dependencies = { 'nvim-lua/plenary.nvim' }, opts = { signs = false } },
  {
    'nvim-mini/mini.nvim',
    config = function()
      require('mini.ai').setup { n_lines = 500 }
      require('mini.surround').setup()
      local statusline = require 'mini.statusline'
      statusline.setup { use_icons = vim.g.have_nerd_font }
      ---@diagnostic disable-next-line: duplicate-set-field
      statusline.section_location = function() return '%2l:%-2v' end
    end,
  },
}

--=============================================================================
-- 7. PLUGIN ASSEMBLY & BOOTSTRAP
--=============================================================================
-- STEP 1: Append optional plugins in a deterministic order.
-- We iterate the explicit OPTIONAL_PLUGIN_ORDER list instead of `pairs()` so
-- startup behavior is stable and easier to debug/review.
for _, plugin_name in ipairs(OPTIONAL_PLUGIN_ORDER) do
  if is_enabled(plugin_name) then table.insert(plugins, OPTIONAL_PLUGINS[plugin_name]) end
end

-- STEP 2: Optional compatibility hook for future modular extensions.
-- This restores the spirit of original `table.insert(plugins, { import = 'custom.plugins' })`
-- while remaining safe for the monolith migration (disabled by default).
if FEATURES.imports and FEATURES.imports.custom_plugins then
  local custom_plugin_dir = vim.fn.stdpath 'config' .. '/lua/custom/plugins'
  if vim.fn.isdirectory(custom_plugin_dir) == 1 then
    table.insert(plugins, { import = 'custom.plugins' })
  else
    vim.schedule(
      function() vim.notify('FEATURES.imports.custom_plugins=true but no custom plugin directory was found at: ' .. custom_plugin_dir, vim.log.levels.WARN) end
    )
  end
end

-- STEP 3: Bootstrap Lazy.nvim
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  local out = vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath }
  if vim.v.shell_error ~= 0 then error('Error cloning lazy.nvim:\n' .. out) end
end
vim.opt.rtp:prepend(lazypath)

-- 4. Launch Lazy.nvim with the assembled plugin list.
--    At this point, all feature toggles and metadata compilation have already
--    happened, so Lazy receives a final, concrete plugin specification.
require('lazy').setup(plugins, {
  ui = {
    icons = vim.g.have_nerd_font and {} or {
      cmd = '⌘',
      config = '🛠',
      event = '📅',
      ft = '📂',
      init = '⚙',
      keys = '🗝',
      plugin = '🔌',
      runtime = '💻',
      require = '🌙',
      source = '📄',
      start = '🚀',
      task = '📌',
      lazy = '💤 ',
    },
  },
})

-- vim: ts=2 sts=2 sw=2 et
