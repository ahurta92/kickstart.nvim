-- sessions.lua — persistent sessions, keyed per working directory.
--
-- persistence.nvim auto-saves a session on exit, scoped to the cwd. Combined
-- with the Worktree palette entries you get "reopen a thread, get your
-- buffers and layout back" — a visual resume per thread.
--
-- In the palette (Ctrl+Shift+P, or <leader>p), search for "session".
return {
  {
    'folke/persistence.nvim',
    event = 'BufReadPre',
    opts = {},

    -- Registration has to happen before the plugin loads, or the entries
    -- would only appear after you had already opened a file.
    init = function()
      require('custom.palette').register {
        {
          category = 'Session',
          name = 'Restore session for this directory',
          desc = 'reopen buffers layout resume',
          run = function() require('persistence').load() end,
        },
        {
          category = 'Session',
          name = 'Restore last session',
          desc = 'reopen previous',
          run = function() require('persistence').load { last = true } end,
        },
        {
          category = 'Session',
          name = "Don't save this session",
          desc = 'stop persistence discard',
          run = function() require('persistence').stop() end,
        },
      }
    end,
  },
}
