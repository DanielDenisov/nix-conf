#!/bin/sh
# Usage: ./build.sh "My change description"
# Builds system + home first. Only commits if both succeed.

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

LABEL="${1:-}"
if [ -z "$LABEL" ]; then
  printf "Build label (shown in boot menu, used as commit message): "
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
if ! home_switch; then
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
echo "Done. Boot entry: NixOS — $SAFE_LABEL"
[ "$SAFE_LABEL" != "$LABEL" ] && echo "Note: label was sanitized from '$LABEL' to '$SAFE_LABEL' for boot-entry compatibility."
