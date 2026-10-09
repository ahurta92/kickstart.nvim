-- workspace.lua — projects, and file marks.
--
-- No project list to maintain. A project is the git repo (or Obsidian vault)
-- around whatever file you are editing, so the same config works on every
-- machine:
--
--   * Opening a file moves this tab's cwd to that file's project root, so
--     Ctrl+P, grep, Harpoon and sessions are scoped to it no matter where
--     nvim was started. Files outside any project leave the cwd alone.
--   * <leader>sp  "Switch project": the vault, then every project you have
--     recently edited a file in (taken from :oldfiles).
--
-- Harpoon's numbered slots are on Alt+1..4. For a handful of files you
-- always want one keystroke away from ANY project, use Vim's own global
-- marks: mA tags the file, 'A jumps back (A-Z, survive restarts, :marks).

-- What makes a directory a project root.
local ROOT_MARKERS = { '.git', '.obsidian' }

local VAULT = vim.env.OBSIDIAN_VAULT or vim.fn.expand '~/vaults/research'

--- Project root of a buffer (number) or path (string), or nil.
local function project_root(src) return vim.fs.root(src, ROOT_MARKERS) end

local function set_project(dir, quiet)
  if vim.fn.getcwd() == dir then return end
  vim.cmd('tcd ' .. vim.fn.fnameescape(dir))
  if not quiet then vim.notify('  ' .. vim.fn.fnamemodify(dir, ':~'), vim.log.levels.INFO) end
end

-- Follow the file: entering a real file buffer moves the tab to its project.
vim.api.nvim_create_autocmd('BufEnter', {
  group = vim.api.nvim_create_augroup('project-root', { clear = true }),
  callback = function(ev)
    if vim.bo[ev.buf].buftype ~= '' or vim.api.nvim_buf_get_name(ev.buf) == '' then return end
    local root = project_root(ev.buf)
    if root then set_project(root, true) end
  end,
})

--- Known projects: the vault, the current one, then recently edited ones.
local function known_projects()
  local seen, list = {}, {}
  local function add(dir)
    if dir and not seen[dir] and vim.fn.isdirectory(dir) == 1 then
      seen[dir] = true
      table.insert(list, dir)
    end
  end
  add(VAULT)
  add(project_root(0))
  for _, f in ipairs(vim.v.oldfiles) do
    if not f:match '^%w+://' then add(project_root(f)) end
  end
  return list
end

local function open_project(dir)
  set_project(dir)
  require('telescope.builtin').find_files { cwd = dir, prompt_title = vim.fn.fnamemodify(dir, ':t') }
end

-- Fuzzy-pick a project, then hand the choice to `action`.
local function pick_project(prompt, action)
  local dirs = known_projects()
  local labels = vim.tbl_map(function(d) return vim.fn.fnamemodify(d, ':~') end, dirs)
  vim.ui.select(labels, { prompt = prompt }, function(_, idx)
    if idx then action(dirs[idx]) end
  end)
end

-- Claude's memory dir: the markdown files it reads at the start of a session.
-- (Updated 2026-07-21: was the old -development-madness project dir.)
local memory_dir = vim.fn.expand '~/.claude/projects/-gpfs-projects-rjh-adrian-repos-madness-workspace/memory'
local workspace_claude_md = '/gpfs/projects/rjh/adrian/development/CLAUDE.md'

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
        { category = 'Marks', name = 'Show global marks', desc = "mA 'A tags", run = function() builtin.marks { mark_type = 'global' } end },
      }
      for i = 1, 4 do
        table.insert(entries, {
          category = 'Marks',
          name = 'Go to mark ' .. i .. '  (Alt+' .. i .. ')',
          run = function() require('harpoon'):list():select(i) end,
        })
      end

      -- --- Projects ----------------------------------------------------
      local switch = function() pick_project('Switch project:', open_project) end
      vim.keymap.set('n', '<leader>sp', switch, { desc = '[S]witch [P]roject' })

      vim.list_extend(entries, {
        { category = 'Project', name = 'Switch project...  (<leader>sp)', desc = 'open choose recent', run = switch },
        {
          category = 'Project',
          name = 'Set project to this file',
          desc = 'cd root here',
          run = function() set_project(project_root(0) or vim.fn.expand '%:p:h') end,
        },
        {
          category = 'Project',
          name = 'Search in a project...',
          desc = 'grep contents ripgrep choose',
          run = function()
            pick_project('Search in project:', function(dir)
              set_project(dir)
              builtin.live_grep { cwd = dir, prompt_title = 'Search: ' .. vim.fn.fnamemodify(dir, ':t') }
            end)
          end,
        },
      })

      -- --- Single files -------------------------------------------------
      vim.list_extend(entries, {
        { category = 'Config', name = 'Edit init.lua', run = function() vim.cmd 'edit ~/.config/nvim/init.lua' end },
        { category = 'Config', name = 'Edit .bashrc', run = function() vim.cmd 'edit ~/.bashrc' end },
      })
      if vim.fn.filereadable(workspace_claude_md) == 1 then
        table.insert(entries, { category = 'Config', name = 'Edit workspace CLAUDE.md', run = function()
          vim.cmd('edit ' .. vim.fn.fnameescape(workspace_claude_md))
        end })
      end

      -- --- Claude memory -------------------------------------------------
      if vim.fn.isdirectory(memory_dir) == 1 then vim.list_extend(entries, {
        { category = 'Claude', name = 'Browse memory files', desc = 'knowledge notes oil', run = function() require('oil').open(memory_dir) end },
        { category = 'Claude', name = 'Search memory files', desc = 'grep knowledge', run = function()
          builtin.live_grep { cwd = memory_dir, prompt_title = 'Search Claude memory' }
        end },
      }) end

      palette.register(entries)
    end,
  },
}
