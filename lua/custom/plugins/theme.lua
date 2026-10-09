-- theme.lua — Alabaster, light.
--
-- lua/options.lua sets the built-in `default` scheme first, before lazy.nvim
-- has loaded anything. That stays: it is the floor. A fresh clone, an offline
-- compute node, or a broken plugin dir all still give readable colours, and
-- this file upgrades on top when the plugin is present.
--
-- Alabaster colours only what you look things up by: strings, constants,
-- comments and definitions. Keywords and ordinary code stay plain text.
return {
  {
    'p00f/alabaster.nvim',
    lazy = false,
    priority = 1000, -- load before anything that reads highlight groups
    config = function()
      vim.o.background = 'light'
      vim.cmd.colorscheme 'alabaster'
    end,
  },
}
