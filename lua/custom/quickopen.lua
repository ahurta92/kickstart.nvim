-- quickopen.lua — VSCode's Quick Open, on Ctrl+P.
--
-- In VSCode, Ctrl+Shift+P is nothing more than a shortcut for "press Ctrl+P
-- and type >".  Windows Terminal swallows every Ctrl+Shift combination for
-- its own menus, and even unbound they would arrive over SSH as the same
-- bytes as plain Ctrl+P — so the prefixes are the way in here, not a
-- workaround for one.
--
--   Ctrl+P          files in this project
--   Ctrl+P then >   command palette
--   Ctrl+P then @   symbol in this file
--   Ctrl+P then #   symbol anywhere in the workspace
--   Ctrl+P then :   go to line
--   Ctrl+P then ?   remind me what the prefixes are
--
-- Typing a prefix as the first character swaps you into that picker. It has
-- to be the first character, which is exactly why VSCode picked > @ # : —
-- no filename begins with them.

local M = {}

--- The project: the enclosing git repo when there is one, else the cwd.
--- Same scoping VSCode gives a workspace folder.
function M.root()
  local out = vim.fn.systemlist { 'git', 'rev-parse', '--show-toplevel' }
  if vim.v.shell_error == 0 and out[1] and out[1] ~= '' then return out[1] end
  return vim.fn.getcwd()
end

local function title(root) return vim.fn.fnamemodify(root, ':t') end

function M.files()
  local root = M.root()
  require('telescope.builtin').find_files { cwd = root, prompt_title = 'Files: ' .. title(root) }
end

function M.grep()
  local root = M.root()
  require('telescope.builtin').live_grep { cwd = root, prompt_title = 'Search: ' .. title(root) }
end

-- prefix -> what it switches to
local modes = {
  ['>'] = { label = 'run a command', run = function() require('custom.palette').open() end },
  ['@'] = { label = 'symbol in this file', run = function() require('telescope.builtin').lsp_document_symbols() end },
  ['#'] = { label = 'symbol in the workspace', run = function() require('telescope.builtin').lsp_dynamic_workspace_symbols() end },
  -- Nothing to build: Neovim's own command line already turns :42<CR> into
  -- "go to line 42", which is the same keystrokes VSCode wants.
  [':'] = { label = 'go to line', run = function() vim.api.nvim_feedkeys(':', 'n', false) end },
  ['?'] = { label = 'list these prefixes', run = function() M.help() end },
}

local order = { '>', '@', '#', ':' }

--- The `?` prefix: show the others, and jump straight into the one picked.
function M.help()
  local labels, runs = { 'nothing   find a file in this project' }, { M.files }
  for _, p in ipairs(order) do
    table.insert(labels, p .. '         ' .. modes[p].label)
    table.insert(runs, modes[p].run)
  end
  vim.ui.select(labels, { prompt = 'Ctrl+P, then:' }, function(choice, idx)
    if choice then runs[idx]() end
  end)
end

--- Open Quick Open in file mode.
function M.open()
  local root = M.root()
  local switched = false
  local prompt_bufnr

  require('telescope.builtin').find_files {
    cwd = root,
    prompt_title = 'Go to File in ' .. title(root) .. '    > command   @ symbol   # workspace   : line   ? help',

    -- Only here to capture the prompt buffer so the filter callback below can
    -- close it. `true` keeps Telescope's default mappings.
    attach_mappings = function(bufnr)
      prompt_bufnr = bufnr
      return true
    end,

    -- Runs on every keystroke with the current prompt. A prefix in the first
    -- column hands off to that mode's own picker, which keeps every one of
    -- them a real, fully featured Telescope picker rather than a
    -- reimplementation. Backspacing does not come back: press Esc, Ctrl+P.
    on_input_filter_cb = function(prompt)
      if switched then return { prompt = '' } end
      local mode = modes[prompt:sub(1, 1)]
      if not mode then return { prompt = prompt } end
      switched = true
      vim.schedule(function()
        if prompt_bufnr then require('telescope.actions').close(prompt_bufnr) end
        -- Deferred again: the next picker cannot start while this one is
        -- still tearing down.
        vim.schedule(mode.run)
      end)
      return { prompt = '' }
    end,
  }
end

return M
