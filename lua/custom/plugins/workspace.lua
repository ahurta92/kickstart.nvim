-- workspace.lua -- project navigation and file marks
--
-- Two things this file sets up:
--
--   1. Harpoon  (<leader>m...)
--      Lets you "pin" up to 4 files and jump between them instantly,
--      regardless of what directory you're in.  Think of it as bookmarks
--      inside a single nvim session.
--
--   2. Project keymaps  (<leader>p...)
--      Each keymap cd's into a named project root and opens the right
--      viewer.  Code dirs use Telescope find_files; data/scratch dirs
--      that might be empty use Oil (a file manager that works on empty dirs).

return {

  -- =========================================================================
  -- Harpoon: persistent per-session file marks
  -- =========================================================================
  -- Harpoon stores a numbered list of files.  You add the current file with
  -- <leader>ma, open the menu with <leader>mm, and jump directly to slot 1-4
  -- with <leader>m1 ... <leader>m4.
  {
    'ThePrimeagen/harpoon',
    branch = 'harpoon2',
    dependencies = { 'nvim-lua/plenary.nvim' },

    -- Lazy-load: only pull the plugin into memory when one of these keys is pressed.
    keys = {
      '<leader>ma',
      '<leader>mm',
      '<leader>m1',
      '<leader>m2',
      '<leader>m3',
      '<leader>m4',
    },

    config = function()
      local harpoon = require 'harpoon'
      harpoon:setup()

      vim.keymap.set('n', '<leader>ma', function() harpoon:list():add() end, { desc = 'Harpoon: [A]dd file' })

      vim.keymap.set('n', '<leader>mm', function() harpoon.ui:toggle_quick_menu(harpoon:list()) end, { desc = 'Harpoon: [M]enu' })

      vim.keymap.set('n', '<leader>m1', function() harpoon:list():select(1) end, { desc = 'Harpoon: jump to [1]' })
      vim.keymap.set('n', '<leader>m2', function() harpoon:list():select(2) end, { desc = 'Harpoon: jump to [2]' })
      vim.keymap.set('n', '<leader>m3', function() harpoon:list():select(3) end, { desc = 'Harpoon: jump to [3]' })
      vim.keymap.set('n', '<leader>m4', function() harpoon:list():select(4) end, { desc = 'Harpoon: jump to [4]' })
    end,
  },

  -- =========================================================================
  -- Project keymaps: <leader>p...
  -- =========================================================================
  {
    dir = vim.fn.stdpath 'config',
    name = 'project-keymaps',

    config = function()
      local builtin = require 'telescope.builtin'

      -- ---------------------------------------------------------------
      -- Helper: open a directory the right way.
      --
      -- find_files fails silently on an empty directory (like a fresh
      -- scratch dir).  We solve this with a `browse` flag per project:
      --   browse = false  ->  Telescope find_files  (best for code repos)
      --   browse = true   ->  Oil file manager      (works even when empty)
      -- ---------------------------------------------------------------
      local function open_project(dir, browse)
        vim.cmd('cd ' .. vim.fn.fnameescape(dir))
        vim.notify('  ' .. dir, vim.log.levels.INFO)
        if browse then
          require('oil').open(dir)
        else
          builtin.find_files { cwd = dir }
        end
      end

      -- ---------------------------------------------------------------
      -- Project table.
      -- To add a new project just add a line here:
      --   { key = 'x', dir = '/path/to/project', desc = 'Label', browse = false }
      -- ---------------------------------------------------------------
      local projects = {
        {
          key = 'g',
          dir = '/gpfs/projects/rjh/adrian/development/gecko',
          desc = 'Gecko source',
          browse = false,
        },
        {
          key = 'm',
          dir = '/gpfs/projects/rjh/adrian/development/madness-worktrees/molresponse-feature-next',
          desc = 'MADNESS source',
          browse = false,
        },
        {
          key = '1',
          dir = '/gpfs/projects/rjh/adrian/development/madness-worktrees/mul-sparse-study/baseline',
          desc = 'mul_sparse: baseline',
          browse = false,
        },
        {
          key = '2',
          dir = '/gpfs/projects/rjh/adrian/development/madness-worktrees/mul-sparse-study/mul-sparse',
          desc = 'mul_sparse: enabled',
          browse = false,
        },
        {
          key = 'x',
          dir = '/gpfs/scratch/ahurtado/mul_sparse_study',
          desc = 'mul_sparse study data',
          browse = true,
        },
        {
          key = 'o',
          dir = '/gpfs/projects/rjh/adrian/development/madness-worktrees/molecules',
          desc = 'Molecule library',
          browse = true,
        },
        {
          key = 's',
          dir = '/gpfs/scratch/ahurtado/gecko_calcs',
          desc = 'Scratch calcs',
          browse = true,
        },
        {
          key = 'r',
          dir = '/gpfs/scratch/ahurtado/project_data/',
          desc = 'Project Data Root',
          browse = false,
        },
        {
          key = 'd',
          dir = '/gpfs/projects/rjh/adrian/development',
          desc = 'Development root',
          browse = false,
        },
        {
          key = 'z',
          dir = '/gpfs/projects/rjh/adrian/development/notes',
          desc = 'Notes',
          browse = false,
        },
      }

      -- Build one keymap per project entry.
      for _, p in ipairs(projects) do
        vim.keymap.set('n', '<leader>p' .. p.key, function() open_project(p.dir, p.browse) end, { desc = '[P]roject: ' .. p.desc })
      end

      -- ---------------------------------------------------------------
      -- Single-file shortcuts
      -- ---------------------------------------------------------------
      vim.keymap.set('n', '<leader>pb', '<cmd>edit ~/.bashrc<CR>', { desc = '[P]roject: [B]ashrc' })
      vim.keymap.set('n', '<leader>pn', '<cmd>edit ~/.config/nvim/init.lua<CR>', { desc = '[P]roject: [N]vim config' })
      vim.keymap.set('n', '<leader>pw', '<cmd>edit /gpfs/projects/rjh/adrian/development/CLAUDE.md<CR>', { desc = '[P]roject: [W]orkspace CLAUDE.md' })

      -- ---------------------------------------------------------------
      -- Claude memory: browse and search the markdown files that Claude
      -- reads at the start of every session to remember your setup.
      --
      -- <leader>pk  opens the memory dir in Oil (read/edit any file)
      -- <leader>pK  live-greps across all memory files
      -- ---------------------------------------------------------------
      local memory_dir = vim.fn.expand '~/.claude/projects/-gpfs-projects-rjh-adrian-development-madness/memory'

      vim.keymap.set('n', '<leader>pk', function() require('oil').open(memory_dir) end, { desc = '[P]roject: Claude [K]nowledge (memory)' })

      vim.keymap.set(
        'n',
        '<leader>pK',
        function() builtin.live_grep { cwd = memory_dir, prompt_title = 'Search Claude Memory' } end,
        { desc = '[P]roject: search Claude memory' }
      )

      -- ---------------------------------------------------------------
      -- Grep across a chosen project
      -- ---------------------------------------------------------------
      vim.keymap.set('n', '<leader>pG', function()
        local labels = {}
        for _, p in ipairs(projects) do
          table.insert(labels, p.key .. '  ' .. p.desc)
        end
        vim.ui.select(labels, { prompt = 'Grep in project:' }, function(choice, idx)
          if not choice then return end
          local p = projects[idx]
          vim.cmd('cd ' .. vim.fn.fnameescape(p.dir))
          builtin.live_grep { cwd = p.dir }
        end)
      end, { desc = '[P]roject: [G]rep (choose project)' })
    end,
  },

  -- Register which-key labels for the prefixes defined in this file.
  {
    'folke/which-key.nvim',
    opts = {
      spec = {
        { '<leader>p', group = '[P]rojects' },
        { '<leader>m', group = 'File [M]arks (Harpoon)' },
      },
    },
  },
}
