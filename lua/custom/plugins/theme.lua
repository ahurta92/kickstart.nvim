-- theme.lua — one colourscheme module for every machine.
--
-- Which scheme loads, in order of precedence:
--   $NVIM_COLORSCHEME (set per machine in dotfiles sites/<machine>.sh)
--       e.g. dd exports NVIM_COLORSCHEME=alabaster -> Alabaster, light background
--   a GNOME session (laptop)
--       auto-gnome-theme follows the system light/dark setting:
--       adwaita (light) / rose-pine (dark)
--   anything else (clusters, plain ssh logins)
--       rose-pine
--
-- The candidates below are on the runtimepath so `:Telescope colorscheme`
-- lists them for auditioning; nothing loads until chosen.
--   everforest            warm, low-contrast green/beige (soft background)
--   gruvbox-material      warm, low-contrast cream (soft background)
--   rose-pine-dawn        muted pastels on warm off-white
--   kanagawa-lotus        ink-wash colours on parchment
--   catppuccin-latte      pastel, cooler
local want = vim.env.NVIM_COLORSCHEME
local has_gnome = (vim.env.XDG_CURRENT_DESKTOP or ''):match('GNOME') ~= nil
  and vim.env.DBUS_SESSION_BUS_ADDRESS ~= nil

local light = { alabaster = true, ['rose-pine-dawn'] = true, ['kanagawa-lotus'] = true, ['catppuccin-latte'] = true }

-- Called once every colourscheme plugin is on the runtimepath (lowest priority below).
local function apply()
  if want then
    vim.o.background = light[want] and 'light' or 'dark'
    vim.cmd.colorscheme(want)
  elseif not has_gnome then
    vim.cmd.colorscheme 'rose-pine'
  end
  -- with GNOME and no explicit choice, auto-gnome-theme sets the scheme
end

local candidates = {
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
    'Mofiqul/adwaita.nvim',
    lazy = false,
    priority = 1000,
    init = function()
      vim.g.adwaita_darker = true
      vim.g.adwaita_disable_cursorline = true
      vim.g.adwaita_transparent = true
    end,
  },
  {
    'rose-pine/neovim',
    name = 'rose-pine',
    lazy = false,
    priority = 1000,
    ---@module 'rose-pine'
    opts = {
      variant = 'auto',
      dark_variant = 'main',
      styles = { italic = false },
    },
  },
  {
    'p00f/alabaster.nvim',
    lazy = false,
    priority = 1000,
  },
  {
    'itsfernn/auto-gnome-theme.nvim',
    lazy = false,
    priority = 998,
    cond = has_gnome and not want,
    dependencies = { 'rose-pine', 'Mofiqul/adwaita.nvim' },
    opts = {
      light_theme = 'adwaita',
      dark_theme = 'rose-pine',
    },
  },
  {
    -- Not a real plugin: the lowest-priority start entry, so apply() runs after
    -- every colourscheme above is available.
    dir = vim.fn.stdpath 'config' .. '/lua/custom/theme-apply',
    name = 'theme-apply',
    lazy = false,
    priority = 997,
    config = apply,
  },
}, candidates)
