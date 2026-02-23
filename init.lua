--=============================================================================
-- init.lua
-- Metadata-Driven Enterprise SaaS & ML Development Configuration
--
-- ARCHITECTURE OVERVIEW:
-- This configuration embraces a declarative, metadata-first architecture.
-- It strictly separates INTENT (Section 2 & 3) from EXECUTION (Section 4 & 6).
--
-- 1. CORE OPTIONS: Native Vim settings for reliability and UI.
-- 2. LANG REGISTRY: Single Source of Truth for LSPs, Formatters, and Parsers.
--    * UPDATED: Uses the "Ruff" stack for high-performance Python linting/formatting.
-- 3. PLUGIN REGISTRY: Declarative list of core IDE capabilities.
-- 4. COMPILER: Translates registries into plugin-consumable data structures.
--    * FIXED: Maps virtual formatter names (ruff_format) to real packages (ruff).
-- 5. BOOTSTRAP: Ensures the Package Manager (Lazy) is installed.
-- 6. RUNTIME: Initializes plugins using the compiled metadata.
--=============================================================================

--- [USER CHANGE] netrw tweaks
-- Overrides for the built-in netrw file explorer to act more like a sidebar.
-- vim.cmd 'let g:netrw_winsize = 25' -- width %
-- vim.cmd 'let g:netrw_banner = 0' -- hide banner
-- vim.keymap.set('n', ':Vex', ':Vex | wincmd H<CR>')

--=============================================================================
-- 1. GLOBAL VARIABLES & CORE OPTIONS
--=============================================================================

-- Map <space> as the leader key. Must happen before plugins are loaded.
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Enable Nerd Font integration for icons across the UI (Telescope, Neo-tree, etc.)
vim.g.have_nerd_font = true

--- UI & Aesthetics
vim.o.number = true -- Show absolute line numbers for deterministic navigation.
vim.o.signcolumn = 'yes' -- Always show signcolumn to prevent text shifting.
vim.o.showmode = false -- Hide default mode text (handled by statusline).
vim.o.cursorline = true -- Highlight the line under cursor for visual tracking.
vim.o.scrolloff = 10 -- Maintain context lines above/below cursor.
vim.o.list = true -- Display hidden whitespace characters.
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

--- Editing Behavior & Reliability
vim.o.mouse = 'a' -- Enable mouse support in all modes.
vim.o.breakindent = true -- Wrapped lines continue with visual indent.
vim.o.undofile = true -- Durable undo history across sessions.
vim.o.updatetime = 250 -- Decrease wait time for CursorHold events.
vim.o.timeoutlen = 300 -- Decrease wait time for mapped key sequences.
vim.o.confirm = true -- Prompt to save changes on exit.

-- Sync OS clipboard (scheduled to reduce startup impact)
vim.schedule(function() vim.o.clipboard = 'unnamedplus' end)

--- Search, Replace & Window Splits
vim.o.ignorecase = true -- Case-insensitive search by default.
vim.o.smartcase = true -- Case-sensitive if search contains capitals.
vim.o.inccommand = 'split' -- Live preview of substitutions.
vim.o.splitright = true -- Vertical splits open to the right.
vim.o.splitbelow = true -- Horizontal splits open below.

--- General Keymaps
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>', { desc = 'Clear search highlights' })
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- Window Navigation (<Ctrl> + hjkl)
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

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
-- 2. LANGUAGE METADATA REGISTRY (Source of Truth)
--=============================================================================
-- Defines capabilities for Enterprise SaaS & Data Science workflows.
-- The compiler engine dynamically configures tools based on this table.
--=============================================================================
local lang_registry = {
  lua = {
    treesitter = { 'lua', 'luadoc', 'luap' },
    lsp = { lua_ls = { settings = { Lua = {} } } },
    formatters = { lua = { 'stylua' } },
  },
  -- Python Configuration (Optimized for ML/Data Science via Ruff)
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
      -- 'ruff_format' and 'ruff_organize_imports' are virtual names used by Conform.
      -- The compiler engine below maps these to the actual 'ruff' package for Mason.
      python = { 'ruff_format', 'ruff_organize_imports' },
    },
    linters = { python = { 'pylint' } }, -- Add this to ensure Mason installs it
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
    linters = { markdown = { 'markdownlint' } }, -- Add this to ensure Mason installs it
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

--=============================================================================
-- 3. PLUGIN MODULE REGISTRY
--=============================================================================
-- Declarative list of external plugin modules.
-- NOTE: `kickstart.plugins.vim-slime` is explicitly OMITTED here.
-- It is loaded in `custom/plugins/data-science.lua` with ML-specific settings.
--=============================================================================
local plugin_registry = {
  -- Core UX
  'kickstart.plugins.indent_line',
  'kickstart.plugins.autopairs',
  'kickstart.plugins.neo-tree',

  -- Debugging & Tooling
  -- 'kickstart.plugins.debug',
  -- 'kickstart.plugins.lint',
  'kickstart.plugins.venv-selector',
  -- 'kickstart.plugins.nvim-lint',
  'kickstart.plugins.nvim-dap',
  'kickstart.plugins.neotest',
  'kickstart.plugins.nvim-ts-autotag',
  'kickstart.plugins.data-science',
}

--=============================================================================
-- 4. METADATA COMPILER ENGINE
--=============================================================================
-- Parses registries into deterministic configurations for Lazy.nvim.
-- Handles mapping between virtual formatter names and actual binary packages.
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
  -- Resolve specific tool mapping if it exists (e.g. ruff_format -> ruff)
  local actual_tool = mason_package_map[tool] or tool

  if type(actual_tool) == 'string' and not mason_seen[actual_tool] then
    table.insert(compiled.mason_tools, actual_tool)
    mason_seen[actual_tool] = true
  end
end

for _, config in pairs(lang_registry) do
  if config.treesitter then
    for _, parser in ipairs(config.treesitter) do
      table.insert(compiled.treesitter_parsers, parser)
    end
  end

  if config.lsp then
    for lsp_name, lsp_opts in pairs(config.lsp) do
      compiled.lsps[lsp_name] = lsp_opts
      register_mason_tool(lsp_name)
    end
  end

  if config.formatters then
    for ft, formatters in pairs(config.formatters) do
      compiled.formatters_by_ft[ft] = formatters
      for _, fmt in ipairs(formatters) do
        register_mason_tool(fmt)
      end
    end
  end

  if config.linters then
    for ft, linter_list in pairs(config.linters) do
      -- 1. Normalize: If it's a string, wrap it in a table so ipairs and list_extend work.
      local normalized_list = type(linter_list) == 'table' and linter_list or { linter_list }
      -- 2. Aggregate linters for nvim-lint
      compiled.linters_by_ft[ft] = compiled.linters_by_ft[ft] or {}
      vim.list_extend(compiled.linters_by_ft[ft], normalized_list)
      -- 3. Register for Mason installation
      for _, linter in ipairs(normalized_list) do
        register_mason_tool(linter)
      end
    end
  end
end

--=============================================================================
-- 5. PLUGIN MANAGER BOOTSTRAP (Lazy.nvim)
--=============================================================================
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  local out = vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath }
  if vim.v.shell_error ~= 0 then error('Error cloning lazy.nvim:\n' .. out) end
end
vim.opt.rtp:prepend(lazypath)

--=============================================================================
-- 6. PLUGIN SPECIFICATIONS (Runtime)
--=============================================================================
local plugins = {

  -- Core Editor Utilities
  { 'NMAC427/guess-indent.nvim', opts = {} },
  {
    'folke/which-key.nvim',
    event = 'VimEnter',
    opts = {
      delay = 0,
      icons = { mappings = vim.g.have_nerd_font },
      spec = {
        { '<leader>s', group = '[S]earch', mode = { 'n', 'v' } },
        { '<leader>t', group = '[T]oggle' },
        { '<leader>h', group = 'Git [H]unk', mode = { 'n', 'v' } },
        -- [USER CHANGE] ML specific group for Molten
        { '<leader>m', group = '[M]olten (Data Science)', mode = { 'n', 'v' } },
      },
    },
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
      -- { 'nvim-telescope/telescope-file-browser.nvim' }, -- [USER CHANGE]
    },
    config = function()
      require('telescope').setup {
        extensions = {
          ['ui-select'] = { require('telescope.themes').get_dropdown() },
          -- [USER CHANGE] file browser config
          -- file_browser = { theme = 'ivy', hijack_netrw = true },
        },
      }
      pcall(require('telescope').load_extension, 'fzf')
      pcall(require('telescope').load_extension, 'ui-select')
      -- pcall(require('telescope').load_extension, 'file_browser') -- [USER CHANGE]

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
    dependencies = {
      { 'mason-org/mason.nvim', opts = {} },
      'williamboman/mason-lspconfig.nvim',
      'WhoIsSethDaniel/mason-tool-installer.nvim',
      { 'j-hui/fidget.nvim', opts = {} },
      'saghen/blink.cmp',
      'b0o/SchemaStore.nvim',
    },
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
      require('mason-lspconfig').setup { ensure_installed = vim.tbl_keys(compiled.lsps), automatic_installation = true }

      -- Wire up servers
      local capabilities = require('blink.cmp').get_lsp_capabilities()
      for name, config in pairs(compiled.lsps) do
        config.capabilities = vim.tbl_deep_extend('force', {}, capabilities, config.capabilities or {})

        -- Dynamic configs
        if name == 'jsonls' then
          config.settings.json.schemas = require('schemastore').json.schemas()
        elseif name == 'yamlls' then
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

  --- UI, Aesthetics & Git
  {
    'folke/tokyonight.nvim',
    priority = 1000,
    config = function()
      require('tokyonight').setup { styles = { comments = { italic = false } } }
      vim.cmd.colorscheme 'slate'
    end,
  },
  {
    'lewis6991/gitsigns.nvim',
    opts = {
      signs = {
        add = { text = '+' },
        change = { text = '~' },
        delete = { text = '_' },
        topdelete = { text = '‾' },
        changedelete = { text = '~' },
      },
    },
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
-- 7. EXTERNAL MODULE INJECTION
--=============================================================================
-- 1. Inject declared Kickstart modules
for _, module in ipairs(plugin_registry) do
  table.insert(plugins, require(module))
end

-- 2. Inject Custom Modules hook (automatically loads ~/.config/nvim/lua/custom/plugins/*.lua)
-- This includes the `data-science.lua` file for ML capabilities.
table.insert(plugins, { import = 'custom.plugins' })

--=============================================================================
-- 8. INITIALIZE LAZY.NVIM
--=============================================================================
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
