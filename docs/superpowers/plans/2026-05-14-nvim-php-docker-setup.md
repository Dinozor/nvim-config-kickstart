# Neovim PHP Docker Setup + Warning Fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix all startup/checkhealth warnings and wire up PHP LSP, formatting, and testing to run inside Docker Compose.

**Architecture:** Replace the local-PHP-dependent `phpactor` with `intelephense` (Node.js, Mason-installable). Override `php_cs_fixer` and `phpunit` to delegate to `docker compose exec`. A `vim.g.php_service` global (default `"app"`) controls the Docker service name and can be overridden per-project via `.nvim.lua`.

**Tech Stack:** Neovim (Lua config), lazy.nvim, mason.nvim, nvim-lspconfig, conform.nvim, nvim-lint, neotest + neotest-phpunit, Docker Compose.

---

### Task 1: Replace phpactor + gdtoolkit with intelephense in servers table

**Files:**
- Modify: `init.lua:696-743`

The `phpactor` entry requires a local PHP runtime (not available). The `gdtoolkit` entry is a duplicate — GDScript LSP is already configured at the bottom of `init.lua` via `vim.lsp.config('gdscript', ...)`, so Mason tries to install an unknown package name. Replace both with `intelephense = {}`.

- [ ] **Step 1: Edit the servers table**

In `init.lua`, replace lines 697–715:

Old content:
```lua
      local servers = {
        gdtoolkit = {},
        vala_ls = {},
        phpactor = {
          -- capabilities = capabilities,
          settings = {
            phpactor = {
              enable = true,
              phpstan = {
                enable = true,
              },
              completion = {
                enable = true,
              },
              index = {
                stubs = 'vendor/php-stubs',
              },
            },
          },
        },
```

New content:
```lua
      local servers = {
        vala_ls = {},
        intelephense = {},
```

- [ ] **Step 2: Verify Neovim starts without errors**

Open Neovim: `nvim`
Expected: no startup error messages about `phpactor` or `gdtoolkit`.

- [ ] **Step 3: Commit**

```bash
git add init.lua
git commit -m "fix: replace phpactor+gdtoolkit with intelephense in servers table"
```

---

### Task 2: Add vim.g.php_service global and vim.o.exrc option

**Files:**
- Modify: `init.lua:90-95` (globals section) and `init.lua:96-168` (options section)

`vim.g.php_service` is the Docker service name used by the formatter and test runner. `vim.o.exrc` lets Neovim auto-load a `.nvim.lua` from the project root so you can override it per project.

- [ ] **Step 1: Add php_service global after existing globals (line 94)**

In `init.lua`, find:
```lua
-- Set to true if you have a Nerd Font installed and selected in the terminal
vim.g.have_nerd_font = true
```

Replace with:
```lua
-- Set to true if you have a Nerd Font installed and selected in the terminal
vim.g.have_nerd_font = true

-- Docker Compose service name for PHP tools (php_cs_fixer, phpunit).
-- Override per project by adding `vim.g.php_service = 'php'` to .nvim.lua at project root.
vim.g.php_service = 'app'
```

- [ ] **Step 2: Add exrc to the options block**

In `init.lua`, find:
```lua
-- if performing an operation that would fail due to unsaved changes in the buffer (like `:q`),
-- instead raise a dialog asking if you wish to save the current file(s)
-- See `:help 'confirm'`
vim.o.confirm = true
```

Replace with:
```lua
-- if performing an operation that would fail due to unsaved changes in the buffer (like `:q`),
-- instead raise a dialog asking if you wish to save the current file(s)
-- See `:help 'confirm'`
vim.o.confirm = true

-- Load .nvim.lua from project root (Neovim prompts to trust the first time).
vim.o.exrc = true
```

- [ ] **Step 3: Verify options load cleanly**

Open Neovim and run:
```
:lua print(vim.g.php_service)
```
Expected output: `app`

- [ ] **Step 4: Commit**

```bash
git add init.lua
git commit -m "feat: add php_service global and exrc for per-project Docker service override"
```

---

### Task 3: Override php_cs_fixer formatter to run via Docker exec

**Files:**
- Modify: `init.lua:795-821` (conform.nvim opts)

Add a `formatters` table that overrides the built-in `php_cs_fixer` entry to delegate to `docker compose exec`. The formatter reads `vim.g.php_service` at call time so it always picks up the current project's service name.

- [ ] **Step 1: Add formatters table to conform.nvim opts**

In `init.lua`, find:
```lua
      formatters_by_ft = {
        lua = { 'stylua' },
        gdscript = { 'gdformat' },
        php = { 'php_cs_fixer' },
        -- Conform can also run multiple formatters sequentially
        -- python = { "isort", "black" },
        --
        -- You can use 'stop_after_first' to run the first available formatter from the list
        -- javascript = { "prettierd", "prettier", stop_after_first = true },
      },
```

Replace with:
```lua
      formatters = {
        php_cs_fixer = {
          command = 'docker',
          args = function(_, ctx)
            local service = vim.g.php_service or 'app'
            return { 'compose', 'exec', '-T', service, 'vendor/bin/php-cs-fixer', 'fix', '--path-mode=intersection', '--', ctx.filename }
          end,
          stdin = false,
        },
      },
      formatters_by_ft = {
        lua = { 'stylua' },
        gdscript = { 'gdformat' },
        php = { 'php_cs_fixer' },
        -- Conform can also run multiple formatters sequentially
        -- python = { "isort", "black" },
        --
        -- You can use 'stop_after_first' to run the first available formatter from the list
        -- javascript = { "prettierd", "prettier", stop_after_first = true },
      },
```

- [ ] **Step 2: Verify conform loads without errors**

Open Neovim and run:
```
:ConformInfo
```
Expected: `php_cs_fixer` appears in the PHP formatters list. No error messages.

- [ ] **Step 3: Commit**

```bash
git add init.lua
git commit -m "feat: route php_cs_fixer through docker compose exec"
```

---

### Task 4: Add markdownlint to Mason ensure_installed

**Files:**
- Modify: `init.lua:759-761`

`markdownlint` is configured as a linter in `lua/kickstart/plugins/lint.lua` but was never added to Mason's install list, causing a `:checkhealth` warning that the tool is missing.

- [ ] **Step 1: Add markdownlint to ensure_installed**

In `init.lua`, find:
```lua
      vim.list_extend(ensure_installed, {
        'stylua', -- Used to format Lua code
      })
```

Replace with:
```lua
      vim.list_extend(ensure_installed, {
        'stylua',
        'markdownlint',
      })
```

- [ ] **Step 2: Install the new tool**

Open Neovim and run:
```
:MasonToolsInstall
```
Expected: `markdownlint` installs successfully.

- [ ] **Step 3: Verify checkhealth**

In Neovim run:
```
:checkhealth nvim-lint
```
Expected: no warning about `markdownlint` missing.

- [ ] **Step 4: Commit**

```bash
git add init.lua
git commit -m "fix: add markdownlint to Mason ensure_installed"
```

---

### Task 5: Fix neotest-phpunit double-setup and route phpunit through Docker

**Files:**
- Modify: `lua/custom/plugins/nvim-neotest.lua`

The current config has a broken double-call pattern: `neotest.setup()` receives an unconfigured adapter module, then the adapter is called again separately with options — that second call is a no-op. Fix by passing the configured adapter (with `phpunit_cmd`) directly inside `setup()`.

- [ ] **Step 1: Rewrite nvim-neotest.lua**

Replace the entire file content with:
```lua
return {
  'nvim-neotest/neotest',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'antoinemadec/FixCursorHold.nvim',
    'nvim-treesitter/nvim-treesitter',
    'olimorris/neotest-phpunit',
    'nvim-neotest/nvim-nio',
  },
  config = function()
    require('neotest').setup {
      adapters = {
        require('neotest-phpunit') {
          phpunit_cmd = function()
            local service = vim.g.php_service or 'app'
            return { 'docker', 'compose', 'exec', '-T', service, 'vendor/bin/phpunit' }
          end,
        },
      },
    }
  end,
}
```

- [ ] **Step 2: Verify neotest loads without errors**

Open Neovim and run:
```
:lua require('neotest')
```
Expected: no error. Then run:
```
:checkhealth neotest
```
Expected: neotest-phpunit adapter listed as configured, no errors.

- [ ] **Step 3: Commit**

```bash
git add lua/custom/plugins/nvim-neotest.lua
git commit -m "fix: correct neotest-phpunit setup, route phpunit through docker compose exec"
```

---

## Final Verification

After all tasks, open Neovim and run a full health check:

```
:checkhealth
```

Expected clean areas:
- `mason`: no unknown package errors
- `nvim-lint`: `markdownlint` found
- `neotest`: adapter configured correctly
- No startup messages about missing LSP servers or failed installs

Also verify Mason installs intelephense:
```
:Mason
```
Expected: `intelephense` listed and installed (green checkmark).
