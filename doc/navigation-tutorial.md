# Navigation — one key and a palette

This config works the way VSCode does: you don't memorize chords, you
**search for what you want by name**. There is one key to know.

| Key | Does |
|-----|------|
| `Ctrl+P` | Find a file in the current project |
| `Ctrl+P` then `>` | **Command palette** — every action, by name |
| `Ctrl+P` then `@` | Symbol in this file |
| `Ctrl+P` then `#` | Symbol anywhere in the workspace |
| `Ctrl+P` then `:` | Go to line |
| `Ctrl+P` then `?` | Remind me what the prefixes are |

Three shortcuts for the ones you'll hit constantly:

| Key | Same as |
|-----|---------|
| `F1` | `Ctrl+P` `>` — the command palette |
| `Alt+F` | Search file *contents* across the project |
| `Ctrl+T` | `Ctrl+P` `#` — symbol in the workspace |

"Project" means the enclosing git repo when there is one, otherwise the
current directory — the same scoping VSCode gives a workspace folder.

---

## Why no Ctrl+Shift+P

Because Windows Terminal takes it. `Ctrl+Shift+P` opens *its* command
palette, `Ctrl+Shift+F` is *its* find, and they never reach the SSH
session at all.

Unbinding them in Windows Terminal does not fix it either. Over SSH,
`Ctrl+Shift+P` and plain `Ctrl+P` send the identical byte (`0x10`);
telling them apart needs the extended keyboard protocol, which Windows
Terminal doesn't speak. Neovim would have nothing to distinguish.

This is not a downgrade. In VSCode, `Ctrl+Shift+P` was only ever a
shortcut for "`Ctrl+P`, then type `>`" — the prefixes are the real
interface, and they're the same characters VSCode uses. No filename
begins with `>`, `@`, `#` or `:`, which is exactly why those were chosen.
`F1` is VSCode's own second binding for the palette, and it survives the
trip intact.

**Want the literal key back?** Windows Terminal can send arbitrary bytes.
In its `settings.json`, under `actions`:

```json
{ "command": { "action": "sendInput", "input": "\u001bf" }, "keys": "ctrl+shift+f" }
```

`\u001bf` is the byte sequence for Alt+F, which this config already maps
to project search — so Windows Terminal's `Ctrl+Shift+F` would reach
Neovim as Alt+F and do the right thing. You give up Windows Terminal's
own find to get it, which is why this is opt-in and not the default.
`F1` is one key and costs nothing.

**To check what your terminal actually delivers:** run `:KeyCheck` and
press the keys it lists. Each one that arrives prints a ✓. Anything
missing is being eaten before Neovim sees it.

Fallbacks that work no matter what, forever:

| Wanted | Always works |
|--------|--------------|
| Command palette | `<Space>p` |
| Search across project | `<Space>sg` |
| Symbol in this file | `gO` |

---

## Part 1 — The palette is the whole interface

Press `F1` (or `Ctrl+P` then `>`, or `<Space>p`) and type. Matching is
fuzzy across the category, the name, and a set of hidden synonyms, so you
can type the word you happen to think of rather than the word in the menu.

Entries are grouped by category:

| Category | What lives there |
|----------|------------------|
| `File` | find, recent, buffers, save, close |
| `Search` | project grep, word under cursor, in-file, open files |
| `Go` | symbols, definition, references, implementation, line |
| `Code` | rename, code action, format, inlay hints |
| `Problems` | diagnostics |
| `Git` | status, commits, branches, blame, hunks |
| `Project` | your named locations (see Part 2) |
| `Worktree` | MADNESS threads, live from `git worktree list` |
| `MADNESS` | `cm_build`, `cm_run`, `cm_unit`, release board |
| `Marks` | Harpoon pins |
| `Session` | restore buffers/layout per directory |
| `Explorer` | Oil file browser |
| `Claude` | browse or grep Claude's memory files |
| `Config` / `Neovim` / `Help` | init.lua, Lazy, Mason, keymaps, this file |

Whatever you ran last floats to the top next time you open the palette,
so the three things you actually use stay one keystroke away.

**Try it:** `F1`, type `gecko` → opens the Gecko source. Then `F1` again —
it's the first entry now.

---

## Part 2 — Projects

Every named location lives in one table in
`lua/custom/plugins/workspace.lua`, and each one gets its own palette
entry: `Project │ Open <label>`.

| Palette entry | Opens |
|---------------|-------|
| `Open Gecko source` | find_files |
| `Open Madness workspace (studies/refs/es_bench)` | find_files |
| `Open DALTON source` | find_files |
| `Open Development root` | find_files |
| `Open Notes` | find_files |
| `Open Project data root` | find_files |
| `Open Scratch calcs (gecko)` | Oil browser |
| `Open Scratch root (all calc dirs)` | Oil browser |
| `Open ES bench calcs` | Oil browser |
| `Open Molecule library` | Oil browser |

Three entries work across all of them:

- `Project │ Open a project...` — pick one, open it
- `Project │ Find a file in a project...` — pick one, then **filename**
  search. Works even on the Oil-browse dirs, so this is how you reach a
  calc file under scratch by typing part of its name.
- `Project │ Search in a project...` — pick one, then **content** grep

**Try it:** `F1` → `search in a project` → pick "DALTON source" →
type `polarizability`. Results update live; `<Enter>` jumps to the line.

Opening a project `cd`s into it, so `Ctrl+P` and `Alt+F` afterwards
are scoped there.

---

## Part 3 — MADNESS worktrees

The thread list comes live from `git worktree list` on the madness repo —
never hardcoded, so new threads appear automatically.

All three first **fuzzy-pick a worktree**, then `:tcd` the tab into it:

- `Worktree │ Find a file in a thread...`
- `Worktree │ Search in a thread...`
- `Worktree │ Browse a thread...`

Because of the `:tcd`, `Ctrl+P` and `Alt+F` afterwards operate on that
thread.

Build and run in the same thread, all under `MADNESS` in the palette:
`Build` (`cm_env && cm_build`), `Run h2o`, `Unit tests`, `Open cm shell
here`, `Run a cm_* command...`. Each opens a terminal split that has
already sourced `cm.sh` and `cm_use`'d the worktree's branch.

`MADNESS │ Open release board` opens `RELEASE_STATUS.md`;
`MADNESS │ Find a doc in this thread` fuzzy-finds the markdown in it.

**Try it:** `F1` → `search in a thread` → pick `raman` → type
`polarizability`. Then press `Alt+F` — note it now searches the raman
thread.

---

## Part 4 — Harpoon: pin the files you're bouncing between

This is the one thing that is *not* palette-first, because searching for
a bookmark by name defeats the purpose of a one-keystroke jump. Slots are
on `Alt+1` … `Alt+4`, the VSCode "switch to tab N" key.

- `F1` → `Marks │ Pin this file`
- `Alt+1` … `Alt+4` — jump straight to a pin
- `F1` → `Marks │ Show pinned files` — see and edit the list

**The intended loop:** search a thread for a hot spot → pin it → bounce
between pins with `Alt+1`/`Alt+2` all session without touching a picker.

---

## Part 5 — Oil survival guide (the browse dirs)

`Project │ Open Scratch root` drops you into an editable directory buffer:

- `<Enter>` — enter dir / open file
- `-` — go up one directory
- `gt` — sort newest first · `gn` — back to name order
- Edit lines like text, then `:w` — renames/deletes files (careful!)
- `g?` — full Oil help

---

## Part 6 — Two-minute self-test

No mouse, no `:e` with a typed path:

1. Open a file in the DALTON source containing `CC2`.
2. Jump to `RELEASE_STATUS.md`.
3. Search the `feat/tpa` worktree for `quadratic`.
4. Pin that file, open a calc dir under scratch root, jump back to the pin.
5. Find a calc file by name under gecko_calcs.
6. Jump to a function in the file you have open, then to one in another file.

Steps 1–5 are all `F1` plus a word. Step 6 is `Ctrl+P` `@`, then
`Ctrl+P` `#`. If that feels fast, you've got it.

---

## What's left on `<leader>`

`<Space>` is still leader, and kickstart's own maps are untouched:
`<Space>s…` search, `<Space>g…` git, `<Space>f` format, `<Space>q`
diagnostics, `gr…` LSP. They overlap the palette on purpose — use
whichever you reach for. The only custom leader key is `<Space>p`, the
palette fallback.

---

## Completion

One menu, one key. `<Tab>` accepts whatever is selected.

| Key | Does |
|-----|------|
| `<Tab>` | **accept** the selected item |
| `<C-n>` / `<C-p>` | next / previous (also `<Down>` / `<Up>`) |
| `<C-y>` | also accepts — kept from the old default preset |
| `<C-space>` | open the menu; press again for documentation |
| `<C-e>` | dismiss |
| `<C-k>` | toggle signature help |
| `<C-b>` / `<C-f>` | scroll the documentation window |

`<Tab>` is context-sensitive, in this order: inside an expanded snippet it
jumps to the next placeholder (`<S-Tab>` goes back); with the menu open it
accepts; with neither, it inserts a real tab.

Five sources feed that one menu:

| Source | Gives you |
|--------|-----------|
| `lsp` | real completions from clangd, pyright, lua_ls, fortls |
| `copilot` | GitHub Copilot, as ordinary menu entries |
| `buffer` | words already in your open buffers |
| `path` | filesystem paths |
| `snippets` | LuaSnip |

`buffer` matters more than it sounds: without it there was no menu at all
in any file with no LSP attached — plain text, markdown, an unconfigured
filetype.

Nothing is written to the buffer until you accept. blink's default inserts
each item as you arrow past it, which is unbearable once Copilot's
multi-line blocks are in the list, so `auto_insert` is off.

Ranking is left to the fuzzy matcher — Copilot competes with the LSP on
merit rather than being pinned above or below it. To bias it, add
`score_offset` to the `copilot` provider in `init.lua`: positive floats it
up, negative sinks it below real LSP results.

### If Copilot isn't suggesting anything

`F1` → `Copilot │ Status`. The usual answer is that you're signed out:
`F1` → `Copilot │ Sign in`.

Copilot runs on a self-contained server binary that downloads on first
use, so it does **not** need Node.js on your PATH. That was the old
problem — `github/copilot.vim` needed `node`, nvm is installed under
`~/.nvm` but nothing sources it, so Copilot had quietly been dead while
still holding `<Tab>` hostage. If the native binary ever fails, there are
two lines in `lua/custom/plugins/copilot.lua` that switch it to the nvm
Node instead.

---

## Formatting

`<Space>f` formats the buffer. In visual mode it formats just the
selection. Everything also formats on save, except C and C++.

| Filetype | Runs |
|----------|------|
| Lua | `stylua` |
| Python | `ruff_organize_imports`, then `ruff_format` |
| anything else | the LSP, if it offers formatting |

Python uses **ruff, not black or blackd**. conform has no `blackd`
formatter at all — the name does not exist in its registry, so
`python = { 'blackd' }` simply errors. Supporting it would mean a
hand-written formatter entry plus a `blackd` daemon running on every
machine you touch, which no compute-node job would have.

`ruff_format` solves the same problem blackd exists to solve — black's
slow cold start — without the daemon. It is one static Rust binary at
roughly 10ms, its output is a drop-in match for black, and it needs no
Node. `ruff_organize_imports` replaces isort and runs first.

Mason installs it automatically; it is listed in `ensure_installed` in
`init.lua`.

**When formatting does nothing**, `F1` → `Code │ Which formatter runs
here?` (`:ConformInfo`) shows what conform picked for the buffer and
whether the binary was actually found.

Note that pyright does **not** format — it reports no formatting
capability at all — so on Python the `lsp_format = 'fallback'` path can
never do anything. The formatter list above is the only thing that runs.

---

## External tools

Telescope hard-requires **ripgrep** for content search and prefers **fd** for
filename search. Neither ships with Neovim and neither lives in this repo, so
a fresh clone looks subtly broken: pickers open and return nothing.

    ~/dotfiles/bootstrap.sh        # or just ~/dotfiles/scripts/install-tools.sh

Installs both as single static musl binaries into `~/.local/bin` — no root, no
package manager, and no glibc dependency, so they work on compute nodes too.
Safe to re-run; it skips what is already present. ripgrep's download is
checksum-verified against the published `.sha256`; fd publishes no checksum,
so that one is trusted on HTTPS alone.

## Obsidian vault sync

The vault lives at `/gpfs/projects/rjh/adrian/repos/vaults/research` (vault
"IACS"). It syncs through **Obsidian Sync** via `obsidian-headless` (`ob`),
supervised by a systemd user service, so edits you write in Neovim upload
within a few seconds and edits from any other device land here without you
doing anything.

    systemctl --user status  obsidian-sync
    systemctl --user restart obsidian-sync
    journalctl --user -u obsidian-sync -f

Or from the palette: `F1` → `Obsidian │ Sync status` / `Sync log (follow)` /
`Restart sync`, plus `Open vault` and `Search vault`.

`scripts/obsidian-sync.sh` is what the service runs. Two non-obvious things
are pinned in it:

- **Node 24, specifically.** `ob` bundles `better-sqlite3`, a native module
  built against the cluster's `node.js/24.4.1` (`NODE_MODULE_VERSION 137`).
  Both nvm versions fail with `ERR_DLOPEN_FAILED`. Reinstall `ob` under a
  different Node and you must update `NODE_BIN` in the script to match.
- **`~/.local/bin` on PATH.** systemd does not read `~/.zshrc`, and that is
  where the `ob` symlink lives.

`~/.zshrc` separately puts nvm's Node on PATH for interactive shells, so `ob`
works when you run it by hand. That is a *different* Node from the one the
service uses, on purpose — see the pin above.

Linger is enabled for this account (`loginctl enable-linger`), which is what
lets the service keep running after you log out and start again at boot.
`loginctl disable-linger ahurtado` reverts it.

---

## Searching gitignored files

`fd` and `rg` both respect `.gitignore` out of the box, which meant whole
categories of writing were invisible to `Ctrl+P` and `Alt+F` — the
superpowers plans and specs under `docs/` in worktrees that gitignore
`docs/`, and everything under `.claude/`. Files you deliberately do not
commit but very much want to find.

Telescope is now configured with `--no-ignore-vcs` (stop honouring
`.gitignore`) and `--hidden` (reach dotted directories), plus an exclude list
for the junk. That covers `Ctrl+P`, `Alt+F`, and every `Search in a
project/thread` entry, since they all inherit telescope's defaults.

The excludes matter more than the flags. Measured on real repos:

| repo | default | `--hidden` naive | tuned |
|------|---------|------------------|-------|
| madness-workspace | 656 | 28,378 | 794 |
| madness | 2,179 | 10,334 | 2,229 |
| phase0 worktree | 2,178 | — | 2,195 (all 7 plans) |

Two of those excludes are non-obvious:

- **`build*`, not `build`.** The madness repo carries `build-40core`,
  `build_amd` and `build-amd96`; matching only `build` let 5,400 object
  files back in.
- **`.claude/worktrees`, path-scoped.** That directory holds 2,339 files of
  Claude Code worktree state next to 2 actual skills. Scoped to the path so a
  directory merely *named* `worktrees` elsewhere is unaffected.

### Hiding something without committing to .gitignore

`.ignore` and `.rgignore` files are **still honoured** under
`--no-ignore-vcs` (verified with both tools). That is the per-repo escape
hatch: drop a `.ignore` in a repo with, say,

    refs/_dalton_scratch/

and those 108 scratch files vanish from these pickers while staying exactly
as they are in `.gitignore`. Use the global list in `init.lua` for junk that
is junk everywhere, and a local `.ignore` for noise specific to one repo.

---

## Appearance

The colorscheme is **tokyonight** (`night`), set in
`lua/custom/plugins/theme.lua`.

`lua/options.lua` still sets Neovim's built-in `default` first, before
lazy.nvim has loaded anything, and that stays deliberately. It is the floor:
a fresh clone, an offline compute node, or a broken plugin directory all
still give readable colours, and tokyonight upgrades on top when present.
There is nothing to fall back to by hand.

tokyonight compiles its highlight groups to a disk cache and reloads them
without re-evaluating the palette, so it costs close to nothing at startup,
and it ships real integrations for what this config uses — telescope,
blink.cmp, gitsigns, which-key, render-markdown, mini.statusline.

Italics are off for comments and keywords on purpose: over SSH + tmux +
Windows Terminal some fonts substitute a slanted fallback at a different
width, which makes comment lines jitter.

Light terminals still work — `light_style = 'day'` is picked up when
`background` flips, so `F1` → `Appearance │ Toggle light / dark` behaves as
before. `F1` → `Appearance │ Try another colorscheme` previews alternatives
live.

## Markdown rendering

`render-markdown.nvim` is the only renderer. **headlines.nvim used to be
configured alongside it and both were loading** — each draws a background
behind headings and fenced code, so every heading got two stacked
backgrounds and every code block a doubled border. That was the ugliness;
headlines.nvim is gone.

Heading colour comes from the colorscheme, not from render-markdown:
tokyonight defines `@markup.heading.1..6` distinctly, so the six levels read
as different hues (H1 blue, H2 amber, H3 green, H4 teal) rather than as
identical bold white text behind a coloured bar.

The rest is tuned in `lua/custom/plugins/render-markdown.lua`: level icons
inline, backgrounds hugging the text (`width = 'block'`) instead of running
the full line, code blocks with a thin border and the language right-aligned,
rounded tables. `anti_conceal` reveals the raw markdown on the cursor line so
editing a link or table never fights the rendering.

## Obsidian notes

`obsidian.nvim` makes the vault's wiki links live — 95 of them across 21 of
30 notes, previously inert text in Neovim.

- `gf` follows the `[[link]]` under the cursor (native; the plugin sets
  `includeexpr`)
- `F1` → `Obsidian │ Backlinks to this note` — what links *here*, which has
  no equivalent elsewhere in this config
- `F1` → `Obsidian │ Today's daily note`, `Insert template`,
  `Rename note (updates backlinks)`, `Switch note by title`, `Table of
  contents`
- `:Obsidian <Tab>` for the rest

Two settings are off deliberately:

- **`ui.enable = false`** — obsidian.nvim ships its own conceal/highlight
  layer, on by default. render-markdown already owns rendering; running both
  recreates exactly the headlines.nvim double-decoration problem.
- **`frontmatter.enabled = false`** — only 2 of the 30 notes have
  frontmatter. Left on, it writes `id`/`aliases`/`tags` into the other 28 as
  you save them, and every one of those writes syncs to your other devices.
  Turn it on deliberately, not by accident.

Note `date_format` uses Moment.js tokens (`YYYY-MM-DD`), not strftime —
`%Y-%m-%d` silently creates a file named `%Y-%m-%d.md`.

All of it reaches the vault **from anywhere** — you do not have to be in a
note, or even in a markdown file. `F1` → `Obsidian │ Today's daily note` from
a C++ buffer in a worktree opens the vault's daily note; `Open vault` and
`Search vault` scope to the vault path explicitly, so your cwd is irrelevant.

That needed `cmd = 'Obsidian'` in the lazy spec alongside `ft = 'markdown'`.
With `ft` alone the plugin does not load until a markdown buffer exists, so
`:Obsidian` was undefined from a `.cpp` or `.lua` file and the palette
entries failed with "E492: Not an editor command".

This plugin does not sync anything; that is the headless client above. It
edits files on disk and the sync daemon picks them up within seconds.

---

## Adding things later

**A new project location** — edit `lua/custom/plugins/workspace.lua`,
add one line to the `projects` table:

```lua
{ dir = '/path/to/thing', desc = 'Label', browse = false },
```

`browse = false` → Telescope find_files (code); `browse = true` → Oil
(data dirs that may be empty or huge — find_files shows nothing at all in
an empty dir, which reads as a broken keybinding). It appears in the
palette immediately, including the three cross-project entries.

**A new action** — register it from any file under `lua/custom/plugins/`:

```lua
require('custom.palette').register {
  {
    category = 'MADNESS',
    name = 'Run the big benchmark',
    desc = 'extra words for fuzzy matching, not displayed',
    run = function() ... end,
  },
}
```

That is the whole extension point. Re-registering the same
category + name replaces the entry instead of duplicating it.
