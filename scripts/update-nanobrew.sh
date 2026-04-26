#!/usr/bin/env bash
set -euo pipefail

# nix-nanobrew version and binary hash update script
#
# Fetches the latest version from nanobrew.trilok.ai/version
# and updates the Nix derivation with new asset URLs and SHA256 hashes.

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
else
    echo "New version found: v$LATEST_VERSION"
    
    echo "Fetching new SHA256 hashes..."
    
    fetch_hash() {
        local file=$1
        curl -L "https://github.com/justrach/nanobrew/releases/download/v${LATEST_VERSION}/${file}.sha256" 2>/dev/null | cut -d' ' -f1 || echo ""
    }

    # Fetch hashes for all supported platforms
    HASH_ARM_DARWIN=$(fetch_hash "nb-arm64-apple-darwin.tar.gz")
    HASH_X64_DARWIN=$(fetch_hash "nb-x86_64-apple-darwin.tar.gz")
    HASH_X64_LINUX=$(fetch_hash "nb-x86_64-linux.tar.gz")
    # Fallback for arm64-linux as it sometimes uses a different name
    HASH_ARM_LINUX=$(fetch_hash "nb-arm64-linux.tar.gz")
    if [[ -z "$HASH_ARM_LINUX" ]]; then
        HASH_ARM_LINUX=$(fetch_hash "nb-aarch64-linux.tar.gz")
    fi

    if [[ -z "$HASH_ARM_DARWIN" || -z "$HASH_X64_DARWIN" ]]; then
        echo "Error: Could not fetch all required hashes for v$LATEST_VERSION" >&2
        exit 1
    fi

    echo "Updating derivation..."

    # Update version and hashes using sed
    sed_cmd() {
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "$@"
        else
            sed -i "$@"
        fi
    }

    sed_cmd "s/version = \"$CURRENT_VERSION\"/version = \"$LATEST_VERSION\"/" "$PKG_FILE"
    
    # Use a temporary file to rebuild the platforms block with new hashes
    # This is safer than complex regex replacements for multiple hashes
    cat > "$PKG_FILE.tmp" <<EOF
{ lib, stdenv, fetchurl, ... }:

let
  version = "${LATEST_VERSION}";

  # Map Nix system strings to GitHub asset names and hashes
  platforms = {
    "aarch64-darwin" = {
      name = "nb-arm64-apple-darwin.tar.gz";
      sha256 = "${HASH_ARM_DARWIN}";
    };
    "x86_64-darwin" = {
      name = "nb-x86_64-apple-darwin.tar.gz";
      sha256 = "${HASH_X64_DARWIN}";
    };
    "x86_64-linux" = {
      name = "nb-x86_64-linux.tar.gz";
      sha256 = "${HASH_X64_LINUX}";
    };
    "aarch64-linux" = {
      name = "nb-arm64-linux.tar.gz";
      sha256 = "${HASH_ARM_LINUX}";
    };
  };

  plat =
    platforms.\${stdenv.hostPlatform.system}
    or (throw "Unsupported system: \${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation {
  pname = "nanobrew";
  inherit version;

  src = fetchurl {
    url = "https://github.com/justrach/nanobrew/releases/download/v\${version}/\${plat.name}";
    inherit (plat) sha256;
  };

  sourceRoot = ".";

  installPhase = ''
    install -Dm755 nb \$out/bin/nb
  '';

  meta = with lib; {
    description = "Fast Homebrew alternative written in Zig";
    homepage = "https://github.com/justrach/nanobrew";
    license = licenses.asl20;
    mainProgram = "nb";
    platforms = builtins.attrNames platforms;
  };
}
EOF
    mv "$PKG_FILE.tmp" "$PKG_FILE"

    echo "Successfully updated nix-nanobrew to v$LATEST_VERSION"
fi
