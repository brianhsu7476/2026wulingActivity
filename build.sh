#!/usr/bin/env bash
# Build a self-contained HTML deck from slides.md (no Docker required).
set -euo pipefail
cd "$(dirname "$0")"

NODE_VERSION="22.16.0"
NODE_DIR=".tools/node-v${NODE_VERSION}-linux-x64"
NODE_BIN="${NODE_DIR}/bin"

if [[ ! -x "${NODE_BIN}/node" ]]; then
  mkdir -p .tools
  arch="$(uname -m)"
  case "$arch" in
    x86_64) node_arch="linux-x64" ;;
    aarch64|arm64) node_arch="linux-arm64" ;;
    *)
      echo "Unsupported CPU architecture: $arch" >&2
      exit 1
      ;;
  esac
  node_dir=".tools/node-v${NODE_VERSION}-${node_arch}"
  NODE_DIR="$node_dir"
  NODE_BIN="${NODE_DIR}/bin"
  tarball="node-v${NODE_VERSION}-${node_arch}.tar.xz"
  url="https://nodejs.org/dist/v${NODE_VERSION}/${tarball}"
  echo "Downloading Node.js ${NODE_VERSION} (${node_arch})..."
  curl -fsSL "$url" | tar -xJ -C .tools
fi

export PATH="${NODE_BIN}:$PATH"
npx --yes @marp-team/marp-cli@latest --no-stdin slides.md --html -o index.html

echo "Built index.html (static, self-contained) — commit it for GitHub Pages."
