-- copilot.lua — GitHub Copilot, feeding the completion menu instead of
-- owning its own keybinding.
--
-- This replaced github/copilot.vim, for two reasons:
--
--   * copilot.vim is vimscript with no API for handing suggestions to a
--     completion engine, so it can only ever be separate ghost text.
--   * it claimed <Tab> globally (`copilot#Accept()`), which is exactly the
--     key we now want for accepting from the blink.cmp menu.
--
-- copilot.lua defaults to a self-contained server binary that it downloads on
-- first use, so it does NOT need Node.js on PATH. That matters here: nvm is
-- installed under ~/.nvm but nothing sources it, which is why Copilot had
-- quietly stopped working. If the native binary ever fails, fall back to
-- Node by adding these two lines to opts (v22+ is required; v22.11.0 and
-- v25.8.1 are both installed under nvm):
--
--   server = { type = 'nodejs' },
--   copilot_node_command = vim.fn.expand '~/.nvm/versions/node/v22.11.0/bin/node',
--
-- Suggestions appear in the blink.cmp menu — see the `copilot` source in
-- init.lua. Sign in with the palette entry below, or :Copilot auth.
return {
  {
    'zbirenbaum/copilot.lua',
    cmd = 'Copilot',
    event = 'InsertEnter',

    opts = {
      -- Both off deliberately. Copilot reaches you through the completion
      -- menu; leaving these on would give it a second, competing inline UI
      -- with its own accept key.
      suggestion = { enabled = false },
      panel = { enabled = false },
    },

    -- Registered before the plugin loads, so the entries are there from the
    -- start rather than only after the first insert.
    init = function()
      require('custom.palette').register {
        { category = 'Copilot', name = 'Sign in', desc = 'auth login github token', run = function() vim.cmd 'Copilot auth' end },
        { category = 'Copilot', name = 'Status', desc = 'working broken node check', run = function() vim.cmd 'Copilot status' end },
        { category = 'Copilot', name = 'Enable', run = function() vim.cmd 'Copilot enable' end },
        { category = 'Copilot', name = 'Disable', desc = 'turn off suggestions', run = function() vim.cmd 'Copilot disable' end },
      }
    end,
  },
}
