return {
  {
    'stevearc/oil.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      CustomOilBar = function()
        local path = vim.fn.expand '%'
        path = path:gsub('oil://', '')

        return '  ' .. vim.fn.fnamemodify(path, ':.')
      end

      require('oil').setup {
        columns = { 'icon', 'mtime' },
        keymaps = {
          ['<C-h>'] = false,
          ['<C-l>'] = false,
          ['<C-k>'] = false,
          ['<C-j>'] = false,
          ['<M-h>'] = 'actions.select_split',
          -- Quick sort toggles (buffer-local, Oil windows only):
          --   gt  newest first (dirs still grouped before files)
          --   gn  back to natural name order
          ['gt'] = {
            callback = function()
              require('oil').set_sort { { 'type', 'asc' }, { 'mtime', 'desc' } }
            end,
            desc = 'Sort by mtime (newest first)',
          },
          ['gn'] = {
            callback = function()
              require('oil').set_sort { { 'type', 'asc' }, { 'name', 'asc' } }
            end,
            desc = 'Sort by name (natural)',
          },
        },
        win_options = {
          winbar = '%{v:lua.CustomOilBar()}',
        },
        view_options = {
          show_hidden = true,
          -- Default sort is natural name order; press gt in an Oil buffer
          -- for newest-first, gn to come back (defined in keymaps above).
          is_always_hidden = function(name, _)
            local folder_skip = { 'dev-tools.locks', 'dune.lock', '_build' }
            return vim.tbl_contains(folder_skip, name)
          end,
        },
      }

      -- Open parent directory in current window
      vim.keymap.set('n', '-', '<CMD>Oil<CR>', { desc = 'Open parent directory' })

      -- Open parent directory in floating window
      vim.keymap.set('n', '<space>-', require('oil').toggle_float)
    end,
  },
}
