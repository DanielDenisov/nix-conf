#!/bin/sh
# Usage: ./build.sh "My change description"
# Builds system + home first. Only commits if both succeed.

cd "$(dirname "$0")"

LABEL="${1:-}"
if [ -z "$LABEL" ]; then
  printf "Build label (shown in GRUB, used as commit message): "
  read -r LABEL
fi
[ -z "$LABEL" ] && echo "Error: label cannot be empty." && exit 1

# NixOS label must match [a-zA-Z0-9:_.-]+ — sanitize by replacing spaces/bad chars with hyphens
SAFE_LABEL=$(printf '%s' "$LABEL" | tr ' ' '-' | tr -cd 'a-zA-Z0-9:_.-')
[ -z "$SAFE_LABEL" ] && echo "Error: label contains no valid characters." && exit 1

# Write sanitized label for configuration.nix to read
printf '%s' "$SAFE_LABEL" > label

echo "==> Building system (sudo required)..."
if ! sudo nixos-rebuild switch --flake .#nixdan; then
  echo ""
  echo "System build FAILED — nothing committed."
  exit 1
fi

echo ""
echo "==> Building home..."
if ! home-manager switch --flake .#nixdan; then
  echo ""
  echo "Home build FAILED — nothing committed."
  exit 1
fi

# Both succeeded — now commit
echo ""
echo "==> Committing..."
git add -A
git commit -m "$LABEL" 2>/dev/null || echo "(nothing new to commit)"

echo ""
echo "Done. GRUB entry: NixOS — $SAFE_LABEL"
[ "$SAFE_LABEL" != "$LABEL" ] && echo "Note: label was sanitized from '$LABEL' to '$SAFE_LABEL' for GRUB compatibility."
