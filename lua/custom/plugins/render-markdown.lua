return {
  'MeanderingProgrammer/render-markdown.nvim',
  dependencies = { 'nvim-treesitter/nvim-treesitter' },
  ft = { 'markdown' },
  opts = {
    heading = {
      signs = false, -- cleaner without gutter signs
      width = 'block', -- highlight only the heading text, not full line
    },
    code = {
      width = 'block',
      left_pad = 2,
    },
    pipe_table = {
      preset = 'round', -- try "round" or "heavy" too
      cell = 'trimmed',
      min_width = 0,
      alignment_indicator = '━',
      style = 'full',
    },
  },
  {

    'lukas-reineke/headlines.nvim',
    dependencies = 'nvim-treesitter/nvim-treesitter',
    ft = 'markdown',
    opts = {},
  },
  {
    'dhruvasagar/vim-table-mode',
    ft = 'markdown',
    config = function()
      vim.g.table_mode_corner = '|' -- standard markdown style
    end,
  },
}
