#!/bin/sh
# Rebuild home-manager only (no sudo, no system rebuild).
# Use this when only home.nix changed.
# Usage: ./homebuild.sh "optional commit message"

cd "$(dirname "$0")"

# Apply the home generation.
# Prefer the home-manager CLI, but fall back to building the activation package
# straight from this flake. The CLI is installed BY the home generation
# (programs.home-manager.enable), so on a fresh clone it does not exist yet --
# the fallback is what makes "git clone && build" work on a clean machine.
home_switch() {
  if command -v home-manager >/dev/null 2>&1; then
    home-manager switch --flake .#nixdan
  else
    echo "(home-manager CLI not on PATH — activating from the flake directly)"
    nix build --no-link --print-out-paths .#homeConfigurations.nixdan.activationPackage \
      | { read -r out; "$out/activate"; }
  fi
}

echo "==> Building home..."
if ! home_switch; then
  echo ""
  echo "Home build FAILED — nothing committed."
  exit 1
fi

echo ""
echo "==> Committing..."
git add -A
git commit -m "${1:-home: rebuild}" 2>/dev/null || echo "(nothing new to commit)"

echo "Done."
