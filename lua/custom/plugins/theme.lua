-- theme.lua — tokyonight.
--
-- lua/options.lua sets the built-in `default` scheme first, before lazy.nvim
-- has loaded anything. That stays: it is the floor. A fresh clone, an offline
-- compute node, or a broken plugin dir all still give readable colours, and
-- this file upgrades on top when the plugin is present. Nothing to fall back
-- to manually.
--
-- tokyonight over the alternatives because it compiles its highlight groups
-- to a cache on disk (`cache = true`) and reloads them without re-evaluating
-- the palette, so it costs near nothing at startup, and because it ships real
-- integrations for what this config actually uses: telescope, blink.cmp,
-- gitsigns, which-key, render-markdown, mini.statusline.
return {
  {
    'folke/tokyonight.nvim',
    lazy = false,
    priority = 1000, -- load before anything that reads highlight groups
    opts = {
      style = 'night', -- darkest of the dark variants
      light_style = 'day', -- used automatically when background=light
      transparent = false,
      terminal_colors = true,

      styles = {
        -- Italics travel badly over SSH + tmux + Windows Terminal: some fonts
        -- substitute a slanted fallback that renders at a different width and
        -- makes comments jitter. Off deliberately.
        comments = { italic = false },
        keywords = { italic = false },
        functions = {},
        variables = {},
      },

      -- Auto-enables integrations for plugins it detects.
      plugins = { auto = true },
    },
    config = function(_, opts)
      require('tokyonight').setup(opts)
      vim.cmd.colorscheme 'tokyonight'
    end,
  },
}
