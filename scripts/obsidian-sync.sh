#!/usr/bin/env bash
# obsidian-sync.sh — run Obsidian Sync headlessly, continuously.
#
# `ob` (obsidian-headless) is a Node program, and Node is not on PATH by
# default on xeonmax: nvm is installed but never sourced, and systemd does not
# read ~/.zshrc at all. So this script resolves Node itself, then hands off.
#
# Run directly to sync in the foreground, or let the systemd user service
# supervise it:
#
#   systemctl --user status  obsidian-sync
#   systemctl --user restart obsidian-sync
#   journalctl --user -u obsidian-sync -f
#
# --continuous is bidirectional and filesystem-watching: edits written by
# Neovim upload, and edits made on any other device land here, with no polling.

set -euo pipefail

VAULT="${OBSIDIAN_VAULT:-/gpfs/projects/rjh/adrian/repos/vaults/research}"

# systemd starts us with a bare PATH -- no ~/.local/bin, which is where the
# `ob` symlink lives. Interactive shells get this from ~/.zshrc; we cannot
# rely on that here.
case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) PATH="$HOME/.local/bin:$PATH"; export PATH ;;
esac

# --- find Node -------------------------------------------------------------
# obsidian-headless bundles better-sqlite3, a NATIVE module, so it loads only
# under the Node ABI it was built against. `ob` was installed with the
# cluster's node.js/24.4.1 (NODE_MODULE_VERSION 137). Both nvm versions fail:
# v22.11.0 is 127 and v25.8.1 is newer still, and each dies with
# ERR_DLOPEN_FAILED. So Node 24 is pinned here deliberately -- this is a hard
# requirement, not a preference.
#
# Reinstalling `ob` under a different Node means updating NODE_BIN to match,
# or the native module will refuse to load again.
NODE_BIN="${OBSIDIAN_NODE_BIN:-/gpfs/software/node-v24.4.1-linux-x64/bin}"

if [ -x "$NODE_BIN/node" ]; then
  PATH="$NODE_BIN:$PATH"; export PATH
elif command -v module >/dev/null 2>&1; then
  # Fallback if the software tree moves: ask the module system for it.
  module load node.js/24.4.1 2>/dev/null || module load nodejs 2>/dev/null || true
fi

command -v node >/dev/null 2>&1 || { echo "obsidian-sync: no node found" >&2; exit 1; }
command -v ob   >/dev/null 2>&1 || { echo "obsidian-sync: 'ob' not found (npm i -g obsidian-headless)" >&2; exit 1; }
[ -d "$VAULT" ] || { echo "obsidian-sync: vault not found: $VAULT" >&2; exit 1; }

# --path is passed explicitly on purpose. The registered vaultPath in
# ~/.config/obsidian-headless/sync/<id>/config.json still points at
# .../repos rather than the vault itself, which is what created the stray
# repos/.obsidian directory. Correcting it needs the E2E encryption password,
# so until then this overrides it on every run.
echo "obsidian-sync: node $(node --version), ob $(ob --version), vault $VAULT"
exec ob sync --continuous --path "$VAULT"
