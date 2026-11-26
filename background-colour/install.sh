#!/usr/bin/env bash

# Symlinks bgr, bgo, bgy, bgg, bgb, bgi, bgv, bgd into ~/.local/bin so they
# can be run from any terminal. Symlinks point at this repo, so a
# `git pull` updates the commands. Safe to re-run.

set -e

SRC="$(cd "$(dirname "$0")" && pwd)/bg.sh"
DEST="${BG_INSTALL_DIR:-$HOME/.local/bin}"

chmod +x "$SRC"
mkdir -p "$DEST"

for letter in r o y g b i v d; do
    ln -sf "$SRC" "$DEST/bg$letter"
done

echo "Installed bgr bgo bgy bgg bgb bgi bgv bgd into $DEST"
case ":$PATH:" in
    *":$DEST:"*) ;;
    *) echo "Note: $DEST is not on your PATH. Add this to your shell profile:"
       echo "  export PATH=\"$DEST:\$PATH\"" ;;
esac
