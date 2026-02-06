-- ~/.config/nvim/after/ftplugin/markdown.lua

-- 1. Essential Prose Settings (Buffer-local)
vim.opt_local.wrap = true -- Enable soft wrapping
vim.opt_local.linebreak = true -- Don't break words in the middle
vim.opt_local.spell = true -- Turn on spellcheck
vim.opt_local.conceallevel = 2 -- Hide markdown markup (like ** or [link])
vim.opt_local.scrolloff = 999 -- "Typewriter mode": keeps cursor centered vertically

-- 2. Trigger Zen Mode automatically
-- We wrap this in a schedule call to ensure the plugin is fully
-- loaded by Lazy before trying to call the command.
vim.schedule(function() vim.cmd 'ZenMode' end)

-- 3. Markdown-Specific Keymaps (Buffer-local)
-- Makes 'j' and 'k' move by visual line, not file line (important for wrapped text)
vim.keymap.set('n', 'j', 'gj', { buffer = true })
vim.keymap.set('n', 'k', 'gk', { buffer = true })

-- Quick toggle if you want to exit Zen without closing the file
vim.keymap.set('n', '<leader>z', ':ZenMode<CR>', { buffer = true, desc = 'Toggle Zen Mode' })
