-- vscode-keys.lua — the small set of keys this config is actually built around.
--
--   Ctrl+P     Quick Open — files, and every other picker behind a prefix:
--                  >  run a command (the palette)
--                  @  symbol in this file
--                  #  symbol in the workspace
--                  :  go to line
--                  ?  remind me what these are
--   F1         command palette directly (VSCode's other binding for it)
--   Alt+F      search file contents across the project
--   Ctrl+T     symbol in the workspace
--
-- No Ctrl+Shift here. Windows Terminal claims every Ctrl+Shift combination
-- for its own menus (Ctrl+Shift+P is *its* command palette), and unbinding
-- them there does not help: over SSH the terminal would still send the same
-- bytes as plain Ctrl+P, so Neovim could not tell the two apart. F1, Alt+F
-- and the Ctrl+P prefixes all survive Windows Terminal, tmux and SSH intact.
--
-- Run :KeyCheck to confirm what your terminal actually delivers.
-- Fallbacks that work no matter what: <leader>p palette, <leader>sg search,
-- gO symbol in file.

local quickopen = require 'custom.quickopen'

return {
  {
    -- Config-local pseudo-plugin. The dir must be unique across every such
    -- spec in this config — lazy.nvim dedupes local plugins by path, and two
    -- specs sharing a dir silently merge into one.
    dir = vim.fn.stdpath 'config' .. '/lua/custom/plugins',
    name = 'vscode-keys',

    config = function()
      local palette = require 'custom.palette'
      local builtin = require 'telescope.builtin'
      local map = vim.keymap.set

      -- ===================================================================
      -- The keys
      -- ===================================================================
      map({ 'n', 'v' }, '<C-p>', quickopen.open, { desc = 'Quick Open: files (> command, @ symbol, # workspace, : line)' })
      map({ 'n', 'v' }, '<F1>', palette.open, { desc = 'Command palette' })
      map('n', '<leader>p', palette.open, { desc = 'Command [P]alette' })
      map({ 'n', 'v' }, '<M-f>', quickopen.grep, { desc = 'Search across project' })
      -- Overrides the tag-stack pop. Use <C-o> (jumplist) to go back instead;
      -- it covers LSP jumps too.
      map('n', '<C-t>', builtin.lsp_dynamic_workspace_symbols, { desc = 'Go to symbol in workspace' })

      vim.api.nvim_create_user_command('Palette', palette.open, { desc = 'Open the command palette' })

      -- Windows Terminal, tmux and SSH each get a chance to swallow a key
      -- before Neovim sees it, and a swallowed key looks identical to a
      -- broken config. This makes the difference visible.
      vim.api.nvim_create_user_command('KeyCheck', function()
        local probes = {
          { '<C-p>', 'Ctrl+P', 'Quick Open' },
          { '<F1>', 'F1', 'command palette' },
          { '<M-f>', 'Alt+F', 'search across project' },
          { '<C-t>', 'Ctrl+T', 'symbol in workspace' },
          { '<M-1>', 'Alt+1', 'jump to file mark 1' },
        }
        local head = {
          'Press each key below. A ✓ appears for every one that reaches',
          'Neovim. Press q to close.',
          '',
        }
        for _, pr in ipairs(probes) do
          table.insert(head, string.format('   %-8s %s', pr[2], pr[3]))
        end
        vim.list_extend(head, {
          '',
          'Anything missing is being eaten by Windows Terminal or tmux.',
          'These always work regardless:',
          '   <leader>p   palette      <leader>sg   search      gO   symbol',
          '',
        })

        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, head)
        vim.bo[buf].modifiable = false
        local w = 66
        local win = vim.api.nvim_open_win(buf, true, {
          relative = 'editor',
          width = w,
          height = #head + #probes + 1,
          row = 3,
          col = math.floor((vim.o.columns - w) / 2),
          style = 'minimal',
          border = 'rounded',
          title = ' Which keys reach Neovim? ',
        })
        local seen = {}
        for _, pr in ipairs(probes) do
          vim.keymap.set('n', pr[1], function()
            if seen[pr[2]] then return end
            seen[pr[2]] = true
            vim.bo[buf].modifiable = true
            vim.api.nvim_buf_set_lines(buf, -1, -1, false, { '   \u{2713} ' .. pr[2] })
            vim.bo[buf].modifiable = false
          end, { buffer = buf })
        end
        vim.keymap.set('n', 'q', function() vim.api.nvim_win_close(win, true) end, { buffer = buf })
      end, { desc = 'Check which keybindings your terminal actually delivers' })

      -- ===================================================================
      -- Core palette entries
      -- ===================================================================
      palette.register {
        { category = 'File', name = 'Find file in project', desc = 'ctrl+p open quick', run = quickopen.files },
        { category = 'File', name = 'Open recent file', desc = 'oldfiles history', run = builtin.oldfiles },
        { category = 'File', name = 'Switch buffer', desc = 'open buffers tabs', run = builtin.buffers },
        { category = 'File', name = 'Close buffer', desc = 'bdelete', run = function() vim.cmd 'bdelete' end },
        { category = 'File', name = 'Save file', run = function() vim.cmd 'write' end },
        { category = 'File', name = 'Open Neovim config', run = function() builtin.find_files { cwd = vim.fn.stdpath 'config' } end },

        { category = 'Search', name = 'Search across project', desc = 'grep ripgrep contents alt+f', run = quickopen.grep },
        { category = 'Search', name = 'Search word under cursor', run = builtin.grep_string },
        { category = 'Search', name = 'Search in current file', run = function()
          builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown { winblend = 10, previewer = false })
        end },
        { category = 'Search', name = 'Search in open files only', run = function()
          builtin.live_grep { grep_open_files = true, prompt_title = 'Search open files' }
        end },
        { category = 'Search', name = 'Resume last search', run = builtin.resume },

        { category = 'Go', name = 'Symbol in file', desc = 'outline ctrl+p @', run = builtin.lsp_document_symbols },
        { category = 'Go', name = 'Symbol in workspace', desc = 'ctrl+t ctrl+p hash', run = builtin.lsp_dynamic_workspace_symbols },
        { category = 'Go', name = 'Definition', run = builtin.lsp_definitions },
        { category = 'Go', name = 'References', run = builtin.lsp_references },
        { category = 'Go', name = 'Implementation', run = builtin.lsp_implementations },
        { category = 'Go', name = 'Type definition', run = builtin.lsp_type_definitions },
        { category = 'Go', name = 'Line in file', desc = 'goto line number', run = function()
          vim.ui.input({ prompt = 'Go to line: ' }, function(n)
            if tonumber(n) then vim.cmd(tostring(tonumber(n))) end
          end)
        end },

        { category = 'Code', name = 'Rename symbol', run = vim.lsp.buf.rename },
        { category = 'Code', name = 'Code action', run = vim.lsp.buf.code_action },
        { category = 'Code', name = 'Format file', desc = 'leader f conform ruff stylua', run = function() require('conform').format { async = true, lsp_format = 'fallback' } end },
        { category = 'Code', name = 'Which formatter runs here?', desc = 'conforminfo debug formatting broken', run = function() vim.cmd 'ConformInfo' end },
        { category = 'Code', name = 'Toggle inlay hints', run = function()
          vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = 0 }, { bufnr = 0 })
        end },

        { category = 'Problems', name = 'Project diagnostics', desc = 'errors warnings', run = builtin.diagnostics },
        { category = 'Problems', name = 'File diagnostics (quickfix)', run = vim.diagnostic.setloclist },

        { category = 'Git', name = 'Status', run = function() builtin.git_status() end },
        { category = 'Git', name = 'Commits', run = function() builtin.git_commits() end },
        { category = 'Git', name = 'Branches', run = function() builtin.git_branches() end },
        { category = 'Git', name = 'Blame line', run = function() require('gitsigns').blame_line { full = true } end },
        { category = 'Git', name = 'Preview hunk', run = function() require('gitsigns').preview_hunk() end },
        { category = 'Git', name = 'Stage hunk', run = function() require('gitsigns').stage_hunk() end },
        { category = 'Git', name = 'Reset hunk', run = function() require('gitsigns').reset_hunk() end },

        { category = 'Appearance', name = 'Toggle light / dark', desc = 'background theme bright contrast colorscheme', run = function()
          vim.o.background = vim.o.background == 'dark' and 'light' or 'dark'
          vim.notify('background = ' .. vim.o.background)
        end },
        { category = 'Appearance', name = 'Toggle word wrap', desc = 'linebreak long lines', run = function()
          vim.wo.wrap = not vim.wo.wrap
          vim.wo.linebreak = vim.wo.wrap
          vim.notify('wrap = ' .. tostring(vim.wo.wrap))
        end },
        { category = 'Appearance', name = 'Toggle relative line numbers', desc = 'relativenumber', run = function()
          vim.wo.relativenumber = not vim.wo.relativenumber
        end },
        -- Everything listed here ships with Neovim now that the theme plugins
        -- are gone, so anything you pick stays portable. Previews live; make
        -- it permanent by changing the one line in lua/options.lua.
        { category = 'Appearance', name = 'Try another colorscheme', desc = 'theme colours preview switch', run = function()
          require('telescope.builtin').colorscheme { enable_preview = true }
        end },

        { category = 'Explorer', name = 'Browse this directory', desc = 'oil file manager tree', run = function() vim.cmd 'Oil' end },
        { category = 'Explorer', name = 'Browse in floating window', run = function() require('oil').toggle_float() end },

        { category = 'Help', name = 'Keybinding cheatsheet', desc = 'tutorial docs navigation', run = function()
          vim.cmd('edit ' .. vim.fn.fnameescape(vim.fn.stdpath 'config' .. '/doc/navigation-tutorial.md'))
        end },
        { category = 'Help', name = 'Check which keys my terminal sends', desc = 'keycheck windows terminal broken', run = function() vim.cmd 'KeyCheck' end },
        { category = 'Help', name = 'All keymaps', run = builtin.keymaps },
        { category = 'Help', name = 'Neovim help tags', run = builtin.help_tags },
        { category = 'Help', name = 'Run any :command', desc = 'ex command vim', run = builtin.commands },
        { category = 'Help', name = 'Telescope pickers', desc = 'builtin list', run = builtin.builtin },

        { category = 'Neovim', name = 'Plugin manager (Lazy)', run = function() vim.cmd 'Lazy' end },
        { category = 'Neovim', name = 'LSP installer (Mason)', run = function() vim.cmd 'Mason' end },
        { category = 'Neovim', name = 'Health check', run = function() vim.cmd 'checkhealth' end },
        { category = 'Neovim', name = 'Messages', desc = 'log output errors', run = function() vim.cmd 'messages' end },
      }
    end,
  },

}
