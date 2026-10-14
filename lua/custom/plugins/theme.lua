-- theme.lua — rose-pine (dark) on every machine.
--
-- Override for one machine or one session with $NVIM_COLORSCHEME (a dotfiles
-- site file can export it). The candidates below stay on the runtimepath so
-- `:Telescope colorscheme` lists them for auditioning; nothing loads until
-- chosen.
--   alabaster             light, low-colour
--   everforest            warm, low-contrast green/beige (soft background)
--   gruvbox-material      warm, low-contrast cream (soft background)
--   rose-pine-dawn        muted pastels on warm off-white
--   kanagawa              ink-wash colours (wave/dragon/lotus)
--   catppuccin            pastel (latte is the light variant)
local want = vim.env.NVIM_COLORSCHEME or 'rose-pine'
local light = { alabaster = true, ['rose-pine-dawn'] = true, ['kanagawa-lotus'] = true, ['catppuccin-latte'] = true }

local candidates = {
  { 'p00f/alabaster.nvim' },
  { 'sainnhe/everforest', init = function() vim.g.everforest_background = 'soft' end },
  { 'sainnhe/gruvbox-material', init = function() vim.g.gruvbox_material_background = 'soft' end },
  { 'rebelot/kanagawa.nvim' },
  { 'catppuccin/nvim', name = 'catppuccin' },
}
for _, c in ipairs(candidates) do
  c.lazy = false
  c.priority = 999
end

return vim.list_extend({
  {
    'rose-pine/neovim',
    name = 'rose-pine',
    lazy = false,
    priority = 1000,
    ---@module 'rose-pine'
    opts = {
      variant = 'main',
      dark_variant = 'main',
      styles = { italic = false },
    },
  },
  {
    -- Not a real plugin: the lowest-priority start entry, so the colourscheme
    -- is set once every scheme above is on the runtimepath.
    dir = vim.fn.stdpath 'config' .. '/lua/custom/theme-apply',
    name = 'theme-apply',
    lazy = false,
    priority = 997,
    config = function()
      vim.o.background = light[want] and 'light' or 'dark'
      vim.cmd.colorscheme(want)
    end,
  },
}, candidates)
