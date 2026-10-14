-- theme.lua — Alabaster, light, plus softer candidates to audition.
--
-- lua/options.lua sets the built-in `default` scheme first, before lazy.nvim
-- has loaded anything. That stays: it is the floor. A fresh clone, an offline
-- compute node, or a broken plugin dir all still give readable colours, and
-- this file upgrades on top when the plugin is present.
--
-- Audition the candidates from the palette ("Try another colorscheme"):
--   everforest            warm, low-contrast green/beige (soft background)
--   gruvbox-material      warm, low-contrast cream (soft background)
--   rose-pine-dawn        muted pastels on warm off-white
--   kanagawa-lotus        ink-wash colours on parchment
--   catppuccin-latte      pastel, cooler
local candidates = {
  { 'sainnhe/everforest', init = function() vim.g.everforest_background = 'soft' end },
  { 'sainnhe/gruvbox-material', init = function() vim.g.gruvbox_material_background = 'soft' end },
  { 'rose-pine/neovim', name = 'rose-pine' },
  { 'rebelot/kanagawa.nvim' },
  { 'catppuccin/nvim', name = 'catppuccin' },
}
for _, c in ipairs(candidates) do
  c.lazy = false -- on the runtimepath so the picker lists them; nothing loads until chosen
end

return vim.list_extend({
  {
    'p00f/alabaster.nvim',
    lazy = false,
    priority = 1000, -- load before anything that reads highlight groups
    config = function()
      vim.o.background = 'light'
      vim.cmd.colorscheme 'alabaster'
    end,
  },
}, candidates)
