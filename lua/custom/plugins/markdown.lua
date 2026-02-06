-- lua/plugins/writing.lua (or wherever you keep your plugin list)
return {
  {
    'folke/zen-mode.nvim',
    ft = 'markdown', -- Lazy loads the plugin only for .md files
    opts = {
      window = { width = 0.70 }, -- Adjust to match your screen size
      plugins = {
        options = {
          laststatus = 0, -- Hides status line
          number = false, -- Hides line numbers
          cursorline = false,
        },
      },
    },
  },
  {
    'folke/twilight.nvim', -- Optional: dims unselected paragraphs
    ft = 'markdown',
  },
}
