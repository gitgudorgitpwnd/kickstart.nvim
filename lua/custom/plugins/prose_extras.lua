--=============================================================================
-- custom/prose_extras.lua
-- Optional writing workflow helpers extracted from init.lua section 5B.
-- Loaded conditionally from init.lua via a metadata-driven toggle.
--=============================================================================

local M = {}

function M.setup(opts)
  opts = opts or {}
  local WRITING = opts.WRITING
  local is_enabled = opts.is_enabled or function(_) return false end

  if type(WRITING) ~= 'table' then
    error('custom.prose_extras.setup requires opts.WRITING (table)')
  end

--=============================================================================
-- 5B. WRITING WORKFLOW HELPERS (Prose Mode, Templates, Exports, Autocmds)
--=============================================================================
-- This section is the "workflow glue" for writing/docs:
--   * FileType autocmds for prose-friendly defaults
--   * `:Prose` toggle for distraction-free editing behavior
--   * Template commands for PRD / PRFAQ / meeting notes
--   * Pandoc export commands for PDF / DOCX
--   * Writing keymaps under <leader>w...
--=============================================================================

-- ============================================================================
-- PROSE MODE CONFIGURATION (metadata-driven / easy to tweak)
-- ============================================================================
--An optional improvement to "hide" diagnostics instead of turning
-- them off. This toggle controls which strategy Prose mode uses:
--
--   "disable" => disables diagnostics for the current buffer (recommended)
--   "hide"    => keeps diagnostics enabled, but hides the decorations while
--                writing (visual-only; diagnostics still exist)
--
local function prose_diagnostic_mode()
  -- Keep the behavior knob inside the WRITING control plane for consistency.
  return (WRITING.prose and WRITING.prose.diagnostic_mode) or 'hide'
end

-- Buffer-local autocmd group management for prose diagnostics hide mode.
local prose_diag_augroup = vim.api.nvim_create_augroup('UserProseDiagnostics', { clear = true })

-- Helper: hide diagnostics decorations for the current buffer (visual-only).
local function prose_hide_diagnostics(bufnr) vim.diagnostic.hide(nil, bufnr) end

-- Helper: re-show diagnostics decorations for the current buffer.
local function prose_show_diagnostics(bufnr) vim.diagnostic.show(nil, bufnr) end

-- Helper: apply prose diagnostic behavior (disable OR hide)
local function prose_diagnostics_on(bufnr)
  if prose_diagnostic_mode() == 'disable' then
    -- Recommended mode: fully disable diagnostics for this buffer.
    vim.diagnostic.enable(false, { bufnr = bufnr })
    vim.api.nvim_clear_autocmds { group = prose_diag_augroup, buffer = bufnr }
  else
    -- Optional mode: hide diagnostics visually, but keep them enabled.
    prose_hide_diagnostics(bufnr)
    vim.api.nvim_clear_autocmds { group = prose_diag_augroup, buffer = bufnr }
    -- Re-hide if diagnostics are updated while Prose mode is active.
    vim.api.nvim_create_autocmd('DiagnosticChanged', {
      group = prose_diag_augroup,
      buffer = bufnr,
      desc = 'Keep diagnostics hidden while Prose mode is active',
      callback = function()
        if vim.b.prose_mode_active then prose_hide_diagnostics(bufnr) end
      end,
    })
  end
end

-- Helper: restore diagnostics behavior when leaving Prose mode
local function prose_diagnostics_off(bufnr)
  if prose_diagnostic_mode() == 'disable' then
    vim.diagnostic.enable(true, { bufnr = bufnr })
  else
    vim.api.nvim_clear_autocmds { group = prose_diag_augroup, buffer = bufnr }
    prose_show_diagnostics(bufnr)
  end
end

-- Helper: apply visual-line movement keymaps for wrapped prose
local function prose_set_wrapped_movement_keymaps(bufnr)
  vim.keymap.set('n', 'j', 'gj', { buffer = bufnr, silent = true, desc = 'Prose mode: move down by visual line' })
  vim.keymap.set('n', 'k', 'gk', { buffer = bufnr, silent = true, desc = 'Prose mode: move up by visual line' })
end

-- Helper: remove prose movement keymaps and restore defaults
local function prose_clear_wrapped_movement_keymaps(bufnr)
  pcall(vim.keymap.del, 'n', 'j', { buffer = bufnr })
  pcall(vim.keymap.del, 'n', 'k', { buffer = bufnr })
end

-- Helper: snapshot local buffer/window options so :Prose acts like a temporary
-- overlay (and restores the user's original state on exit).
local function prose_snapshot_buffer_state(bufnr)
  if vim.b[bufnr].prose_saved_opts then return end

  vim.b[bufnr].prose_saved_opts = {
    wrap = vim.wo[0].wrap,
    linebreak = vim.wo[0].linebreak,
    breakindent = vim.wo[0].breakindent,
    cursorline = vim.wo[0].cursorline,
    spell = vim.wo[0].spell,
    spelllang = vim.opt_local.spelllang:get(),
    expandtab = vim.bo[bufnr].expandtab,
  }
end

local function prose_restore_buffer_state(bufnr)
  local saved = vim.b[bufnr].prose_saved_opts
  if type(saved) ~= 'table' then return false end

  vim.wo[0].wrap = saved.wrap
  vim.wo[0].linebreak = saved.linebreak
  vim.wo[0].breakindent = saved.breakindent
  vim.wo[0].cursorline = saved.cursorline
  vim.wo[0].spell = saved.spell
  vim.opt_local.spelllang = saved.spelllang
  vim.bo[bufnr].expandtab = saved.expandtab

  vim.b[bufnr].prose_saved_opts = nil
  return true
end

-- Slugify helper used for auto-generating filenames from titles.
local function writing_slugify(input)
  local s = (input or ''):lower()
  s = s:gsub('[^%w%s%-_]', '') -- remove punctuation
  s = s:gsub('%s+', '-') -- spaces -> hyphen
  s = s:gsub('%-+', '-') -- collapse repeated hyphens
  s = s:gsub('^%-', ''):gsub('%-$', '')
  if s == '' then s = 'untitled' end
  return s
end

-- Small utility to ensure a directory exists.
local function writing_ensure_dir(dir)
  if dir and dir ~= '' then vim.fn.mkdir(dir, 'p') end
end

-- Build a date-stamped markdown filename.
local function writing_dated_filename(title, suffix)
  local date_prefix = os.date '%Y-%m-%d'
  local slug = writing_slugify(title)
  local parts = { date_prefix, slug }
  if suffix and suffix ~= '' then table.insert(parts, writing_slugify(suffix)) end
  return table.concat(parts, '-') .. '.md'
end

-- Open a file and insert a template only if the file is empty.
local function writing_open_from_template(target_dir, filename, template_lines)
  writing_ensure_dir(target_dir)
  local fullpath = target_dir .. '/' .. filename

  -- Open the target document.
  vim.cmd.edit(vim.fn.fnameescape(fullpath))

  -- Populate template if the file is currently empty.
  local buf = vim.api.nvim_get_current_buf()
  local existing = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local is_empty = (#existing == 1 and existing[1] == '') or #existing == 0
  if is_empty then
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, template_lines)
    vim.bo[buf].modified = true
  end

  return fullpath
end

-- Simple reusable heading helper for markdown templates.
local function writing_template_heading(title)
  return {
    '# ' .. title,
    '',
    '> Created: ' .. os.date '%Y-%m-%d %H:%M',
    '> Author: ' .. (vim.env.USER or 'user'),
    '',
  }
end

-- Template factory: PRD (Product Requirements Document)
local function writing_template_prd(title)
  local lines = writing_template_heading(title)
  vim.list_extend(lines, {
    '## 1. Problem Statement',
    '- What user/customer problem are we solving?',
    '- Why now?',
    '',
    '## 2. Goals',
    '- Primary goal:',
    '- Secondary goal(s):',
    '',
    '## 3. Non-Goals',
    '- Explicitly out of scope:',
    '',
    '## 4. Users / Personas',
    '- Primary persona:',
    '- Secondary persona:',
    '',
    '## 5. Use Cases / User Stories',
    '- As a ..., I want ..., so that ...',
    '',
    '## 6. Requirements',
    '### Functional Requirements',
    '- [ ] Requirement 1',
    '- [ ] Requirement 2',
    '',
    '### Non-Functional Requirements',
    '- Performance:',
    '- Reliability:',
    '- Security / Privacy:',
    '- Compliance:',
    '',
    '## 7. UX / Workflow',
    '- Key user flows',
    '- Edge cases',
    '',
    '## 8. Success Metrics',
    '- KPI 1:',
    '- KPI 2:',
    '',
    '## 9. Risks and Mitigations',
    '- Risk:',
    '  - Mitigation:',
    '',
    '## 10. Open Questions',
    '- [ ] Question 1',
    '',
    '## 11. Launch / Rollout Plan',
    '- Milestones',
    '- Dependencies',
    '',
    '## 12. Appendix',
    '- Links',
    '- References',
    '',
  })
  return lines
end

-- Template factory: PR/FAQ
local function writing_template_prfaq(title)
  local lines = writing_template_heading(title)
  vim.list_extend(lines, {
    '## Press Release',
    '',
    '### Headline',
    '- One clear customer-facing headline',
    '',
    '### Sub-headline',
    '- One supporting line that sharpens the value proposition',
    '',
    '### Body',
    '- Paragraph 1: customer problem + why current options are insufficient',
    '- Paragraph 2: the solution and what is new',
    '- Paragraph 3: how it works (high level)',
    '- Paragraph 4: customer/partner quote',
    '- Paragraph 5: leader/team quote',
    '- Paragraph 6: availability / rollout',
    '',
    '## FAQ',
    '',
    '### Customer FAQ',
    '#### 1) What problem does this solve?',
    '-',
    '',
    '#### 2) Who is this for?',
    '-',
    '',
    '#### 3) Why is this better than alternatives?',
    '-',
    '',
    '#### 4) What does it cost (if relevant)?',
    '-',
    '',
    '### Internal FAQ',
    '#### 1) What are the key assumptions?',
    '-',
    '',
    '#### 2) What are the biggest risks?',
    '-',
    '',
    '#### 3) What dependencies exist (eng, design, legal, GTM, etc.)?',
    '-',
    '',
    '#### 4) How will success be measured?',
    '-',
    '',
    '#### 5) What is the rollout plan?',
    '-',
    '',
  })
  return lines
end

-- Template factory: Meeting Notes
local function writing_template_meeting_notes(title)
  local lines = writing_template_heading(title)
  vim.list_extend(lines, {
    '## Meeting Details',
    '- Topic:',
    '- Date:',
    '- Participants:',
    '',
    '## Agenda',
    '-',
    '',
    '## Notes',
    '-',
    '',
    '## Decisions',
    '- #decision ',
    '',
    '## Action Items',
    '- [ ] Action item @owner due:YYYY-MM-DD',
    '',
    '## Risks / Blocks',
    '- #blocked ',
    '',
    '## Follow-ups',
    '-',
    '',
  })
  return lines
end

-- Create a document command that supports:
--   * optional title argument (uses prompt if omitted)
--   * date-stamped filenames
--   * auto template insertion
local function writing_create_doc_command(spec)
  vim.api.nvim_create_user_command(spec.command, function(opts)
    local title = opts.args
    if not title or title == '' then
      title = vim.fn.input(spec.prompt)
      if title == '' then title = spec.default_title end
    end

    local filename = writing_dated_filename(title, spec.filename_suffix)
    local fullpath = writing_open_from_template(spec.dir, filename, spec.template(title))

    vim.notify('Created/opened: ' .. fullpath, vim.log.levels.INFO, { title = spec.command })
  end, {
    nargs = '?',
    desc = spec.desc,
  })
end

-- Pandoc export helper used by :ExportPDF and :ExportDocx
local function writing_export_with_pandoc(output_ext, explicit_output)
  if not WRITING.pandoc.enabled then
    vim.notify('Pandoc export is disabled in WRITING.pandoc.enabled', vim.log.levels.WARN, { title = 'Pandoc Export' })
    return
  end

  if vim.fn.executable 'pandoc' ~= 1 then
    vim.notify('pandoc is not installed or not in PATH. Install pandoc to use export commands.', vim.log.levels.ERROR, { title = 'Pandoc Export' })
    return
  end

  local src = vim.fn.expand '%:p'
  if src == '' then
    vim.notify('Save the current buffer to a file before exporting.', vim.log.levels.WARN, { title = 'Pandoc Export' })
    return
  end

  if vim.bo.modified then vim.cmd.write() end

  local dst = explicit_output
  if not dst or dst == '' then dst = vim.fn.expand '%:p:r' .. '.' .. output_ext end

  local cmd = { 'pandoc', src, '-o', dst }
  if output_ext == 'pdf' and WRITING.pandoc.pdf_engine and WRITING.pandoc.pdf_engine ~= '' then
    table.insert(cmd, '--pdf-engine=' .. WRITING.pandoc.pdf_engine)
  end

  -- Prefer list-based process execution (no shell string concatenation). This is
  -- easier to extend safely and easier for beginners to reason about.
  if vim.system then
    local result = vim.system(cmd, { text = true }):wait()
    if result.code ~= 0 then
      local details = (result.stderr and result.stderr ~= '' and result.stderr) or result.stdout or ''
      vim.notify('Pandoc export failed: ' .. details, vim.log.levels.ERROR, { title = 'Pandoc Export' })
      return
    end
  else
    local out = vim.fn.system(cmd)
    if vim.v.shell_error ~= 0 then
      vim.notify('Pandoc export failed: ' .. out, vim.log.levels.ERROR, { title = 'Pandoc Export' })
      return
    end
  end

  vim.notify('Exported: ' .. dst, vim.log.levels.INFO, { title = 'Pandoc Export' })
end

local function register_writing_autocmds()
  local prose_group = vim.api.nvim_create_augroup('kickstart-writing-defaults', { clear = true })

  vim.api.nvim_create_autocmd('FileType', {
    group = prose_group,
    pattern = WRITING.prose_filetypes,
    desc = 'Apply prose-friendly defaults for writing-oriented filetypes',
    callback = function(args)
      if vim.bo[args.buf].buftype ~= '' then return end
      local buf = args.buf
      local ft = vim.bo[buf].filetype

      -- Baseline writing ergonomics (not as aggressive as :Prose)
      vim.opt_local.wrap = WRITING.defaults.wrap
      vim.opt_local.linebreak = WRITING.defaults.linebreak
      vim.opt_local.breakindent = WRITING.defaults.breakindent
      vim.opt_local.spell = WRITING.defaults.spell
      vim.opt_local.spelllang = WRITING.defaults.spelllang
      vim.opt_local.textwidth = WRITING.defaults.textwidth
      vim.opt_local.colorcolumn = WRITING.defaults.colorcolumn
      vim.opt_local.cursorline = WRITING.defaults.cursorline

      -- Better paragraph/list formatting behavior in prose buffers
      vim.opt_local.formatoptions:append { 't', 'c', 'r', 'o', 'q', 'n', 'j' }

      -- Markdown-like filetypes benefit from conceal for cleaner visuals
      if ft == 'markdown' or ft == 'vimwiki' or ft == 'norg' then vim.opt_local.conceallevel = WRITING.defaults.conceallevel_markdown end
    end,
  })
end

local function register_writing_commands()
  -- ============================================================================
  -- :Prose (toggle prose-writing profile for the CURRENT BUFFER)
  -- ============================================================================
  -- What this command does:
  --   - Wrap + linebreak + breakindent
  --   - Spell check on/off
  --   - Cursorline off/on
  --   - Diagnostic handling:
  --       * "disable" mode => disables diagnostics for this buffer
  --       * "hide" mode    => hides decorations only, diagnostics remain enabled
  --   - j/k move by visual lines while in prose mode
  vim.api.nvim_create_user_command('Prose', function()
    local bufnr = vim.api.nvim_get_current_buf()
    local is_on = vim.b[bufnr].prose_mode_active or false

    if is_on then
      -- TURN OFF PROSE MODE
      vim.b[bufnr].prose_mode_active = false

      -- Restore the exact local state from before :Prose was enabled.
      local restored = prose_restore_buffer_state(bufnr)
      if not restored then
        -- Fallback (should be rare): restore reasonable defaults if no snapshot exists.
        vim.wo[0].breakindent = WRITING.defaults.breakindent
        vim.bo[bufnr].expandtab = true
        vim.wo[0].wrap = WRITING.defaults.wrap
        vim.wo[0].linebreak = WRITING.defaults.linebreak
        vim.wo[0].spell = WRITING.defaults.spell
        vim.opt_local.spelllang = WRITING.defaults.spelllang
        vim.wo[0].cursorline = WRITING.defaults.cursorline
      end

      prose_diagnostics_off(bufnr)
      prose_clear_wrapped_movement_keymaps(bufnr)
      print 'Prose Mode: OFF'
    else
      -- TURN ON PROSE MODE
      prose_snapshot_buffer_state(bufnr)
      vim.b[bufnr].prose_mode_active = true
      vim.wo[0].breakindent = true
      vim.bo[bufnr].expandtab = true
      vim.wo[0].wrap = true
      vim.wo[0].linebreak = true
      vim.wo[0].spell = true
      vim.opt_local.spelllang = 'en_us'
      vim.wo[0].cursorline = false

      prose_diagnostics_on(bufnr)
      prose_set_wrapped_movement_keymaps(bufnr)
      print('Prose Mode: ON (' .. prose_diagnostic_mode() .. ' diagnostics)')
    end
  end, {
    desc = 'Toggle buffer-local Prose writing mode',
  })

  -- Explicit variants (nice for scripts/mappings)
  vim.api.nvim_create_user_command('ProseOn', function()
    if not vim.b.prose_mode_active then vim.cmd 'Prose' end
  end, { desc = 'Enable Prose Mode for current buffer' })

  vim.api.nvim_create_user_command('ProseOff', function()
    if vim.b.prose_mode_active then vim.cmd 'Prose' end
  end, { desc = 'Disable Prose Mode for current buffer' })

  -- ============================================================================
  -- :CheckWritingDeps (Check availability of prose tools)
  -- ============================================================================
  vim.api.nvim_create_user_command('CheckWritingDeps', function()
    local deps = {
      { cmd = 'pandoc', label = 'Pandoc (PDF/DOCX export)' },
      { cmd = 'node', label = 'Node.js (markdown-preview.nvim)' },
      { cmd = 'vale', label = 'Vale (prose linting)' },
      { cmd = 'markdownlint', label = 'markdownlint (Markdown linting)' },
    }

    local lines = { 'Writing / document tooling dependency check:', '------------------------------------------' }
    for _, dep in ipairs(deps) do
      local ok = (vim.fn.executable(dep.cmd) == 1)
      local mark = ok and 'OK  ' or 'MISSING'
      table.insert(lines, string.format('[%s] %-12s - %s', mark, dep.cmd, dep.label))
    end
    vim.notify(table.concat(lines, '\n'), vim.log.levels.INFO, { title = 'CheckWritingDeps' })
  end, {
    desc = 'Check availability of writing/prose CLI dependencies',
  })

  -- Template-driven document creation commands
  writing_create_doc_command {
    command = 'NewPRD',
    prompt = 'PRD title: ',
    default_title = 'Product Requirements Document',
    filename_suffix = 'prd',
    dir = WRITING.paths.prd,
    template = writing_template_prd,
    desc = 'Create/open a new PRD markdown document from template',
  }

  writing_create_doc_command {
    command = 'NewPRFAQ',
    prompt = 'PRFAQ title: ',
    default_title = 'Press Release FAQ',
    filename_suffix = 'prfaq',
    dir = WRITING.paths.prfaq,
    template = writing_template_prfaq,
    desc = 'Create/open a new PRFAQ markdown document from template',
  }

  writing_create_doc_command {
    command = 'NewMeetingNotes',
    prompt = 'Meeting notes title: ',
    default_title = 'Meeting Notes',
    filename_suffix = 'notes',
    dir = WRITING.paths.meeting_notes,
    template = writing_template_meeting_notes,
    desc = 'Create/open meeting notes markdown document from template',
  }

  -- Optional Pandoc export commands
  vim.api.nvim_create_user_command('ExportPDF', function(opts) writing_export_with_pandoc('pdf', opts.args) end, {
    nargs = '?',
    complete = 'file',
    desc = 'Export current document to PDF using pandoc',
  })

  vim.api.nvim_create_user_command('ExportDocx', function(opts) writing_export_with_pandoc('docx', opts.args) end, {
    nargs = '?',
    complete = 'file',
    desc = 'Export current document to DOCX using pandoc',
  })
end

local function register_writing_keymaps()
  -- All writing keymaps live under <leader>w... for discoverability.
  vim.keymap.set('n', '<leader>wp', '<cmd>Prose<CR>', { desc = '[W]riting [P]rose mode toggle' })

  vim.keymap.set('n', '<leader>wz', function()
    if not is_enabled 'zen_mode' then
      vim.notify('Zen Mode plugin is disabled in FEATURES.plugins.zen_mode', vim.log.levels.WARN)
      return
    end
    vim.cmd 'ZenMode'
  end, { desc = '[W]riting [Z]en mode' })

  vim.keymap.set('n', '<leader>ww', function()
    if not is_enabled 'twilight' then
      vim.notify('Twilight plugin is disabled in FEATURES.plugins.twilight', vim.log.levels.WARN)
      return
    end
    vim.cmd 'Twilight'
  end, { desc = '[W]riting T[w]ilight toggle' })

  vim.keymap.set('n', '<leader>wm', function()
    if not is_enabled 'markdown_preview' then
      vim.notify('markdown-preview.nvim is installed but currently disabled (FEATURES.plugins.markdown_preview=false).', vim.log.levels.WARN)
      return
    end
    vim.cmd 'MarkdownPreviewToggle'
  end, { desc = '[W]riting [M]arkdown preview toggle' })

  vim.keymap.set('n', '<leader>wT', function()
    if not is_enabled 'table_mode' then
      vim.notify('vim-table-mode is disabled in FEATURES.plugins.table_mode', vim.log.levels.WARN)
      return
    end
    vim.cmd 'TableModeToggle'
  end, { desc = '[W]riting [T]able mode toggle' })

  vim.keymap.set('n', '<leader>wl', function()
    local ok, lint = pcall(require, 'lint')
    if not ok then
      vim.notify('nvim-lint is not available yet (plugin not loaded). Open a file first or trigger lazy-loading.', vim.log.levels.WARN)
      return
    end
    lint.try_lint()
  end, { desc = '[W]riting [L]int now (nvim-lint)' })

  vim.keymap.set('n', '<leader>ws', 'z=', { desc = '[W]riting [S]pelling suggestions' })

  -- Template commands
  vim.keymap.set('n', '<leader>wr', '<cmd>NewPRD<CR>', { desc = '[W]riting new P[R]D' })
  vim.keymap.set('n', '<leader>wq', '<cmd>NewPRFAQ<CR>', { desc = '[W]riting new PRFA[Q]' })
  vim.keymap.set('n', '<leader>wn', '<cmd>NewMeetingNotes<CR>', { desc = '[W]riting meeting [N]otes' })

  -- Export commands (Pandoc)
  vim.keymap.set('n', '<leader>wP', '<cmd>ExportPDF<CR>', { desc = '[W]riting export [P]DF' })
  vim.keymap.set('n', '<leader>wD', '<cmd>ExportDocx<CR>', { desc = '[W]riting export [D]OCX' })

  -- Neorg convenience mappings (only if the plugin feature is enabled)
  if is_enabled 'neorg' then
    vim.keymap.set('n', '<leader>ni', '<cmd>Neorg index<CR>', { desc = '[N]eorg [I]ndex' })
    vim.keymap.set('n', '<leader>nj', '<cmd>Neorg journal today<CR>', { desc = '[N]eorg [J]ournal today' })
    vim.keymap.set('n', '<leader>nw', '<cmd>Neorg workspace notes<CR>', { desc = '[N]eorg [W]orkspace notes' })
  end
end

-- Register writing workflow features after all helper functions are defined.
register_writing_autocmds()
register_writing_commands()
register_writing_keymaps()

end

return M
