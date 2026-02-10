return {
  -- 1. Add vim-fugitive (not included by default in LazyVim)
  {
    'tpope/vim-fugitive',
  },

  -- 2. Customize Gitsigns (already in LazyVim, but we add TJ-style keymaps)
  {
    'lewis6991/gitsigns.nvim',
    opts = {
      on_attach = function(buffer)
        local gs = package.loaded.gitsigns

        local function map(mode, l, r, desc) vim.keymap.set(mode, l, r, { buffer = buffer, desc = desc }) end

        -- Navigation through hunks
        map('n', ']h', gs.next_hunk, 'Next Hunk')
        map('n', '[h', gs.prev_hunk, 'Prev Hunk')

        -- Git Actions
        map('n', '<leader>gs', gs.stage_hunk, 'Stage Hunk')
        map('n', '<leader>gr', gs.reset_hunk, 'Reset Hunk')
        map('n', '<leader>gp', gs.preview_hunk, 'Preview Hunk')
        map('n', '<leader>gb', function() gs.blame_line { full = true } end, 'Blame Line')
      end,
    },
  },

  -- 3. Add Telescope Git Pickers (already in LazyVim, just adding explicit keys)
  {
    'nvim-telescope/telescope.nvim',
    keys = {
      { '<leader>gc', '<cmd>Telescope git_commits<cr>', desc = 'Git Commits' },
      { '<leader>gs', '<cmd>Telescope git_status<cr>', desc = 'Git Status' },
    },
  },
}
