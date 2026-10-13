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
  },

  {
    'itsfernn/auto-gnome-theme.nvim',
    lazy = false,
    priority = 999,
    dependencies = { 'rose-pine', 'Mofiqul/adwaita.nvim' },
    opts = {
      light_theme = 'adwaita',
      dark_theme = 'rose-pine',
    },
  },
}
