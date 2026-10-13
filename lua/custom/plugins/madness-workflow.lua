-- madness-workflow.lua — thread-aware MADNESS dev helpers, reachable by name.
--
-- Mirrors the shell entrypoints (~/.madness_workflow.sh). The set of threads is
-- derived LIVE from `git worktree list` (never hardcoded), so new worktrees show
-- up automatically and retired ones disappear.
--
-- All of it lives in the command palette (Ctrl+Shift+P, or <leader>p):
--
--     "worktree"  -> pick a thread, then find / search / browse it
--     "build"     -> MADNESS │ Build (cm_env && cm_build)
--     "board"     -> MADNESS │ Open release board

-- (Updated 2026-07-21: repos moved under /gpfs/projects/rjh/adrian/repos/;
-- the old /gpfs/projects/rjh/adrian/madness{,_studies} paths are now symlinks.)
local MAD_REPO = '/gpfs/projects/rjh/adrian/repos/madness'
local STUDIES = '/gpfs/projects/rjh/adrian/repos/madness-workspace'

-- Parse `git worktree list --porcelain` -> { {branch=, path=}, ... }.
-- Detached worktrees are included with branch = '(detached)'.
local function worktrees()
  local out = vim.fn.systemlist { 'git', '-C', MAD_REPO, 'worktree', 'list', '--porcelain' }
  local res, cur = {}, {}
  for _, line in ipairs(out) do
    if line:match '^worktree ' then
      cur = { path = line:sub(10) }
    elseif line:match '^branch ' then
      cur.branch = (line:gsub('^branch refs/heads/', ''))
      table.insert(res, cur)
    elseif line == 'detached' then
      cur.branch = '(detached)'
      table.insert(res, cur)
    end
  end
  return res
end

-- git toplevel of the current cwd (fallback: cwd).
local function git_root()
  local out = vim.fn.systemlist { 'git', 'rev-parse', '--show-toplevel' }
  local r = out[1]
  if r and r ~= '' and not r:match 'fatal' then return r end
  return vim.fn.getcwd()
end

-- Open a terminal split, source cm.sh, cm_use the current worktree's branch, run cmd.
local function cm_term(cmd)
  local pre = 'source ' .. STUDIES .. '/es_bench/cm.sh; ' .. 'cm_use "$(git rev-parse --abbrev-ref HEAD 2>/dev/null)" >/dev/null 2>&1; '
  vim.cmd('botright 18split | terminal bash -ic ' .. vim.fn.shellescape(pre .. cmd))
  vim.cmd 'startinsert'
end

-- Fuzzy-pick a worktree, :tcd into it, then run `action(w)` on the choice.
local function pick_worktree(prompt, action)
  local wts = worktrees()
  if #wts == 0 then
    vim.notify('no worktrees found under ' .. MAD_REPO, vim.log.levels.WARN)
    return
  end
  local labels = {}
  for _, w in ipairs(wts) do
    table.insert(labels, string.format('%-22s  %s', w.branch or '(detached)', w.path))
  end
  vim.ui.select(labels, { prompt = prompt }, function(_, idx)
    if not idx then return end
    local w = wts[idx]
    vim.cmd('tcd ' .. vim.fn.fnameescape(w.path))
    vim.notify('worktree → ' .. (w.branch or w.path), vim.log.levels.INFO)
    action(w)
  end)
end

return {
  {
    -- Config-local pseudo-plugin. NOTE: the dir must differ from every other
    -- such spec — lazy.nvim dedupes local plugins by path, and two specs
    -- sharing a dir get merged into one, silently dropping this config.
    dir = vim.fn.stdpath 'config' .. '/lua/custom',
    name = 'madness-workflow',
    -- Everything below drives the cluster's MADNESS checkout. One config runs
    -- on every machine, so skip it where that checkout does not exist rather
    -- than registering palette entries that fail when run.
    cond = vim.fn.isdirectory(MAD_REPO) == 1,

    config = function()
      require('custom.palette').register {
        {
          category = 'Worktree',
          name = 'Find a file in a thread...',
          desc = 'madness pick switch branch',
          run = function()
            pick_worktree('Worktree: find files', function(w)
              require('telescope.builtin').find_files { cwd = w.path, prompt_title = 'Files: ' .. (w.branch or w.path) }
            end)
          end,
        },
        {
          category = 'Worktree',
          name = 'Search in a thread...',
          desc = 'madness grep contents branch',
          run = function()
            pick_worktree('Worktree: search', function(w)
              require('telescope.builtin').live_grep { cwd = w.path, prompt_title = 'Search: ' .. (w.branch or w.path) }
            end)
          end,
        },
        {
          category = 'Worktree',
          name = 'Browse a thread...',
          desc = 'madness oil files branch',
          run = function() pick_worktree('Worktree: browse', function(w) require('oil').open(w.path) end) end,
        },

        {
          category = 'MADNESS',
          name = 'Open cm shell here',
          desc = 'terminal cm_arch',
          run = function() cm_term 'echo "cm ready ($STUDY @ $CM_ARCH)"; cm_arch' end,
        },
        { category = 'MADNESS', name = 'Build', desc = 'cm_env cm_build compile', run = function() cm_term 'cm_env && cm_build' end },
        { category = 'MADNESS', name = 'Run h2o', desc = 'cm_run test calc', run = function() cm_term 'cm_run h2o' end },
        { category = 'MADNESS', name = 'Unit tests', desc = 'cm_unit', run = function() cm_term 'cm_unit' end },
        {
          category = 'MADNESS',
          name = 'Run a cm_* command...',
          desc = 'custom terminal arbitrary',
          run = function()
            vim.ui.input({ prompt = 'cm command: ' }, function(input)
              if input and input ~= '' then cm_term(input) end
            end)
          end,
        },
        {
          category = 'MADNESS',
          name = 'Open release board',
          desc = 'RELEASE_STATUS cross-thread',
          run = function() vim.cmd('edit ' .. vim.fn.fnameescape(STUDIES .. '/RELEASE_STATUS.md')) end,
        },
        {
          -- (docs/00_status.md was dropped 2026-07-21; search this thread's
          -- markdown instead of opening a fixed file.)
          category = 'MADNESS',
          name = 'Find a doc in this thread',
          desc = 'markdown notes status',
          run = function()
            require('telescope.builtin').find_files {
              cwd = git_root(),
              prompt_title = 'Docs in this thread',
              -- --no-ignore-vcs/--hidden so gitignored docs/ and .claude/
              -- plans show up here too, matching Ctrl+P (see init.lua).
              find_command = { 'rg', '--files', '--no-ignore-vcs', '--hidden', '--glob', '*.md', '--glob', '!.git/' },
            }
          end,
        },
      }
    end,
  },
}
