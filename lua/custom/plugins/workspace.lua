-- workspace.lua — named project locations, and file marks.
--
-- Nothing here claims a <leader> chord any more. Everything is reachable by
-- name from the command palette (Ctrl+Shift+P, or <leader>p):
--
--     "gecko"     -> Project │ Open Gecko source
--     "scratch"   -> Project │ Open Scratch root (all calc dirs)
--     "grep"      -> Project │ Search in a project...
--
-- The one exception is Harpoon's numbered slots, which are on Alt+1..4 —
-- the VSCode "switch to tab N" key. Searching for a mark by name would
-- defeat the point of a one-keystroke jump.

-- ---------------------------------------------------------------------
-- Project table.
-- To add a project, add a line here. It shows up in the palette immediately.
--
--   browse = false  ->  opens with Telescope find_files (best for code repos)
--   browse = true   ->  opens with Oil, which also works on EMPTY dirs
--                       (find_files silently shows nothing in a fresh
--                       scratch dir, which looks like a broken keybinding)
-- ---------------------------------------------------------------------
local projects = {
  { dir = '/gpfs/projects/rjh/adrian/development/gecko', desc = 'Gecko source', browse = false },
  -- NOTE: per-thread MADNESS worktrees are intentionally NOT listed here.
  -- The "Worktree" palette entries (madness-workflow.lua) derive the live
  -- thread list from `git worktree list`, so new worktrees appear on their own.
  { dir = '/gpfs/projects/rjh/adrian/repos/madness-workspace', desc = 'Madness workspace (studies/refs/es_bench)', browse = false },
  { dir = '/gpfs/projects/rjh/adrian/development/madness-worktrees/molecules', desc = 'Molecule library', browse = true },
  { dir = '/gpfs/scratch/ahurtado/gecko_calcs', desc = 'Scratch calcs (gecko)', browse = true },
  { dir = '/gpfs/scratch/ahurtado', desc = 'Scratch root (all calc dirs)', browse = true },
  { dir = '/gpfs/scratch/ahurtado/madness_es_bench', desc = 'ES bench calcs', browse = true },
  { dir = '/gpfs/projects/rjh/adrian/dalton', desc = 'DALTON source', browse = false },
  { dir = '/gpfs/scratch/ahurtado/project_data/', desc = 'Project data root', browse = false },
  { dir = '/gpfs/projects/rjh/adrian/development', desc = 'Development root', browse = false },
  { dir = '/gpfs/projects/rjh/adrian/development/notes', desc = 'Notes', browse = false },
}

-- Claude's memory dir: the markdown files it reads at the start of a session.
-- (Updated 2026-07-21: was the old -development-madness project dir.)
local memory_dir = vim.fn.expand '~/.claude/projects/-gpfs-projects-rjh-adrian-repos-madness-workspace/memory'

local function open_project(p)
  vim.cmd('cd ' .. vim.fn.fnameescape(p.dir))
  vim.notify('  ' .. p.dir, vim.log.levels.INFO)
  if p.browse then
    require('oil').open(p.dir)
  else
    require('telescope.builtin').find_files { cwd = p.dir, prompt_title = p.desc }
  end
end

-- Fuzzy-pick a project, then hand the choice to `action`.
local function pick_project(prompt, action)
  local labels = {}
  for _, p in ipairs(projects) do
    table.insert(labels, p.desc)
  end
  vim.ui.select(labels, { prompt = prompt }, function(choice, idx)
    if not choice then return end
    action(projects[idx])
  end)
end

return {

  -- =========================================================================
  -- Harpoon: numbered file marks, Alt+1..4
  -- =========================================================================
  -- Pin the files you are bouncing between, then jump to them regardless of
  -- which directory you are in. Lazy-loaded: the first require('harpoon')
  -- from a palette action or an Alt+N press pulls it in.
  {
    'ThePrimeagen/harpoon',
    branch = 'harpoon2',
    dependencies = { 'nvim-lua/plenary.nvim' },
    lazy = true,
    config = function() require('harpoon'):setup() end,
  },

  -- =========================================================================
  -- Palette entries + the Alt+N marks
  -- =========================================================================
  {
    -- Config-local pseudo-plugin; the dir must be unique across all such
    -- specs (lazy.nvim dedupes local plugins by path and would merge them).
    dir = vim.fn.stdpath 'config',
    name = 'workspace-actions',

    config = function()
      local palette = require 'custom.palette'
      local builtin = require 'telescope.builtin'

      -- --- Harpoon: one keystroke per slot -------------------------------
      for i = 1, 4 do
        vim.keymap.set('n', '<M-' .. i .. '>', function() require('harpoon'):list():select(i) end, { desc = 'Go to file mark ' .. i })
      end

      local entries = {
        { category = 'Marks', name = 'Pin this file', desc = 'harpoon add bookmark', run = function() require('harpoon'):list():add() end },
        { category = 'Marks', name = 'Show pinned files', desc = 'harpoon menu list', run = function()
          local h = require 'harpoon'
          h.ui:toggle_quick_menu(h:list())
        end },
      }
      for i = 1, 4 do
        table.insert(entries, {
          category = 'Marks',
          name = 'Go to mark ' .. i .. '  (Alt+' .. i .. ')',
          run = function() require('harpoon'):list():select(i) end,
        })
      end

      -- --- One entry per project -----------------------------------------
      for _, p in ipairs(projects) do
        table.insert(entries, {
          category = 'Project',
          name = 'Open ' .. p.desc,
          desc = p.dir,
          run = function() open_project(p) end,
        })
      end

      -- --- Cross-project pickers -----------------------------------------
      vim.list_extend(entries, {
        {
          category = 'Project',
          name = 'Open a project...',
          desc = 'choose pick switch',
          run = function() pick_project('Open project:', open_project) end,
        },
        {
          category = 'Project',
          -- Always find_files, even for the Oil-browse projects: this is the
          -- fast way to reach a calc file under scratch by typing its name.
          name = 'Find a file in a project...',
          desc = 'filename search choose',
          run = function()
            pick_project('Find files in project:', function(p)
              vim.cmd('cd ' .. vim.fn.fnameescape(p.dir))
              builtin.find_files { cwd = p.dir, prompt_title = 'Files: ' .. p.desc }
            end)
          end,
        },
        {
          category = 'Project',
          name = 'Search in a project...',
          desc = 'grep contents ripgrep choose',
          run = function()
            pick_project('Search in project:', function(p)
              vim.cmd('cd ' .. vim.fn.fnameescape(p.dir))
              builtin.live_grep { cwd = p.dir, prompt_title = 'Search: ' .. p.desc }
            end)
          end,
        },

        -- --- Single files -------------------------------------------------
        { category = 'Config', name = 'Edit init.lua', run = function() vim.cmd 'edit ~/.config/nvim/init.lua' end },
        { category = 'Config', name = 'Edit .bashrc', run = function() vim.cmd 'edit ~/.bashrc' end },
        { category = 'Config', name = 'Edit workspace CLAUDE.md', run = function()
          vim.cmd 'edit /gpfs/projects/rjh/adrian/development/CLAUDE.md'
        end },

        -- --- Claude memory -------------------------------------------------
        { category = 'Claude', name = 'Browse memory files', desc = 'knowledge notes oil', run = function() require('oil').open(memory_dir) end },
        { category = 'Claude', name = 'Search memory files', desc = 'grep knowledge', run = function()
          builtin.live_grep { cwd = memory_dir, prompt_title = 'Search Claude memory' }
        end },
      })

      palette.register(entries)
    end,
  },
}
