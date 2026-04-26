#!/usr/bin/env bash
set -euo pipefail

# nix-nanobrew version update script
#
# Fetches the latest version from nanobrew.trilok.ai/version
# and updates the Nix derivation and flake lock.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PKG_FILE="$REPO_ROOT/pkgs/nanobrew/default.nix"

# 1. Get current version from Nix derivation
CURRENT_VERSION=$(grep 'version = "' "$PKG_FILE" | cut -d'"' -f2)
echo "Current nix-nanobrew version: v$CURRENT_VERSION"

# 2. Fetch latest version from nanobrew API
echo "Checking for updates..."
LATEST_VERSION=$(curl -fsSL https://nanobrew.trilok.ai/version | tr -d '[:space:]')

if [[ -z "$LATEST_VERSION" ]]; then
    echo "Error: Could not fetch latest version" >&2
    exit 1
fi

# 3. Compare and update
if [[ "$CURRENT_VERSION" == "$LATEST_VERSION" ]]; then
    echo "nanobrew is already at the latest version (v$LATEST_VERSION)."
    echo "Updating flake lock to ensure we have the latest commits..."
    nix flake update nanobrew-src --flake "$REPO_ROOT"
else
    echo "New version found: v$LATEST_VERSION"
    
    # Update the version string in the Nix derivation
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s/version = \"$CURRENT_VERSION\"/version = \"$LATEST_VERSION\"/" "$PKG_FILE"
    else
        sed -i "s/version = \"$CURRENT_VERSION\"/version = \"$LATEST_VERSION\"/" "$PKG_FILE"
    fi
    
    # Update the flake lock
    echo "Updating flake lock..."
    nix flake update nanobrew-src --flake "$REPO_ROOT"
    
    echo "Successfully updated nix-nanobrew to v$LATEST_VERSION"
fi
