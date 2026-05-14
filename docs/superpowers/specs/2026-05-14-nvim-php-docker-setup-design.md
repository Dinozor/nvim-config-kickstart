# Neovim Config: Fix Warnings + PHP Docker Setup

**Date:** 2026-05-14
**Status:** Approved

## Context

Kickstart.nvim-based config running on WSL2 Ubuntu. PHP development is done entirely inside Docker Compose — no local PHP installation. The config already has partial PHP tooling (phpactor, php_cs_fixer, neotest-phpunit) but none of it works because phpactor and php_cs_fixer both require a local PHP runtime. Several checkhealth and startup warnings exist from misconfigured or missing tools.

## Goals

1. Fix all startup and `:checkhealth` warnings (config-only changes, no plugin source)
2. Make PHP LSP, formatting, and testing work via Docker Compose
3. Keep GDScript/Vala tooling intact

## Constraints

- PHP only runs inside Docker Compose (no local PHP in WSL2)
- Docker service name varies per project (typically `app` or `php`)
- Changes limited to config files only

---

## Section 1: LSP — Replace phpactor with intelephense

**File:** `init.lua` (servers table)

- Remove `phpactor` — requires local PHP, cannot run without it
- Remove `gdtoolkit` from servers table — GDScript LSP is already configured separately via `vim.lsp.config('gdscript', ...)` at the bottom of `init.lua`; having it in servers causes a duplicate Mason install error
- Add `intelephense` — Node.js-based PHP LSP, Mason installs it via npm, no PHP runtime required

```lua
local servers = {
  vala_ls = {},
  intelephense = {},
  lua_ls = {
    settings = {
      Lua = {
        completion = { callSnippet = 'Replace' },
      },
    },
  },
}
```

---

## Section 2: Formatter — php_cs_fixer via Docker exec

**File:** `init.lua` (top-level global) + `init.lua` (conform.nvim opts)

Add a `vim.g.php_service` global defaulting to `"app"` so the Docker service name is configurable per project without editing the config.

Override the built-in `php_cs_fixer` formatter in conform.nvim to delegate to Docker:

```lua
-- Near top of init.lua (after mapleader, before lazy.setup):
vim.g.php_service = 'app'

-- In conform.nvim opts:
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
```

---

## Section 3: Testing — Fix neotest-phpunit setup

**File:** `lua/custom/plugins/nvim-neotest.lua`

The current config calls `neotest.setup()` once with an unconfigured adapter, then calls the adapter again separately — the second call is ignored and options never apply. Fix by passing the configured adapter directly inside `setup()`, routed through Docker:

```lua
config = function()
  require('neotest').setup({
    adapters = {
      require('neotest-phpunit')({
        phpunit_cmd = function()
          local service = vim.g.php_service or 'app'
          return { 'docker', 'compose', 'exec', '-T', service, 'vendor/bin/phpunit' }
        end,
      }),
    },
  })
end
```

---

## Section 4: Remaining Warning Fixes

### markdownlint missing from Mason
**File:** `init.lua` (ensure_installed list)

Add `'markdownlint'` to the `ensure_installed` list passed to `mason-tool-installer`. It is already configured as a linter in `lua/kickstart/plugins/lint.lua` but was never added to Mason.

### exrc for per-project service override
**File:** `init.lua` (options section)

Enable `vim.o.exrc = true` so Neovim auto-loads a `.nvim.lua` from the project root. Neovim will prompt you to trust the file the first time (safe by default). Projects with a non-default service name can then drop:

```lua
-- .nvim.lua at project root
vim.g.php_service = 'php'
```

### vala_ls
Stays in the servers table — Vala support is still in use (`after/ftplugin/vala.lua` exists). Removing `gdtoolkit` (the actual bad package name) should resolve Mason-related warnings for this server too.

---

## Files Changed

| File | Change |
|------|--------|
| `init.lua` | Remove phpactor + gdtoolkit from servers; add intelephense; add `vim.g.php_service`; add `vim.o.exrc`; add markdownlint to ensure_installed; add php_cs_fixer Docker formatter override |
| `lua/custom/plugins/nvim-neotest.lua` | Fix double-setup, route phpunit through Docker |
