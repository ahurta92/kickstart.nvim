-- Colourscheme: adwaita (light) / rose-pine (dark), following the GNOME
-- light-dark setting on the laptop. On machines without a GNOME session
-- (clusters, ssh logins) the GNOME plugin is skipped and rose-pine is set
-- directly, so the same config works everywhere.
local has_gnome = (vim.env.XDG_CURRENT_DESKTOP or ''):match('GNOME') ~= nil
  and vim.env.DBUS_SESSION_BUS_ADDRESS ~= nil

return {
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
    config = function(_, opts)
      require('rose-pine').setup(opts)
      if not has_gnome then
        vim.cmd.colorscheme 'rose-pine'
      end
    end,
  },

  {
    'itsfernn/auto-gnome-theme.nvim',
    lazy = false,
    priority = 999,
    cond = has_gnome,
    dependencies = { 'rose-pine', 'Mofiqul/adwaita.nvim' },
    opts = {
      light_theme = 'adwaita',
      dark_theme = 'rose-pine',
    },
  },
}
