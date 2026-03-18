# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Linting / Formatting

This repo uses [StyLua](https://github.com/JohnnyMorganz/stylua) to format all Lua files. The CI checks formatting on every PR.

```bash
# Check formatting
stylua --check .

# Apply formatting
stylua .
```

StyLua config is in `.stylua.toml`: 2-space indentation, single quotes, 160 column width, `collapse_simple_statement = "Always"`.

## Architecture

This is a single-file Neovim configuration with optional modular extensions:

- **`init.lua`** — The entire core config in one file. Sets options, keymaps, autocommands, and configures all plugins via [lazy.nvim](https://github.com/folke/lazy.nvim). Read top-to-bottom; it's intentionally self-documenting.
- **`lua/kickstart/plugins/`** — Optional built-in plugin configs (debug, lint, autopairs, neo-tree, gitsigns, indent_line). Commented out in `init.lua` by default; uncomment to enable.
- **`lua/custom/plugins/`** — User's own plugins. All `*.lua` files here are auto-imported via `{ import = 'custom.plugins' }`. This is the intended place for personal customizations without causing merge conflicts with upstream.
- **`after/ftplugin/`** — Filetype-specific settings loaded after the main config.

### Plugin Management

lazy.nvim manages all plugins. Key commands inside Neovim:
- `:Lazy` — view plugin status, update, or install
- `:Mason` — manage LSP servers, formatters, linters
- `:checkhealth` — diagnose configuration issues

### LSP Setup

LSPs are managed via mason + mason-lspconfig. `lua_ls` and `stylua` are always installed. Add servers to the `servers` table in `init.lua`. Capabilities are extended by `blink.cmp` for autocompletion.

### Adding Plugins

Add files to `lua/custom/plugins/` returning a lazy.nvim plugin spec table. They are auto-loaded. Example existing custom plugins: `copilot.lua`, `oil.lua`, `git.lua`, `markdown.lua`, `tmux-navigator.lua`.
