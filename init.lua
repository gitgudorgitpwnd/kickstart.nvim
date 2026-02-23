--=============================================================================
-- init.lua
-- Metadata-Driven Enterprise SaaS Development Configuration
--
-- ARCHITECTURE OVERVIEW:
-- This configuration embraces a declarative, metadata-first architecture to
-- ensure zero configuration drift across tools.
--
--   - SECTION 2 (Lang Registry): Defines all LSPs, parsers, and formatters.
--   - SECTION 3 (Plugin Registry): Defines external tooling modules to load.
--
-- A compiler engine (Section 4) parses these registries and dynamically
-- injects the requirements into the respective plugin setups (Section 6).
--=============================================================================

--- [USER CHANGE] netrw tweaks
-- Overrides for the built-in netrw file explorer to act more like a sidebar.
-- vim.cmd 'let g:netrw_winsize = 25' -- width %
-- vim.cmd 'let g:netrw_banner = 0' -- hide banner
-- vim.keymap.set('n', ':Vex', ':Vex | wincmd H<CR>')

--=============================================================================
-- 1. GLOBAL VARIABLES & CORE OPTIONS
--=============================================================================

-- Map <space> as the leader key.
-- NOTE: This must happen before plugins are loaded to ensure all plugin
-- keybindings register the correct leader key.
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Enable Nerd Font integration for icons across the UI (Telescope, Neo-tree, etc.)
vim.g.have_nerd_font = true

--- UI & Aesthetics
vim.o.number = true -- Show absolute line numbers for deterministic navigation.
vim.o.signcolumn = 'yes' -- Always show signcolumn to prevent horizontal text shifting when git signs or LSP errors appear.
vim.o.showmode = false -- Hide the default mode text (e.g., "-- INSERT --") since the statusline already handles it.
vim.o.cursorline = true -- Highlight the line currently under the cursor for better visual tracking.
vim.o.scrolloff = 10 -- Maintain 10 lines of context above/below the cursor when scrolling.
vim.o.list = true -- Display normally hidden whitespace characters (spaces, tabs, trailing spaces).
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

--- Editing Behavior & Reliability
vim.o.mouse = 'a' -- Enable mouse support in all modes for quick split resizing and cursor placement.
vim.o.breakindent = true -- Visually wrapped lines will continue with the same indentation level.
vim.o.undofile = true -- Maintain a durable undo history across editor sessions (writes to ~/.local/state/nvim/undo/).
vim.o.updatetime = 250 -- Decrease wait time (in ms) for CursorHold events and swap file writes. Speeds up LSP highlights.
vim.o.timeoutlen = 300 -- Decrease wait time (in ms) for Neovim to wait for a mapped key sequence to complete.
vim.o.confirm = true -- Safely prompt to save unsaved buffers instead of throwing an error on commands like `:q`.

-- Sync OS clipboard with Neovim.
-- Scheduled on a delay (after `UiEnter`) because clipboard tools can significantly increase initial startup time.
vim.schedule(function() vim.o.clipboard = 'unnamedplus' end)

--- Search, Replace & Window Splits
vim.o.ignorecase = true -- Case-insensitive search by default.
vim.o.smartcase = true -- Automatically switch to case-sensitive if the search query contains capital letters.
vim.o.inccommand = 'split' -- Show a live preview of buffer substitutions (e.g., :%s/foo/bar/) in a split window.
vim.o.splitright = true -- When creating vertical splits, open the new window to the right.
vim.o.splitbelow = true -- When creating horizontal splits, open the new window below.

--- General Keymaps
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>', { desc = 'Clear search highlights' })
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- Streamlined window navigation using <Ctrl> + hjkl keys instead of <Ctrl-w> prefixes.
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

--- Diagnostic Config
-- Controls how code analysis errors/warnings are displayed globally.
vim.diagnostic.config {
  update_in_insert = false, -- Defer diagnostic updates until leaving insert mode to prevent distraction.
  severity_sort = true, -- Sort diagnostics by severity (Errors always appear above Warnings).
  float = { border = 'rounded', source = 'if_many' }, -- Style floating diagnostic windows with rounded borders.
  underline = { severity = vim.diagnostic.severity.ERROR }, -- Only underline syntax errors, not warnings.
  virtual_text = true, -- Show inline diagnostic text at the end of the line.
  virtual_lines = false, -- Disable multi-line virtual text to keep the view compact.
  jump = { float = true }, -- Automatically open the float window when jumping between diagnostics.
}
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

-- Highlight text momentarily when yanking (copying) to provide visual feedback.
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function() vim.hl.on_yank() end,
})

--=============================================================================
-- 2. LANGUAGE METADATA REGISTRY (Source of Truth)
--=============================================================================
-- HOW TO USE: To add support for a new language (e.g., Go, Rust), add a new
-- block to this table. Specify the `treesitter` parsers, the `lsp` server
-- (and optional settings), and the `formatters`.
--=============================================================================
local lang_registry = {
  lua = {
    treesitter = { 'lua', 'luadoc', 'luap' },
    lsp = { lua_ls = { settings = { Lua = {} } } },
    formatters = { lua = { 'stylua' } },
  },
  python = {
    treesitter = { 'python' },
    lsp = { basedpyright = {} }, -- Using basedpyright for stricter type checking
    formatters = { python = { 'isort', 'black' } },
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
      -- Formatters inside an array run sequentially.
      -- `stop_after_first = true` tells Conform to use the first available formatter (e.g. prettierd daemon for speed, falling back to prettier).
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
  },
  infra_shell = {
    treesitter = { 'bash', 'dockerfile', 'hcl', 'terraform', 'sql' },
    lsp = { bashls = {}, dockerls = {}, terraformls = {}, sqls = {} },
    formatters = { sh = { 'shfmt' } },
  },
  core = {
    treesitter = { 'c', 'diff', 'query', 'vim', 'vimdoc', 'regex' },
    -- Format on save for C/C++ is disabled dynamically in Conform below to accommodate varied legacy code styles.
  },
}

--=============================================================================
-- 3. PLUGIN MODULE REGISTRY
--=============================================================================
-- Declarative list of external plugin modules to load.
-- Comment out any module string to easily disable that feature without
-- hunting through the codebase. This acts as a feature-flag system.
--=============================================================================
local plugin_registry = {
  -- Core UX & Editor extensions
  'kickstart.plugins.indent_line',
  'kickstart.plugins.autopairs',
  'kickstart.plugins.neo-tree',

  -- Debugging, Testing & Tooling
  'kickstart.plugins.debug',
  'kickstart.plugins.lint',
  'kickstart.plugins.venv-selector',
  'kickstart.plugins.nvim-lint',
  'kickstart.plugins.nvim-dap',
  'kickstart.plugins.neotest',
  'kickstart.plugins.vim-slime',
  'kickstart.plugins.nvim-ts-autotag',
}

--=============================================================================
-- 4. METADATA COMPILER ENGINE
--=============================================================================
-- Parses the `lang_registry` into deterministic arrays and dictionaries that
-- Lazy.nvim plugins expect. This decouples intent from execution.
--=============================================================================
local compiled = {
  treesitter_parsers = {},
  lsps = {},
  formatters_by_ft = {},
  mason_tools = {},
}

-- Helper function to ensure we don't queue duplicate tools for Mason to install
local mason_seen = {}
local function register_mason_tool(tool)
  if type(tool) == 'string' and not mason_seen[tool] then
    table.insert(compiled.mason_tools, tool)
    mason_seen[tool] = true
  end
end

-- Iterate through the registry and compile the configuration structures
for _, config in pairs(lang_registry) do
  -- 1. Extract AST parsers for Treesitter
  if config.treesitter then
    for _, parser in ipairs(config.treesitter) do
      table.insert(compiled.treesitter_parsers, parser)
    end
  end

  -- 2. Extract Language Servers and queue their binaries for Mason installation
  if config.lsp then
    for lsp_name, lsp_opts in pairs(config.lsp) do
      compiled.lsps[lsp_name] = lsp_opts
      register_mason_tool(lsp_name)
    end
  end

  -- 3. Extract Formatters, map them to specific filetypes for Conform, and queue for Mason installation
  if config.formatters then
    for ft, formatters in pairs(config.formatters) do
      compiled.formatters_by_ft[ft] = formatters
      for _, fmt in ipairs(formatters) do
        register_mason_tool(fmt) -- Register e.g., 'prettierd', 'stylua'
      end
    end
  end
end

--=============================================================================
-- 5. PLUGIN MANAGER BOOTSTRAP (Lazy.nvim)
--=============================================================================
-- Automatically clones and installs the lazy.nvim package manager if it doesn't exist.
-- Ensures a reproducible setup on new machines without manual intervention.
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
-- Defines the base plugins required for the IDE.
local plugins = {

  -- Core Editor Utilities
  { 'NMAC427/guess-indent.nvim', opts = {} }, -- Automatically detect and set buffer indentation based on file contents
  {
    'folke/which-key.nvim', -- Displays an interactive popup with possible key bindings
    event = 'VimEnter',
    opts = {
      delay = 0, -- Show immediately upon prefix keypress
      icons = { mappings = vim.g.have_nerd_font },
      spec = {
        -- Document existing key chains for better UI discoverability
        { '<leader>s', group = '[S]earch', mode = { 'n', 'v' } },
        { '<leader>t', group = '[T]oggle' },
        { '<leader>h', group = 'Git [H]unk', mode = { 'n', 'v' } },
      },
    },
  },

  --- Telescope: Fuzzy Finder
  -- Core navigation tool for finding files, grepping text, and inspecting LSP symbols.
  {
    'nvim-telescope/telescope.nvim',
    enabled = true,
    event = 'VimEnter',
    dependencies = {
      'nvim-lua/plenary.nvim',
      -- Native C port of fzf for vastly improved sorting performance
      { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make', cond = function() return vim.fn.executable 'make' == 1 end },
      { 'nvim-telescope/telescope-ui-select.nvim' },
      { 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },
      -- { 'nvim-telescope/telescope-file-browser.nvim' }, -- [USER CHANGE] file browser extension dependency
    },
    config = function()
      require('telescope').setup {
        extensions = {
          -- Hijacks Neovim's default UI selection dialogs (e.g. Code Actions) to use Telescope
          ['ui-select'] = { require('telescope.themes').get_dropdown() },
          -- [USER CHANGE] file browser config: hijack netrw to make telescope the default directory viewer
          -- file_browser = { theme = 'ivy', hijack_netrw = true },
        },
      }

      -- Load extensions if dependencies are satisfied
      pcall(require('telescope').load_extension, 'fzf')
      pcall(require('telescope').load_extension, 'ui-select')
      -- pcall(require('telescope').load_extension, 'file_browser') -- [USER CHANGE]

      -- Standard Telescope Keymaps
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

      -- Fuzzily search lines within the currently open buffer
      vim.keymap.set(
        'n',
        '<leader>/',
        function() builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown { winblend = 10, previewer = false }) end,
        { desc = '[/] Fuzzily search in current buffer' }
      )
      -- Fuzzily search lines across all actively opened buffers
      vim.keymap.set(
        'n',
        '<leader>s/',
        function() builtin.live_grep { grep_open_files = true, prompt_title = 'Live Grep in Open Files' } end,
        { desc = '[S]earch [/] in Open Files' }
      )

      -- [USER CHANGE] file browser specific keymaps
      -- vim.keymap.set('n', '<leader>sb', ':Telescope file_browser<CR>', { desc = '[S]earch [B]rowser (Workspace)' })
      -- vim.keymap.set('n', '<leader>sB', ':Telescope file_browser path=%:p:h select_buffer=true<CR>', { desc = '[S]earch [B]rowser (Current Directory)' })

      -- Contextual LSP Keymaps
      -- These mappings are only registered when an LSP actually attaches to a buffer,
      -- ensuring Telescope doesn't override keys in non-LSP contexts.
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

  --- Treesitter: Syntax Highlighting & AST Parsing
  -- Replaces basic regex-based highlighting with robust Abstract Syntax Tree parsing.
  -- Consumes `compiled.treesitter_parsers` automatically derived from the registry.
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
  -- Ensures code conforms to CI/CD standards automatically on save.
  -- Consumes `compiled.formatters_by_ft` automatically derived from the registry.
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
        -- Disable format-on-save for specific languages without strict standardized styles
        local disable_filetypes = { c = true, cpp = true }
        if disable_filetypes[vim.bo[bufnr].filetype] then return nil end

        -- Apply formatting with a strict timeout to prevent editor locking
        return { timeout_ms = 500, lsp_format = 'fallback' }
      end,
      formatters_by_ft = compiled.formatters_by_ft,
    },
  },

  --- Autocompletion (Blink.cmp)
  -- High-performance, Rust-backed completion engine overriding Neovim's default omnifunc.
  {
    'saghen/blink.cmp',
    build = 'cargo +nightly build --release',
    event = 'VimEnter',
    version = '1.*',
    dependencies = {
      {
        'L3MON4D3/LuaSnip', -- Required snippet engine dependency
        version = '2.*',
        build = (function()
          -- Build Step needed for regex support in snippets (disabled on raw windows environments)
          if vim.fn.has 'win32' == 1 or vim.fn.executable 'make' == 0 then return end
          return 'make install_jsregexp'
        end)(),
        opts = {},
      },
    },
    opts = {
      keymap = {
        preset = 'super-tab',
        -- [USER CHANGE] Custom mapping to easily cycle through completion lists
        -- Maps Alt-j and Alt-k to navigate completion dropdowns and jump through snippet fill-in spots.
        ['<A-j>'] = { 'select_next', 'snippet_forward', 'fallback' },
        ['<A-k>'] = { 'select_prev', 'snippet_backward', 'fallback' },
      },
      appearance = { nerd_font_variant = 'mono' },
      completion = { documentation = { auto_show = false, auto_show_delay_ms = 500 } },
      sources = { default = { 'lsp', 'path', 'snippets' } },
      snippets = { preset = 'luasnip' },
      fuzzy = { implementation = 'prefer_rust_with_warning' },
      signature = { enabled = true }, -- Shows function signature help while typing arguments
    },
  },

  --- LSP Configuration
  -- Manages communication with Language Servers for intelligent IDE features (GoTo Def, Rename, etc).
  -- Dynamically wires up the exact LSPs requested in the `lang_registry`.
  {
    'neovim/nvim-lspconfig',
    dependencies = {
      { 'mason-org/mason.nvim', opts = {} },
      'williamboman/mason-lspconfig.nvim',
      'WhoIsSethDaniel/mason-tool-installer.nvim',
      { 'j-hui/fidget.nvim', opts = {} }, -- UI updates for LSP initialization/progress
      'saghen/blink.cmp', -- Bridges LSP capabilities to the completion engine
      'b0o/SchemaStore.nvim', -- [USER CHANGE] Provides enterprise schema validation for Yaml/JSON (e.g. OpenAPI, Github Actions)
    },
    config = function()
      -- LSP Attach Standard Autocommands
      -- This ensures LSP keymaps are ONLY active in buffers where an LSP is successfully attached.
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
        callback = function(event)
          local map = function(keys, func, desc, mode) vim.keymap.set(mode or 'n', keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc }) end

          -- Core LSP Actions
          map('grn', vim.lsp.buf.rename, '[R]e[n]ame')
          map('gra', vim.lsp.buf.code_action, '[G]oto Code [A]ction', { 'n', 'x' })
          map('grD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

          -- Document highlighting on CursorHold
          -- Illuminates all references to the variable under the cursor if you pause for `updatetime`.
          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if client and client:supports_method('textDocument/documentHighlight', event.buf) then
            local hl_group = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
            vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, { buffer = event.buf, group = hl_group, callback = vim.lsp.buf.document_highlight })
            vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, { buffer = event.buf, group = hl_group, callback = vim.lsp.buf.clear_references })
            -- Clean up the autocommands if the LSP detaches
            vim.api.nvim_create_autocmd('LspDetach', {
              group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
              callback = function(event2)
                vim.lsp.buf.clear_references()
                vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
              end,
            })
          end

          -- Toggle Inline Type Hints (if supported by the connected language server)
          if client and client:supports_method('textDocument/inlayHint', event.buf) then
            map('<leader>th', function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf }) end, '[T]oggle Inlay [H]ints')
          end
        end,
      })

      -- [USER CHANGE] Programmatic Mason installation for defined servers.
      -- We feed the dynamically generated 'compiled.mason_tools' and 'compiled.lsps' tables
      -- into Mason to ensure our environment matches the Registry automatically.
      -- This guarantees no drift between requested tooling and installed tooling.
      require('mason-tool-installer').setup { ensure_installed = compiled.mason_tools }
      require('mason-lspconfig').setup { ensure_installed = vim.tbl_keys(compiled.lsps), automatic_installation = true }

      -- Wire up the servers using capabilities from Blink.cmp
      local capabilities = require('blink.cmp').get_lsp_capabilities()
      for name, config in pairs(compiled.lsps) do
        -- Deep merge default capabilities with any specific capabilities defined in the registry
        config.capabilities = vim.tbl_deep_extend('force', {}, capabilities, config.capabilities or {})

        -- Inject special runtime configurations dynamically to keep the registry clean
        if name == 'jsonls' then
          -- [USER CHANGE] Attach SchemaStore to jsonls for robust enterprise schema validation
          config.settings.json.schemas = require('schemastore').json.schemas()
        elseif name == 'yamlls' then
          -- [USER CHANGE] Attach SchemaStore to yamlls and disable built-in schemas to avoid conflict
          config.settings.yaml.schemaStore = { enable = false, url = '' }
          config.settings.yaml.schemas = require('schemastore').yaml.schemas()
        elseif name == 'lua_ls' then
          -- Recognize Neovim runtime APIs automatically so configuring Neovim doesn't throw warnings
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

        -- Finalize and start the server
        vim.lsp.config(name, config)
        vim.lsp.enable(name)
      end
    end,
  },

  --- UI, Aesthetics & Git Integration
  {
    'folke/tokyonight.nvim',
    priority = 1000, -- Force load before other plugins to prevent visual flashing
    config = function()
      require('tokyonight').setup { styles = { comments = { italic = false } } }
      vim.cmd.colorscheme 'slate'
    end,
  },
  {
    -- Displays git line states (added, modified, removed) in the sign column
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
  {
    -- Highlights comments containing TODO, FIXME, NOTE, etc.
    'folke/todo-comments.nvim',
    event = 'VimEnter',
    dependencies = { 'nvim-lua/plenary.nvim' },
    opts = { signs = false },
  },
  {
    -- Collection of lightweight modules (surround, statusline, ai textobjects)
    'nvim-mini/mini.nvim',
    config = function()
      -- Enhances text objects (e.g. `va)` to select around parenthesis, `yinq` to yank inside quote)
      require('mini.ai').setup { n_lines = 500 }
      -- Quickly surround objects (e.g., `ysiw"` surrounds a word in quotes, `sd'` deletes quotes)
      require('mini.surround').setup()

      -- Minimal and performant Statusline
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
-- Iterate over the `plugin_registry` (Section 3) and inject the requested
-- modules into the runtime `plugins` table.
for _, module in ipairs(plugin_registry) do
  table.insert(plugins, require(module))
end

-- Custom Modules hook (automatically loads any files inside ~/.config/nvim/lua/custom/plugins/)
table.insert(plugins, { import = 'custom.plugins' })

--=============================================================================
-- 8. INITIALIZE LAZY.NVIM
--=============================================================================
require('lazy').setup(plugins, {
  ui = {
    -- Use Nerd Font icons if available in the Lazy plugin installer UI
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
