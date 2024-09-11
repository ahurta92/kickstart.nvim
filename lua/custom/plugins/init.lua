-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information
return {
  {
    'stevearc/oil.nvim',
    opts = {},
    -- Optional dependencies
    dependencies = { { 'echasnovski/mini.icons', opts = {} } },
    config = function()
      require('oil').setup {
        icons = require 'mini.icons',
        vim.keymap.set('n', '-', '<CMD>Oil<CR>', { desc = 'Open parent directory' }),
      }
    end,
    -- dependencies = { "nvim-tree/nvim-web-devicons" }, -- use if prefer nvim-web-devicons
  },
  {
    'github/copilot.vim',
    'fladson/vim-kitty',
    'tpope/vim-fugitive',

    enabled = true,
  },
  {
    'tpope/vim-dispatch',
    -- Create a custom BuildMadqc command
    vim.api.nvim_create_user_command('BuildMadqc', function()
      -- save all first first
      vim.cmd 'wa'
      vim.cmd '  Dispatch cmake --build build --target madqc -- -j'
    end, {}),

    vim.api.nvim_create_user_command('BuildTestManager', function()
      vim.cmd 'wa'
      vim.cmd 'Dispatch cmake --build build --target test_managers -- -j'
    end, {}),
  },
  {
    'christoomey/vim-tmux-navigator',
    cmd = {
      'TmuxNavigateLeft',
      'TmuxNavigateDown',
      'TmuxNavigateUp',
      'TmuxNavigateRight',
      'TmuxNavigatePrevious',
    },
    keys = {
      { '<c-h>', '<cmd><C-U>TmuxNavigateLeft<cr>' },
      { '<c-j>', '<cmd><C-U>TmuxNavigateDown<cr>' },
      { '<c-k>', '<cmd><C-U>TmuxNavigateUp<cr>' },
      { '<c-l>', '<cmd><C-U>TmuxNavigateRight<cr>' },
      { '<c-\\>', '<cmd><C-U>TmuxNavigatePrevious<cr>' },
    },
  },
}
