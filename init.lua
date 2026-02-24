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

    -- Writing / Documents / Notes
    render_markdown = true, -- MeanderingProgrammer/render-markdown.nvim
    zen_mode = true, -- folke/zen-mode.nvim
    twilight = true, -- folke/twilight.nvim
    bullets = true, -- bullets-vim/bullets.vim
    table_mode = true, -- dhruvasagar/vim-table-mode
    markdown_preview = false, -- iamcco/markdown-preview.nvim (installed but OFF initially)
    neorg = true, -- nvim-neorg/neorg
    vimwiki = false, -- vimwiki/vimwiki (installed but OFF initially)

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

--=============================================================================
-- 1A. WRITING / DOCUMENT WORKFLOW CONFIG (Prose, Notes, PRD/PRFAQ, Exports)
--=============================================================================
-- This section is intentionally separate from `FEATURES.plugins`.
--
-- WHY?
-- ----
-- `FEATURES.plugins` answers: "Which plugins are enabled?"
-- `WRITING` answers:      "How should writing workflows behave?"
--
-- Keeping these concerns separate makes the config more scalable:
--   * You can change prose defaults (wrap, spell, width) without touching plugin toggles
--   * You can move notes/templates folders later without editing plugin specs
--   * You can keep export commands available but disable Pandoc if desired
--=============================================================================
local WRITING = {
  -- Filetypes that should receive prose-friendly defaults automatically.
  -- Add/remove entries here as your writing workflow evolves.
  prose_filetypes = { 'markdown', 'text', 'gitcommit', 'norg', 'vimwiki' },
  -- Prose defaults applied by FileType autocmds (baseline writing ergonomics).
  -- NOTE: `:Prose` is a stronger, manual toggle that can temporarily override
  -- some of these values for a deeper distraction-free writing mode.
  defaults = {
    wrap = true,
    linebreak = true, -- don't split words when wrapping
    breakindent = true,
    spell = true,
    spelllang = 'en_us',
    textwidth = 100, -- good default for PM docs/PRDs/PRFAQs
    colorcolumn = '101', -- visual guide just past textwidth
    conceallevel_markdown = 2, -- cleaner markdown rendering
    cursorline = false, -- prose buffers are usually nicer without cursorline
  },

  -- Prose mode behavior toggles (manual writing overlay via :Prose)
  prose = {
    -- "disable" = buffer diagnostics off while writing (stronger)
    -- "hide"    = keep diagnostics enabled, but hide decorations (visual only)
    diagnostic_mode = 'hide',
  },

  -- Paths used by note-taking and template commands.
  -- These can be absolute paths or expressions expanded with `~`.
  paths = {
    root = vim.fn.expand '~/notes',
    templates = vim.fn.expand '~/notes/templates',
    prd = vim.fn.expand '~/notes/prd',
    prfaq = vim.fn.expand '~/notes/prfaq',
    meeting_notes = vim.fn.expand '~/notes/meetings',
    neorg_workspace = vim.fn.expand '~/notes/neorg',
    vimwiki = vim.fn.expand '~/notes/vimwiki',
  },

  -- Pandoc export integration (optional but very useful).
  -- If `enabled = false`, export commands still exist but will warn and exit.
  pandoc = {
    enabled = true,
    pdf_engine = nil, -- e.g. 'wkhtmltopdf', 'xelatex', 'weasyprint'; nil = let pandoc choose
  },
}

--=============================================================================
-- 1B. HOW TO EXTEND THIS CONFIG (Beginner workflow cheatsheet)
--=============================================================================
-- Add a plugin (config-driven path)
--   1) Add/modify the toggle in FEATURES.plugins
--   2) Add the plugin spec in OPTIONAL_PLUGINS
--   3) Add the plugin key in OPTIONAL_PLUGIN_ORDER
--   4) Run :ConfigAudit to confirm it is visible and compiled
--
-- Add a language toolchain (LSP / formatter / linter / Treesitter)
--   1) Add or update a block in lang_registry
--   2) Add the registry key to LANGUAGE_ORDER
--   3) Run :ConfigAudit, :Mason, and :ConformInfo to verify the compiled output
--
-- Why this matters:
--   This monolith is intentionally metadata-driven. Most changes should happen in
--   the control tables above (FEATURES / WRITING) or the language registry below,
--   not by scattering one-off plugin edits throughout the file.
--=============================================================================

--=============================================================================
-- 1C. NEOVIM VERSION GATE
--=============================================================================
-- This monolith uses newer Neovim APIs (notably vim.lsp.config / vim.lsp.enable).
-- Requiring 0.11+ avoids confusing runtime errors for beginners on older builds.
if vim.fn.has 'nvim-0.11' ~= 1 then error 'This init.lua monolith requires Neovim 0.11+ (detected an older version). Upgrade Neovim and retry.' end

-- Ordered list of optional plugins.
-- We keep this separate from FEATURES.plugins so plugin assembly is deterministic.
-- (Iterating `pairs()` is NOT ordered in Lua.)
local OPTIONAL_PLUGIN_ORDER = {
  -----------------------------------------------------------------------------
  -- General editor / coding feature modules
  -----------------------------------------------------------------------------
  'indent_line',
  'autopairs',
  'neo_tree',
  'venv_selector',
  'dap',
  'neotest',
  'autotag',
  'gitsigns',
  'schemastore',

  -----------------------------------------------------------------------------
  -- Writing / document workflow modules
  -----------------------------------------------------------------------------
  'render_markdown',
  'zen_mode',
  'twilight',
  'bullets',
  'table_mode',
  'markdown_preview',
  'neorg',
  'vimwiki',

  -----------------------------------------------------------------------------
  -- Data science bundle
  -----------------------------------------------------------------------------
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

--=============================================================================
-- 2. GLOBAL VARIABLES & CORE OPTIONS
--=============================================================================

-- ============================================================================
-- FILETYPE REGISTRATION
-- ============================================================================
-- This maps specific files/extensions to official filetype names used by LSPs.
vim.filetype.add {
  extension = {
    mdx = 'mdx',
    tfvars = 'terraform-vars',
  },
  filename = {
    ['docker-compose.yml'] = 'yaml.docker-compose',
    ['docker-compose.yaml'] = 'yaml.docker-compose',
    ['gitlab-ci.yml'] = 'yaml.gitlab',
    ['gitlab-ci.yaml'] = 'yaml.gitlab',
  },
  pattern = {
    ['.*values%.yaml'] = 'yaml.helm-values',
    ['.*values%.yml'] = 'yaml.helm-values',
  },
}

-- Tree-sitter parser aliases for custom/specialized filetypes.
-- This keeps the custom filetype names above (great for LSP routing) while still
-- mapping them to the correct parser names for syntax parsing/highlighting.
do
  local ts_register = vim.treesitter and vim.treesitter.language and vim.treesitter.language.register
  if ts_register then
    pcall(ts_register, 'yaml', 'yaml.docker-compose')
    pcall(ts_register, 'yaml', 'yaml.gitlab')
    pcall(ts_register, 'yaml', 'yaml.helm-values')
    pcall(ts_register, 'terraform', 'terraform-vars')
    pcall(ts_register, 'tsx', 'typescriptreact')
    pcall(ts_register, 'javascript', 'javascriptreact')
  end
end

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
vim.opt.number = true -- Enable line number.
vim.opt.relativenumber = true -- Enable relative line number.

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

-- Remaps
vim.keymap.set('i', ';;', '<C-[>', { desc = 'Escape into normal mode.' })
vim.keymap.set('n', ';;', '%', { desc = 'Jump to matching bracket/brace.' })
vim.keymap.set('n', '09', '$', { noremap = true, desc = '09 is $ - end of line' })
vim.keymap.set('n', '00', '^', { noremap = true, desc = '00 is ^ - first char of line' })
vim.keymap.set('n', '000', 'G', { noremap = true, desc = '000 is G - Last line of file' })
vim.keymap.set('n', 'U', '<C-r>', { noremap = true, desc = 'Redo last undone change' })
vim.keymap.set('n', '0', '0', { noremap = true, desc = '0 is 0 - start of line' })

--- Diagnostic Config
-- A robust formatter function is used to prevent indexing errors when the
-- native diagnostic API passes varied structures.
local diagnostic_formatter = function(diag)
  if type(diag) ~= 'table' then return diag end
  return string.format('%s (%s: %s)', diag.message, diag.source or 'LSP', diag.code or 'no-code')
end

vim.diagnostic.config {
  update_in_insert = false,
  severity_sort = true,
  -- Diagnostic format configs must be explicitly nested within their display views
  virtual_text = {
    format = diagnostic_formatter,
  },
  float = {
    format = diagnostic_formatter,
    border = 'rounded',
    source = 'if_many',
  },
  underline = { severity = vim.diagnostic.severity.ERROR },
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
-- Terminology legend (important for beginners)
--   * filetype  : Neovim's buffer classification (e.g. 'yaml.gitlab')
--   * parser    : Tree-sitter grammar name (e.g. 'yaml', 'tsx')
--   * LSP       : Language server process (diagnostics, goto-def, rename, etc.)
--   * formatter : Code/document formatter used by Conform.nvim
--   * linter    : Diagnostics-only CLI tool used by nvim-lint
--   * Mason     : Installer/manager for external CLI tools and language servers
--
-- The registry below is the source of truth. The compiler in Section 4 converts
-- this metadata into deterministic lists/tables that plugins consume.
--=============================================================================
local lang_registry = {
  lua = {
    treesitter = { 'lua', 'luadoc', 'luap' },
    lsp = {
      lua_ls = {
        settings = {
          Lua = {
            diagnostics = {
              globals = { 'vim' },
            },
            workspace = {
              checkThirdParty = false,
              library = vim.api.nvim_get_runtime_file('', true),
            },
            telemetry = {
              enable = false,
            },
          },
        },
      },
    },
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
      -- We explicitly list valid filetypes to block the LSP's
      -- default "Unknown" types (like javascript.jsx)
      ts_ls = {
        filetypes = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact' },
      },
      tailwindcss = {
        filetypes = { 'html', 'css', 'scss', 'javascript', 'javascriptreact', 'typescript', 'typescriptreact' },
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
    treesitter = { 'json', 'json5', 'yaml', 'toml', 'markdown', 'markdown_inline', 'norg' },
    lsp = {
      jsonls = { settings = { json = { validate = true } } },
      yamlls = {
        -- Use the compound names we registered in Step 1
        filetypes = { 'yaml', 'yaml.docker-compose', 'yaml.gitlab', 'yaml.helm-values' },
        settings = { yaml = { validate = true, completion = true, hover = true } },
      },
      taplo = {},
      marksman = {
        -- Use standard markdown + the 'mdx' name we registered in Step 1
        filetypes = { 'markdown', 'mdx' },
      },
    },
    formatters = {
      json = { 'prettierd', 'prettier', stop_after_first = true },
      yaml = { 'prettierd', 'prettier', stop_after_first = true },
      markdown = { 'prettierd', 'prettier', stop_after_first = true },
      toml = { 'taplo' },
    },
    linters = {
      markdown = { 'markdownlint', 'vale' },
      text = { 'vale' },
      gitcommit = { 'vale' },
    },
  },
  infra_shell = {
    treesitter = { 'bash', 'dockerfile', 'hcl', 'terraform', 'sql' },
    lsp = {
      bashls = {},
      dockerls = {},
      terraformls = {
        -- Register 'terraform-vars' as we defined in Step 1
        filetypes = { 'terraform', 'terraform-vars' },
      },
      sqls = {},
    },
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
-- Parses registries into deterministic configurations.
--=============================================================================

-- ============================================================================
-- TREE-SITTER PARSER SANITIZER (Fix for norg warning)
-- ============================================================================
-- Why this exists:
--   - Neorg manages the "norg" and "norg_meta" parsers through its own
--     "core.integrations.treesitter" module.
--   - If you also put "norg" / "norg_meta" inside nvim-treesitter's
--     ensure_installed list, nvim-treesitter will warn and skip unsupported
--     languages.
--
-- Goal:
--   - Keep your parser list metadata-driven in `lang_registry` above, but
--     automatically filter out parsers that should be managed elsewhere.
local function sanitize_treesitter_parsers(parsers)
  -- Parsers that should NOT be installed via nvim-treesitter.ensure_installed
  local excluded = {
    norg = true,
    norg_meta = true,
  }

  local out = {}
  local seen = {}

  for _, lang in ipairs(parsers or {}) do
    if not excluded[lang] and not seen[lang] then
      table.insert(out, lang)
      seen[lang] = true
    end
  end

  return out
end

local compiled = {
  treesitter_parsers = {},
  lsps = {},
  formatters_by_ft = {},
  linters_by_ft = {},
  mason_tools = {}, -- non-LSP CLI tools only (formatters/linters/etc.)
  mason_lsp_servers = {}, -- LSP servers only (installed via mason-lspconfig)
}

-- Mapping table for when Conform formatter names differ from Mason package names
local mason_package_map = {
  ['ruff_format'] = 'ruff',
  ['ruff_organize_imports'] = 'ruff',
}

local mason_tool_seen = {}
local function register_mason_tool(tool)
  -- Non-LSP tools (Conform/nvim-lint/etc.) go through mason-tool-installer.
  local actual_tool = mason_package_map[tool] or tool
  if type(actual_tool) == 'string' and not mason_tool_seen[actual_tool] then
    table.insert(compiled.mason_tools, actual_tool)
    mason_tool_seen[actual_tool] = true
  end
end

local mason_lsp_seen = {}
local function register_mason_lsp(server_name)
  -- LSP servers are intentionally installed via mason-lspconfig to keep roles
  -- separated and beginner troubleshooting simpler.
  if type(server_name) == 'string' and not mason_lsp_seen[server_name] then
    table.insert(compiled.mason_lsp_servers, server_name)
    mason_lsp_seen[server_name] = true
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
      -- Deep-copy to keep lang_registry immutable (compiler output should be a
      -- compiled artifact, not a mutable alias to the registry source table).
      compiled.lsps[lsp_name] = vim.deepcopy(lsp_opts)
      register_mason_lsp(lsp_name)
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

-- Apply the sanitizer to the compiled list immediately
compiled.treesitter_parsers = sanitize_treesitter_parsers(compiled.treesitter_parsers)

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
  -- WRITING / DOCUMENT WORKFLOW PLUGINS
  -----------------------------------------------------------------------------
  -- These plugins turn Neovim into a strong environment for:
  --   * note taking
  --   * PRDs / PRFAQs / memos
  --   * lightweight task/project management
  --   * markdown tables / lists / focus writing
  --
  -- They are intentionally separated from coding plugins so you can disable the
  -- entire writing stack selectively via the feature switchboard.
  -----------------------------------------------------------------------------

  -- Render Markdown nicely inside Neovim (headings, checkboxes, code fences, etc.)
  render_markdown = {
    'MeanderingProgrammer/render-markdown.nvim',
    ft = { 'markdown', 'norg', 'vimwiki' },
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' },
    opts = {
      -- Keep defaults initially. This plugin is highly configurable; you can add
      -- custom heading icons, checkbox states, and code block rendering later.
    },
  },

  -- Distraction-free writing mode (narrow centered column, hide clutter).
  zen_mode = {
    'folke/zen-mode.nvim',
    cmd = 'ZenMode',
    opts = {
      window = {
        backdrop = 0.95,
        width = 110,
        options = {
          number = false,
          relativenumber = false,
        },
      },
      plugins = {
        -- If twilight is enabled, Zen can dim surrounding text automatically.
        twilight = { enabled = is_enabled 'twilight' },
        gitsigns = { enabled = false },
      },
    },
  },

  -- Dims non-focused text. Useful in long PRDs/PRFAQs while editing one section.
  twilight = {
    'folke/twilight.nvim',
    cmd = 'Twilight',
    opts = {},
  },

  -- Better markdown/plaintext list ergonomics (auto bullet continuation, etc.).
  bullets = {
    'bullets-vim/bullets.vim',
    ft = { 'markdown', 'text', 'gitcommit', 'vimwiki' },
  },

  -- Markdown table editing/alignment. Very useful for PM docs and specs.
  table_mode = {
    'dhruvasagar/vim-table-mode',
    cmd = { 'TableModeEnable', 'TableModeDisable', 'TableModeToggle' },
    ft = { 'markdown', 'vimwiki' },
    init = function()
      -- Default corner character for markdown tables.
      vim.g.table_mode_corner = '|'
    end,
  },

  -- Live markdown preview in browser. Installed but OFF by default in FEATURES.
  markdown_preview = {
    'iamcco/markdown-preview.nvim',
    ft = { 'markdown' },
    cmd = { 'MarkdownPreview', 'MarkdownPreviewStop', 'MarkdownPreviewToggle' },
    build = function() vim.fn['mkdp#util#install']() end,
  },

  -- Neorg: a powerful note-taking / knowledge management system for Neovim.
  -- Great for structured notes, journals, and TODO/task workflows in `.norg`.
  neorg = {
    'nvim-neorg/neorg',
    version = '*',
    ft = { 'norg' },
    cmd = { 'Neorg' },
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      -- Ensure the workspace root exists. Neorg will manage files under this path.
      vim.fn.mkdir(WRITING.paths.neorg_workspace, 'p')

      require('neorg').setup {
        load = {
          ['core.defaults'] = {},
          ['core.concealer'] = {},
          ['core.summary'] = {},

          -- ============================================================================
          -- NEORG TREE-SITTER INTEGRATION
          -- ============================================================================
          -- Neorg can configure/install the Norg parsers itself. This is the preferred
          -- path when using Neorg, and it avoids nvim-treesitter warnings for "norg".
          ['core.integrations.treesitter'] = {
            config = {
              configure_parsers = true,
              install_parsers = true,
            },
          },

          ['core.journal'] = {
            config = {
              workspace = 'notes',
            },
          },
          ['core.dirman'] = {
            config = {
              default_workspace = 'notes',
              workspaces = {
                notes = WRITING.paths.neorg_workspace,
              },
            },
          },
        },
      }
    end,
  },

  -- Vimwiki: classic wiki/note system. Installed but OFF by default.
  vimwiki = {
    'vimwiki/vimwiki',
    ft = { 'vimwiki', 'markdown' },
    init = function()
      vim.fn.mkdir(WRITING.paths.vimwiki, 'p')
      vim.g.vimwiki_global_ext = 0
      vim.g.vimwiki_list = {
        {
          path = WRITING.paths.vimwiki,
          syntax = 'markdown',
          ext = '.md',
        },
      }
    end,
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
      max_width = 100,
      max_height = 12,
      max_width_window_percentage = math.huge,
      max_height_window_percentage = math.huge,
      window_overlap_clear_enabled = true,
      window_overlap_clear_ft_ignore = { 'cmp_menu', 'cmp_docs', '' },
    },
  },
  -- 4. Vim Slime (REPL)
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
--=============================================================================

local function validate_feature_matrix()
  local issues = {}

  -- Hard dependency: Molten setup is explicitly configured to use image.nvim
  if is_enabled 'molten' and not is_enabled 'image_nvim' then
    table.insert(issues, 'FEATURES.plugins.molten=true requires FEATURES.plugins.image_nvim=true (Molten is configured with image.nvim as the image provider).')
  end

  -- Validate the 3-way optional plugin model stays in sync:
  --   FEATURES.plugins <-> OPTIONAL_PLUGINS <-> OPTIONAL_PLUGIN_ORDER
  local plugin_order_seen = {}
  for _, plugin_name in ipairs(OPTIONAL_PLUGIN_ORDER) do
    if plugin_order_seen[plugin_name] then table.insert(issues, ("OPTIONAL_PLUGIN_ORDER contains a duplicate entry for '%s'."):format(plugin_name)) end
    plugin_order_seen[plugin_name] = true

    if OPTIONAL_PLUGINS[plugin_name] == nil then
      table.insert(issues, ("OPTIONAL_PLUGIN_ORDER references '%s' but no OPTIONAL_PLUGINS spec exists."):format(plugin_name))
    end
  end

  for feature_name, enabled in pairs(ENABLED_PLUGINS) do
    if OPTIONAL_PLUGINS[feature_name] == nil then
      table.insert(issues, ("FEATURES.plugins.%s exists but no OPTIONAL_PLUGINS spec exists for '%s'."):format(feature_name, feature_name))
    end

    if plugin_order_seen[feature_name] ~= true then
      table.insert(issues, ('FEATURES.plugins.%s exists but is missing from OPTIONAL_PLUGIN_ORDER.'):format(feature_name))
    end

    if enabled and OPTIONAL_PLUGINS[feature_name] == nil then
      table.insert(issues, ("FEATURES.plugins.%s=true but no OPTIONAL_PLUGINS spec exists for '%s'."):format(feature_name, feature_name))
    end
  end

  for plugin_name, _ in pairs(OPTIONAL_PLUGINS) do
    if plugin_order_seen[plugin_name] ~= true then
      table.insert(issues, ("OPTIONAL_PLUGINS contains '%s' but it is missing from OPTIONAL_PLUGIN_ORDER (it can never load)."):format(plugin_name))
    end
  end

  -- Validate language registry coverage against LANGUAGE_ORDER (prevents silent skips)
  local language_order_seen = {}
  for _, lang_name in ipairs(LANGUAGE_ORDER) do
    if language_order_seen[lang_name] then table.insert(issues, ("LANGUAGE_ORDER contains a duplicate entry for '%s'."):format(lang_name)) end
    language_order_seen[lang_name] = true

    if lang_registry[lang_name] == nil then table.insert(issues, ("LANGUAGE_ORDER references '%s' but no lang_registry entry exists."):format(lang_name)) end
  end

  for lang_name, _ in pairs(lang_registry) do
    if language_order_seen[lang_name] ~= true then
      table.insert(issues, ("lang_registry contains '%s' but it is missing from LANGUAGE_ORDER (it will be ignored by the compiler)."):format(lang_name))
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
      'Compiled Mason non-LSP tools (' .. tostring(#compiled.mason_tools) .. '):',
      '  ' .. (next(compiled.mason_tools) and table.concat(compiled.mason_tools, ', ') or '(none)'),
      '',
      'Compiled Mason LSP servers (' .. tostring(#compiled.mason_lsp_servers) .. '):',
      '  ' .. (next(compiled.mason_lsp_servers) and table.concat(compiled.mason_lsp_servers, ', ') or '(none)'),
      '',
      'Compiled LSP servers (' .. tostring(vim.tbl_count(compiled.lsps)) .. '):',
      '  ' .. table.concat(sorted_keys(compiled.lsps), ', '),
      '',
      'Compiled Treesitter parsers (' .. tostring(#compiled.treesitter_parsers) .. '):',
      '  ' .. table.concat(compiled.treesitter_parsers, ', '),
      '',
      'Writing root:',
      '  ' .. WRITING.paths.root,
      'Pandoc export enabled:',
      '  ' .. tostring(WRITING.pandoc.enabled),
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
-- 5B. WRITING WORKFLOW HELPERS (Extracted Optional Module Loader)
--=============================================================================
-- The writing workflow helpers (Prose mode, templates, exports, writing keymaps)
-- are now split into `lua/custom/prose_extras.lua` so the core init.lua remains
-- easier to read for beginners.
--
-- `WRITING` (Section 1A) stays in this file for now. We pass it into the module.
-- The module load is optional and metadata-driven:
--   FEATURES.extras.prose.enabled = true  -> load extras
--   FEATURES.extras.prose.enabled = false -> skip extras
--=============================================================================

FEATURES.extras = FEATURES.extras or {}
FEATURES.extras.prose = FEATURES.extras.prose or {
  enabled = true,
  module = 'custom.prose_extras',
}

local function load_optional_module(spec, opts)
  if not spec or not spec.enabled then return end

  local ok, mod_or_err = pcall(require, spec.module)
  if not ok then
    local err = tostring(mod_or_err)
    local not_found_pat = "module '" .. spec.module:gsub('%.', '%%.') .. "' not found"
    if not err:match(not_found_pat) then vim.notify('Error loading optional module [' .. spec.module .. ']: ' .. err, vim.log.levels.ERROR) end
    return
  end

  local mod = mod_or_err
  if type(mod.setup) == 'function' then
    local setup_ok, setup_err = pcall(mod.setup, opts or {})
    if not setup_ok then vim.notify('Error in ' .. spec.module .. '.setup(): ' .. tostring(setup_err), vim.log.levels.ERROR) end
  end
end

load_optional_module(FEATURES.extras.prose, {
  WRITING = WRITING,
  is_enabled = is_enabled,
})

--=============================================================================
-- 6. CORE PLUGINS (Always Loaded)
--=============================================================================
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
      local spec = {
        { '<leader>s', group = '[S]earch', mode = { 'n', 'v' } },
        { '<leader>t', group = '[T]oggle' },
        { '<leader>w', group = '[W]riting', mode = { 'n', 'v' } },
      }

      if is_enabled 'gitsigns' then table.insert(spec, { '<leader>h', group = 'Git [H]unk', mode = { 'n', 'v' } }) end
      if is_enabled 'molten' then table.insert(spec, { '<leader>m', group = '[M]olten (Data Science)', mode = { 'n', 'v' } }) end
      if is_enabled 'vim_slime' then table.insert(spec, { '<leader>r', group = '[R]EPL / Slime', mode = { 'n', 'v' } }) end
      if is_enabled 'dap' then table.insert(spec, { '<leader>d', group = '[D]ebug' }) end
      if is_enabled 'venv_selector' then table.insert(spec, { '<leader>v', group = '[V]env' }) end
      if is_enabled 'neorg' then table.insert(spec, { '<leader>n', group = '[N]eorg' }) end

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

      -- Contextual LSP Keymaps scoped to Telescope
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

  --- Treesitter: Advanced Syntax Highlighting and Parsing
  {
    'nvim-treesitter/nvim-treesitter',
    version = 'v0.9.3',
    build = ':TSUpdate',
    event = { 'BufReadPost', 'BufNewFile' },
    cmd = { 'TSUpdateSync', 'TSUpdate', 'TSInstall' },
    config = function()
      -- compiled.treesitter_parsers is built in Section 4 of the monolith
      local configs = require 'nvim-treesitter.configs'

      configs.setup {
        ensure_installed = compiled.treesitter_parsers,
        auto_install = true,
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = false,
        },
        indent = { enable = true },
        incremental_selection = {
          enable = true,
          keymaps = {
            init_selection = '<c-space>',
            node_incremental = '<c-space>',
            scope_incremental = '<c-s>',
            node_decremental = '<M-space>',
          },
        },
      }

      -- Native Tree-sitter attach fallback.
      -- We intentionally trigger on all FileType events and use pcall instead of
      -- matching parser names as filetypes (parser names and filetypes differ for
      -- several languages/custom aliases, e.g. tsx vs typescriptreact, yaml.*).
      local ts_start_group = vim.api.nvim_create_augroup('monolith-treesitter-start', { clear = true })
      vim.api.nvim_create_autocmd('FileType', {
        group = ts_start_group,
        pattern = '*',
        desc = 'Best-effort Tree-sitter attach for parser/filetype alias cases',
        callback = function(args) pcall(vim.treesitter.start, args.buf) end,
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

      -- Mapping the metadata directly to the plugin.
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

  --=============================================================================
  -- 6A. LSP ORCHESTRATION & CONFIGURATION
  --=============================================================================
  -- This section leverages the native Neovim Language Server Protocol orchestrator.
  -- Key architecture:
  -- 1. `vim.lsp.enable()`: Manages server lifecycles gracefully via internal autocommands.
  -- 2. `vim.lsp.config`: A centralized native table handling global server rules.
  -- 3. The editor natively provides core mappings (`grn`, `gra`, `grr`, `gri`).
  --=============================================================================
  {
    'neovim/nvim-lspconfig', -- Used strictly as a metadata source for default LSP configurations
    dependencies = (function()
      local deps = {
        { 'williamboman/mason.nvim', config = true },
        'williamboman/mason-lspconfig.nvim',
        'WhoIsSethDaniel/mason-tool-installer.nvim',
        { 'j-hui/fidget.nvim', opts = {} },
        'saghen/blink.cmp',
      }
      if is_enabled 'schemastore' then table.insert(deps, 'b0o/SchemaStore.nvim') end
      return deps
    end)(),
    config = function()
      -- ========================================================================
      -- LSP ATTACH LOGIC (Feature capability detection & Keymaps)
      -- ========================================================================
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('monolith-lsp-attach', { clear = true }),
        callback = function(event)
          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if not client then return end

          local map = function(keys, func, desc, mode) vim.keymap.set(mode or 'n', keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc }) end

          -- Even though the editor provides native mappings for these, we re-apply them
          -- to ensure Which-Key picks up the descriptions and for explicit control.
          map('grn', vim.lsp.buf.rename, '[R]e[n]ame Variable')
          map('gra', vim.lsp.buf.code_action, '[G]oto Code [A]ction', { 'n', 'x' })
          map('grD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

          -- Explicit Toggle Inlay Hints keymap detection
          if client:supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
            map('<leader>th', function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf }) end, '[T]oggle Inlay [H]ints')
          end

          -- Provide visual feedback for symbols under the cursor
          if client:supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight) then
            local group = vim.api.nvim_create_augroup('lsp-highlight', { clear = false })
            vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
              buffer = event.buf,
              group = group,
              callback = vim.lsp.buf.document_highlight,
            })
            vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
              buffer = event.buf,
              group = group,
              callback = vim.lsp.buf.clear_references,
            })
          end
        end,
      })

      -- ========================================================================
      -- LSP ENGINE REGISTRATION & ACTIVATION
      -- ========================================================================
      local capabilities = require('blink.cmp').get_lsp_capabilities()

      require('mason').setup()
      -- Split installation responsibilities for clarity:
      --   * mason-tool-installer => non-LSP CLIs (formatters/linters/etc.)
      --   * mason-lspconfig      => LSP servers only
      require('mason-tool-installer').setup { ensure_installed = compiled.mason_tools }

      require('mason-lspconfig').setup {
        ensure_installed = compiled.mason_lsp_servers,
        handlers = {
          function(server_name)
            -- Retrieve the default baseline configurations built into nvim-lspconfig
            local server_def = require('lspconfig')[server_name]
            local default_config = server_def and server_def.document_config and server_def.document_config.default_config or {}

            -- Merge overrides mapped within our monolith's Language Registry (Section 3)
            local user_settings = compiled.lsps[server_name] or {}

            -- Construct the definitive table accepted by the native config schema.
            -- Deep extend ensures we don't drop any arbitrary user keys (like init_options).
            local final_config = vim.tbl_deep_extend('force', {}, user_settings)

            -- Fallback to lspconfig defaults for core routing parameters
            final_config.cmd = final_config.cmd or default_config.cmd
            final_config.filetypes = final_config.filetypes or default_config.filetypes
            final_config.root_dir = final_config.root_dir or default_config.root_dir
            final_config.capabilities = vim.tbl_deep_extend('force', capabilities, final_config.capabilities or {})

            -- SchemaStore injection: Extends JSON/YAML servers with community schema catalogs
            if (server_name == 'jsonls' or server_name == 'yamlls') and is_enabled 'schemastore' then
              local ok, schemastore = pcall(require, 'schemastore')
              if ok then
                final_config.settings = vim.tbl_deep_extend('force', final_config.settings or {}, {
                  json = server_name == 'jsonls' and { schemas = schemastore.json.schemas(), validate = true } or nil,
                  yaml = server_name == 'yamlls' and { schemas = schemastore.yaml.schemas(), validate = true } or nil,
                })
              end
            end

            -- Lua Server Environment Protection (Preserving original logic for local .luarc.json overrides)
            if server_name == 'lua_ls' then
              final_config.on_init = function(client)
                if client.workspace_folders then
                  local path = client.workspace_folders[1].name
                  if path ~= vim.fn.stdpath 'config' and (vim.uv.fs_stat(path .. '/.luarc.json') or vim.uv.fs_stat(path .. '/.luarc.jsonc')) then return end
                end
                client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua or {}, {
                  runtime = { version = 'LuaJIT' },
                  diagnostics = { globals = { 'vim' } },
                  workspace = {
                    checkThirdParty = false,
                    library = { vim.env.VIMRUNTIME, '${3rd}/luv/library' },
                  },
                })
              end
            end

            -- Set the global template for the server within the native config store
            vim.lsp.config[server_name] = final_config

            -- Instruct the native orchestrator to watch for matching buffers and instantiate the server
            vim.lsp.enable(server_name)
          end,
        },
      }
    end,
  },

  --=============================================================================
  -- 7. UI, AESTHETICS & THEME
  --=============================================================================
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
-- 8. PLUGIN ASSEMBLY & BOOTSTRAP
--=============================================================================
-- STEP 1: Append optional plugins in a deterministic order.
-- We iterate the explicit OPTIONAL_PLUGIN_ORDER list instead of `pairs()` so
-- startup behavior is stable and easier to debug/review.
for _, plugin_name in ipairs(OPTIONAL_PLUGIN_ORDER) do
  if is_enabled(plugin_name) then table.insert(plugins, OPTIONAL_PLUGINS[plugin_name]) end
end

-- STEP 2: Optional compatibility hook for future modular extensions.
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
require('lazy').setup(plugins, {
  --  rocks = {
  --    hererocks = true, -- This creates a local Lua 5.1 environment for rocks
  --  },
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
