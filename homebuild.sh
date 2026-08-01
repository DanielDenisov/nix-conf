#!/bin/sh
# Rebuild home-manager only (no sudo, no system rebuild).
# Use this when only home.nix changed.
# Usage: ./homebuild.sh "optional commit message"

cd "$(dirname "$0")"

echo "==> Building home..."
if ! home-manager switch --flake .#nixdan; then
  echo ""
  echo "Home build FAILED — nothing committed."
  exit 1
fi

echo ""
echo "==> Committing..."
git add -A
git commit -m "${1:-home: rebuild}" 2>/dev/null || echo "(nothing new to commit)"

echo "Done."
