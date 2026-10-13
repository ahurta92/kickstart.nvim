-- render-markdown.lua — in-buffer markdown rendering.
--
-- headlines.nvim used to be configured here too, and BOTH were loading. They
-- each draw a background behind headings and fenced code, so every heading got
-- two stacked backgrounds and every code block a doubled border. That is what
-- made this look bad; headlines.nvim is gone and render-markdown is now the
-- only renderer.
--
-- Colours come from the colorscheme, not from here: tokyonight defines
-- @markup.heading.1..6 distinctly, so the six levels differ by hue rather than
-- by a coloured bar.
return {
  {
    'MeanderingProgrammer/render-markdown.nvim',
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    ft = { 'markdown' },
    ---@module 'render-markdown'
    opts = {
      -- Reveal the raw markdown on whichever line the cursor is on, so editing
      -- a link or a table never fights the rendering.
      anti_conceal = { enabled = true },

      heading = {
        sign = false, -- no gutter clutter; the icon carries the level
        position = 'inline', -- icon sits with the text, not in the margin
        icons = { '󰲡 ', '󰲣 ', '󰲥 ', '󰲧 ', '󰲩 ', '󰲫 ' },
        width = 'block', -- background hugs the text instead of the whole line
        left_pad = 0,
        right_pad = 2,
        min_width = 0,
        border = false,
      },

      code = {
        sign = false,
        style = 'full', -- language label + background
        position = 'right', -- language name right-aligned, out of the way
        width = 'block',
        border = 'thin',
        left_pad = 2,
        right_pad = 2,
        language_pad = 2,
        min_width = 45, -- stops short snippets rendering as ragged stubs
      },

      bullet = { icons = { '●', '○', '◆', '◇' } },

      checkbox = {
        unchecked = { icon = '󰄱 ' },
        checked = { icon = '󰱒 ' },
      },

      quote = { icon = '▍' },
      dash = { icon = '─' },

      link = {
        hyperlink = '󰌷 ',
        image = '󰥶 ',
        email = '󰇰 ',
        footnote = { superscript = true },
        wiki = { icon = '󱗖 ' }, -- [[wiki links]] -- obsidian.lua follows these
      },

      pipe_table = {
        preset = 'round',
        style = 'full',
        cell = 'trimmed',
        alignment_indicator = '━',
        min_width = 0,
      },
    },
  },

  {
    'dhruvasagar/vim-table-mode',
    ft = 'markdown',
    config = function()
      vim.g.table_mode_corner = '|' -- standard markdown style
    end,
  },
}
