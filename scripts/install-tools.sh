#!/usr/bin/env bash
# install-tools.sh — fetch the external binaries this config needs.
#
# Telescope hard-requires ripgrep for any content search, and prefers fd for
# filename search. Neither ships with Neovim and neither is in the repo, so a
# fresh clone looks broken in a way that is hard to diagnose: pickers open and
# silently return nothing.
#
# Both are single static musl binaries, so they need no root, no package
# manager, and no glibc of a particular vintage — they run on login nodes and
# compute nodes alike. They install to ~/.local/bin.
#
#   ./scripts/install-tools.sh          install anything missing
#   ./scripts/install-tools.sh --force  reinstall even if present
#
# Safe to re-run; it skips what is already there unless --force.

set -euo pipefail

BIN="$HOME/.local/bin"
MAN="$HOME/.local/share/man/man1"
FORCE="${1:-}"

case "$(uname -m)" in
  x86_64)  ARCH=x86_64 ;;
  aarch64) ARCH=aarch64 ;;
  *) echo "unsupported architecture: $(uname -m)" >&2; exit 1 ;;
esac

mkdir -p "$BIN" "$MAN"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

have() { command -v "$1" >/dev/null 2>&1 && [ -z "$FORCE" ]; }

# Latest tag from the GitHub API, so this does not rot to a pinned version.
latest() { curl -fsSL "https://api.github.com/repos/$1/releases/latest" \
  | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p' | head -1; }

# --- ripgrep ---------------------------------------------------------------
# Publishes a per-asset .sha256, so the download is verified.
if have rg; then
  echo "rg    already installed: $(command -v rg)"
else
  V="$(latest BurntSushi/ripgrep)"
  A="ripgrep-${V}-${ARCH}-unknown-linux-musl.tar.gz"
  U="https://github.com/BurntSushi/ripgrep/releases/download/${V}/${A}"
  echo "rg    downloading ${V}..."
  curl -fsSL -o "$TMP/$A" "$U"
  if curl -fsSL -o "$TMP/$A.sha256" "$U.sha256" 2>/dev/null; then
    want="$(awk '{print $1}' "$TMP/$A.sha256")"
    got="$(sha256sum "$TMP/$A" | awk '{print $1}')"
    [ "$want" = "$got" ] || { echo "rg    CHECKSUM MISMATCH -- refusing to install" >&2; exit 1; }
    echo "rg    checksum verified"
  else
    echo "rg    WARNING: no published checksum found; installing unverified" >&2
  fi
  tar xzf "$TMP/$A" -C "$TMP"
  install -m 0755 "$TMP/ripgrep-${V}-${ARCH}-unknown-linux-musl/rg" "$BIN/rg"
  install -m 0644 "$TMP/ripgrep-${V}-${ARCH}-unknown-linux-musl/doc/rg.1" "$MAN/rg.1"
  echo "rg    installed: $("$BIN/rg" --version | head -1)"
fi

# --- fd --------------------------------------------------------------------
# NOTE: sharkdp publishes no checksum file for fd, only the tarballs and
# .debs. This download is therefore trusted on HTTPS alone -- one notch weaker
# than ripgrep above. Nothing to do about it short of vendoring a hash here.
if have fd; then
  echo "fd    already installed: $(command -v fd)"
else
  V="$(latest sharkdp/fd)"
  A="fd-${V}-${ARCH}-unknown-linux-musl.tar.gz"
  echo "fd    downloading ${V}... (no upstream checksum published)"
  curl -fsSL -o "$TMP/$A" "https://github.com/sharkdp/fd/releases/download/${V}/${A}"
  tar xzf "$TMP/$A" -C "$TMP"
  install -m 0755 "$TMP/fd-${V}-${ARCH}-unknown-linux-musl/fd" "$BIN/fd"
  install -m 0644 "$TMP/fd-${V}-${ARCH}-unknown-linux-musl/fd.1" "$MAN/fd.1" 2>/dev/null || true
  echo "fd    installed: $("$BIN/fd" --version)"
fi

echo
case ":$PATH:" in
  *":$BIN:"*) echo "$BIN is on PATH. Done." ;;
  *) echo "WARNING: $BIN is not on your PATH. Add it in ~/.zshrc:"; echo "  export PATH=\"\$HOME/.local/bin:\$PATH\"" ;;
esac
