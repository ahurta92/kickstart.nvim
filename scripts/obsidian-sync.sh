#!/usr/bin/env bash
# obsidian-sync.sh — run Obsidian Sync headlessly, continuously.
#
# `ob` (obsidian-headless) is a Node program, and systemd does not read
# ~/.zshrc, so neither nvm nor ~/.local/bin is on PATH here. This script
# resolves both itself, then hands off.
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
#
# Per-machine overrides (e.g. from a site file or `systemctl --user edit`):
#   OBSIDIAN_VAULT     vault directory        (default ~/vaults/research)
#   OBSIDIAN_NODE_BIN  dir containing `node`  (default: auto, see below)

set -euo pipefail

# systemd never reads the site file, which is where the cluster exports its
# /gpfs vault path -- so without this the service would look in the default,
# find nothing, and restart-loop. Take ONLY that one variable from it, in a
# throwaway subshell, so none of the site's PATH/alias setup leaks in here.
SITEF="${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/site.sh"
if [[ -z "${OBSIDIAN_VAULT:-}" && -r "$SITEF" ]]; then
  OBSIDIAN_VAULT="$(bash -c '_path_prepend() { :; }; . "$1" >/dev/null 2>&1; printf %s "${OBSIDIAN_VAULT:-}"' _ "$SITEF")"
fi
VAULT="${OBSIDIAN_VAULT:-$HOME/vaults/research}"

case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) PATH="$HOME/.local/bin:$PATH"; export PATH ;;
esac

# --- find Node -------------------------------------------------------------
# obsidian-headless bundles better-sqlite3, a NATIVE module: it loads only
# under the Node ABI *and CPU architecture* it was built for. So Node must be
# the one `ob` was installed with -- not merely any Node on PATH. Order:
#   1. $OBSIDIAN_NODE_BIN, if set
#   2. the cluster's pinned Node 24 (what `ob` was built with on seawulf)
#   3. nvm's default alias (what bootstrap.sh installs with on other machines)
pick_node() {
  if [[ -n "${OBSIDIAN_NODE_BIN:-}" ]]; then echo "$OBSIDIAN_NODE_BIN"; return; fi
  local cluster=/gpfs/software/node-v24.4.1-linux-x64/bin
  [[ -x "$cluster/node" ]] && { echo "$cluster"; return; }
  local nvm="$HOME/.nvm" alias
  if [[ -r "$nvm/alias/default" ]]; then
    alias="$(<"$nvm/alias/default")"
    # alias may be a bare major ("22") -- take the newest matching install
    ls -d "$nvm/versions/node/v${alias#v}"*/bin 2>/dev/null | sort -V | tail -1
  fi
}
NODE_BIN="$(pick_node)"
[[ -n "$NODE_BIN" && -x "$NODE_BIN/node" ]] && { PATH="$NODE_BIN:$PATH"; export PATH; }

command -v node >/dev/null 2>&1 || { echo "obsidian-sync: no node found" >&2; exit 1; }
command -v ob   >/dev/null 2>&1 || { echo "obsidian-sync: 'ob' not found (npm i -g --prefix ~/.local obsidian-headless)" >&2; exit 1; }
[[ -d "$VAULT" ]] || { echo "obsidian-sync: vault not found: $VAULT" >&2; exit 1; }

# Fail loudly and early on an ABI/arch mismatch instead of letting `ob` die
# with a bare ERR_DLOPEN_FAILED on every restart.
SQLITE="$(dirname "$(readlink -f "$(command -v ob)")")/node_modules/better-sqlite3/build/Release/better_sqlite3.node"
if [[ -f "$SQLITE" ]] && ! node -e "require(process.argv[1])" "$SQLITE" 2>/dev/null; then
  echo "obsidian-sync: better-sqlite3 will not load under node $(node --version) ($(uname -m))." >&2
  echo "  Reinstall ob with this node, or set OBSIDIAN_NODE_BIN to the one it was built with." >&2
  exit 1
fi

echo "obsidian-sync: node $(node --version), ob $(ob --version), vault $VAULT"
exec ob sync --continuous --path "$VAULT"
