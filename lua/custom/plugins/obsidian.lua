-- obsidian.lua — make the vault's [[links]] navigable from Neovim.
--
-- Syncing is NOT this plugin's job -- that is the headless client
-- (`ob sync --continuous`, run by the obsidian-sync systemd user service).
-- This only edits files on disk; the sync daemon notices and uploads.
--
-- The vault path comes from $OBSIDIAN_VAULT so one file works on every
-- machine (a site file can export the cluster's /gpfs path); otherwise it
-- defaults to ~/vaults/research. If the directory does not exist the plugin
-- is skipped entirely instead of erroring on every startup.
--
--   gf                     follow the link under the cursor
--   <leader>o...           Obsidian commands (see which-key)
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

    -- `ft` alone is not enough: :Obsidian would not exist until a markdown
    -- buffer had been opened. `cmd` and `keys` register stubs that load the
    -- plugin on first use, from any buffer.
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

      -- Left off to match the cluster config, where render-markdown.nvim owns
      -- rendering. Also avoids obsidian.nvim's conceallevel warning.
      ui = { enable = false },

      -- OFF deliberately: enabled, this writes id/aliases/tags blocks into
      -- every note you save, and each of those writes syncs to every device.
      frontmatter = { enabled = false },

      -- NOTE: these are Moment.js tokens, not strftime. `%Y-%m-%d` silently
      -- produces a file literally named "%Y-%m-%d.md".
      daily_notes = {
        folder = 'Periodic/Daily',
        date_format = 'YYYY-MM-DD',
        default_tags = {},
        workdays_only = false,
      },

      templates = {
        folder = 'Templates',
        date_format = 'YYYY-MM-DD',
        time_format = 'HH:mm',
      },

      completion = {
        min_chars = 2, -- `[[` + 2 chars starts completing note titles
      },
    },
  },
}
