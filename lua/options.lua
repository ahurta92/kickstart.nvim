-- options.lua — settings that need no plugins.
--
-- Required from init.lua. (It was not, for a long while: nothing loaded this
-- file, so the swapfile and filetype settings below silently never applied.)

-- ---------------------------------------------------------------------
-- Colorscheme
-- ---------------------------------------------------------------------
-- Neovim's own built-in scheme, picked for portability over looks:
--
--   * It ships with the editor. A fresh clone of this config looks right
--     immediately, before lazy.nvim has downloaded anything — including on
--     a compute node with no network.
--   * It degrades. The semantic groups (strings, search, diagnostics,
--     selection) carry cterm colours, and body text falls through to the
--     terminal's own foreground, so on a 16- or 256-colour terminal it
--     stays readable. Truecolor-only plugin themes go flat grey there.
--   * It has real light and dark variants.
--
-- 'termguicolors' is deliberately NOT set. Neovim probes the terminal and
-- enables it when truecolor is available; forcing it on would break exactly
-- the terminals this scheme was chosen to survive.
-- Audition the alternatives live from the palette ("try another
-- colorscheme"); every one in that list also ships with Neovim. To keep a
-- different one, change this single line.
vim.cmd.colorscheme 'default'

-- Neovim asks the terminal for its background colour at startup and sets
-- 'background' from the reply, so a light terminal gets the light variant on
-- its own. When a terminal doesn't answer — some SSH and tmux setups don't —
-- flip it from the palette ("toggle light") or with :set background=light.
-- Assigning 'background' re-applies the scheme; no reload needed.

-- ---------------------------------------------------------------------
-- Node.js
-- ---------------------------------------------------------------------
-- Several Mason tools are Node packages whose shebang is `#!/usr/bin/env
-- node` — pyright among them. nvm is installed under ~/.nvm but nothing
-- sources it, so those tools died with exit 127 and pyright had not started
-- on this machine since June 2026.
--
-- Rather than hardcode a version, find nvm's newest Node and prepend it to
-- the PATH Neovim hands its children. Prefers an even-numbered major (the
-- LTS lines) over a newer odd one, since the tooling tracks LTS. No-ops when
-- node already resolves or nvm isn't installed, so it stays inert on every
-- other machine.
if vim.fn.executable 'node' == 0 then
  local best, best_rank
  -- expand() must only resolve the ~; given the wildcard too it returns every
  -- match newline-joined into one string, which glob() then finds nothing for.
  local pattern = vim.fn.expand '~' .. '/.nvm/versions/node/*/bin/node'
  for _, path in ipairs(vim.fn.glob(pattern, false, true)) do
    local major, minor, patch = path:match '/v(%d+)%.(%d+)%.(%d+)/'
    if major then
      major, minor, patch = tonumber(major), tonumber(minor), tonumber(patch)
      -- LTS first, then highest version within that group.
      local rank = (major % 2 == 0 and 1e12 or 0) + major * 1e8 + minor * 1e4 + patch
      if not best_rank or rank > best_rank then
        best, best_rank = path, rank
      end
    end
  end
  if best then vim.env.PATH = vim.fs.dirname(best) .. ':' .. vim.env.PATH end
end

-- ---------------------------------------------------------------------
-- Files
-- ---------------------------------------------------------------------
vim.opt.swapfile = false

-- Treat .hip and .cu as C++ so treesitter and clangd pick them up.
vim.filetype.add {
  extension = {
    hip = 'cpp',
    cu = 'cpp',
  },
}

-- NOTE: markdown settings (wrap, conceallevel, spell, j/k by visual line)
-- live in after/ftplugin/markdown.lua. There used to be a FileType autocmd
-- here doing a subset of the same thing; it was removed rather than kept in
-- two places.
