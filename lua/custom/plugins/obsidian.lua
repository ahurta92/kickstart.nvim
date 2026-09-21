-- obsidian.lua — make the vault's [[links]] navigable from Neovim.
--
-- The vault is 30 notes carrying 95 wiki links across 21 of them, with folder
-- notes (MADNESS/MADNESS.md, AMS 561/AMS 561.md) acting as hubs. Without this
-- those links are inert text and the hub structure is invisible outside the
-- Obsidian app. That is what this is for; the rest is a bonus.
--
-- Syncing is NOT this plugin's job -- that is the headless client in
-- scripts/obsidian-sync.sh. This only edits files on disk; the sync daemon
-- notices and uploads within a few seconds.
--
--   gf                     follow the link under the cursor
--   F1 -> Obsidian | ...   backlinks, today's note, templates, rename
--   :Obsidian <Tab>        everything else
local VAULT = '/gpfs/projects/rjh/adrian/repos/vaults/research'

return {
  {
    'obsidian-nvim/obsidian.nvim',
    version = '*',
    ft = 'markdown',
    dependencies = { 'nvim-lua/plenary.nvim' },

    ---@module 'obsidian'
    opts = {
      legacy_commands = false, -- `:Obsidian <sub>`, not the old `:ObsidianSub`
      workspaces = {
        { name = 'research', path = VAULT },
      },

      -- Rendering belongs to render-markdown.nvim. obsidian.nvim ships its own
      -- conceal/highlight layer that is ON by default, and running both stacks
      -- two sets of decorations on the same headings and checkboxes -- exactly
      -- the headlines.nvim problem this config just removed.
      ui = { enable = false },

      -- OFF deliberately. Only 2 of the 30 notes have frontmatter; left
      -- enabled this writes id/aliases/tags blocks into the other 28 as you
      -- save them, and every one of those writes syncs straight to your other
      -- devices. Turn it on when you actually want that, not by accident.
      frontmatter = { enabled = false },

      -- NOTE: these are Moment.js tokens, not strftime. `%Y-%m-%d` silently
      -- produces a file literally named "%Y-%m-%d.md".
      daily_notes = {
        folder = 'Periodic/Daily',
        date_format = 'YYYY-MM-DD', -- matches the existing 2026-09-21.md
        default_tags = {}, -- the vault does not use a daily-notes tag
        workdays_only = false,
      },

      templates = {
        folder = 'Templates', -- Experiment, Faculty Meeting, Literature Note, ...
        date_format = 'YYYY-MM-DD',
        time_format = 'HH:mm',
      },

      completion = {
        min_chars = 2, -- `[[` + 2 chars starts completing note titles
      },

      -- picker.name is left unset: it auto-detects, and telescope is installed.
      --
      -- follow_url_func is NOT set: it is deprecated in favour of vim.ui.open,
      -- and setting it prints a deprecation warning on every load.
    },

    -- Registered before load so the entries exist from startup, not only after
    -- the first markdown buffer.
    init = function()
      local function cmd(sub)
        return function() vim.cmd('Obsidian ' .. sub) end
      end
      require('custom.palette').register {
        -- `gf` already follows a link natively (the plugin sets includeexpr);
        -- this is here for discoverability, not because gf needs help.
        { category = 'Obsidian', name = 'Follow link under cursor (or gf)', desc = 'jump wiki', run = cmd 'follow_link' },
        { category = 'Obsidian', name = 'Backlinks to this note', desc = 'what links here references', run = cmd 'backlinks' },
        { category = 'Obsidian', name = "Today's daily note", desc = 'journal periodic', run = cmd 'today' },
        { category = 'Obsidian', name = "Yesterday's daily note", run = cmd 'yesterday' },
        { category = 'Obsidian', name = 'Insert template', desc = 'experiment literature meeting benchmark', run = cmd 'template' },
        { category = 'Obsidian', name = 'New note', run = cmd 'new' },
        { category = 'Obsidian', name = 'Rename note (updates backlinks)', desc = 'refactor move', run = cmd 'rename' },
        { category = 'Obsidian', name = 'Switch note by title', desc = 'quick switch alias', run = cmd 'quick_switch' },
        { category = 'Obsidian', name = 'Links in this note', run = cmd 'links' },
        { category = 'Obsidian', name = 'Table of contents', run = cmd 'toc' },
      }
    end,
  },
}
