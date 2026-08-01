#!/bin/sh
# Usage: ./build.sh "My change description"
# Rebuilds system + home, names the GRUB entry, commits with that message.

set -e
cd "$(dirname "$0")"

LABEL="${1:-}"
if [ -z "$LABEL" ]; then
  printf "Build label (shown in GRUB, used as commit message): "
  read -r LABEL
fi
[ -z "$LABEL" ] && echo "Error: label cannot be empty." && exit 1

# Write label so configuration.nix can read it
printf '%s' "$LABEL" > label

# Stage and commit everything
git add -A
git commit -m "$LABEL" 2>/dev/null || echo "(nothing new to commit — rebuilding anyway)"

echo ""
echo "==> Building system (sudo required)..."
sudo nixos-rebuild switch --flake .#nixdan

echo ""
echo "==> Building home..."
home-manager switch --flake .#nixdan

echo ""
echo "Done. GRUB entry: NixOS — $LABEL"
