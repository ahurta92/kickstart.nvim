-- obsidian.lua — make the vault's [[links]] navigable from Neovim.
--
-- The vault has folder notes (MADNESS/MADNESS.md, AMS 561/AMS 561.md) acting
-- as hubs for its wiki links. Without this those links are inert text and the
-- hub structure is invisible outside the Obsidian app. That is what this is
-- for; the rest is a bonus.
--
-- Syncing is NOT this plugin's job -- that is the headless client
-- (`ob sync --continuous`, run by the obsidian-sync systemd user service).
-- This only edits files on disk; the sync daemon notices and uploads.
--
-- The vault path comes from $OBSIDIAN_VAULT so one file works on every
-- machine (sites/seawulf.sh exports the cluster's /gpfs path); otherwise it
-- defaults to ~/vaults/research. If the directory does not exist the plugin
-- is skipped entirely -- keys, palette entries and all.
--
--   gf                     follow the link under the cursor
--   <leader>o...           fast path (see which-key)
--   F1 -> Obsidian | ...   the same actions, findable by name
--   :Obsidian <Tab>        everything else
local VAULT = vim.env.OBSIDIAN_VAULT or vim.fn.expand '~/vaults/research'

local function cmd(sub)
  return function() vim.cmd('Obsidian ' .. sub) end
end

return {
  {
    'obsidian-nvim/obsidian.nvim',
    version = '*',
    dependencies = { 'nvim-lua/plenary.nvim' },
    cond = vim.fn.isdirectory(VAULT) == 1,

    -- `ft` alone is not enough. With only ft = 'markdown', :Obsidian does not
    -- exist until a markdown buffer has been opened, so reaching the vault
    -- from the palette while editing C++ in a worktree failed with
    -- "E492: Not an editor command". `cmd` and `keys` make lazy.nvim register
    -- stubs that load the plugin on first use, from any buffer.
    ft = 'markdown',
    cmd = 'Obsidian',
    keys = {
      { '<leader>of', cmd 'quick_switch', desc = '[O]bsidian [F]ind note' },
      { '<leader>os', cmd 'search', desc = '[O]bsidian [S]earch text' },
      { '<leader>on', cmd 'new', desc = '[O]bsidian [N]ew note' },
      { '<leader>ot', cmd 'today', desc = '[O]bsidian [T]oday' },
      { '<leader>oy', cmd 'yesterday', desc = '[O]bsidian [Y]esterday' },
      { '<leader>ob', cmd 'backlinks', desc = '[O]bsidian [B]acklinks' },
      { '<leader>ol', cmd 'links', desc = '[O]bsidian [L]inks in note' },
      { '<leader>oT', cmd 'template', desc = '[O]bsidian insert [T]emplate' },
      { '<leader>or', cmd 'rename', desc = '[O]bsidian [R]ename (updates backlinks)' },
      { '<leader>oc', cmd 'toc', desc = '[O]bsidian table of [C]ontents' },
    },

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

      -- OFF deliberately. Most notes have no frontmatter; left enabled this
      -- writes id/aliases/tags blocks into them as you save, and every one of
      -- those writes syncs straight to your other devices. Turn it on when
      -- you actually want that, not by accident.
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
    -- the first markdown buffer. (Skipped along with the plugin when `cond`
    -- is false, so a machine without the vault gets no dead entries.)
    init = function()
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
        { category = 'Obsidian', name = 'Search note text', desc = 'grep find', run = cmd 'search' },
        { category = 'Obsidian', name = 'Links in this note', run = cmd 'links' },
        { category = 'Obsidian', name = 'Table of contents', run = cmd 'toc' },
      }
    end,
  },
}
