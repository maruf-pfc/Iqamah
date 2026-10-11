#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root/client"
bun install --frozen-lockfile --ignore-scripts
bun run build
cp "$root/client/dist/index.html" "$root/mobile/assets/web/index.html"
