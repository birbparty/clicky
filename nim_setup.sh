#!/usr/bin/env bash
# nim_setup.sh — idempotent setup for the Nim + naylib idle-clicker port.
# Installs: Xcode CLI tools (naylib compiles raylib C source), Homebrew, Nim + nimble.
# Re-runs are no-ops if everything is already present.

set -euo pipefail

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m  ok\033[0m %s\n' "$*"; }
skip() { printf '\033[1;33m  --\033[0m %s\n' "$*"; }

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This script targets macOS. Adapt the Homebrew calls for your OS." >&2
  exit 1
fi

# 1. Xcode Command Line Tools (naylib bundles raylib C source and compiles it locally).
log "Xcode Command Line Tools"
if xcode-select -p >/dev/null 2>&1; then
  skip "already installed at $(xcode-select -p)"
else
  log "triggering xcode-select --install (a GUI dialog will appear; finish it then re-run this script)"
  xcode-select --install || true
  exit 1
fi

# 2. Homebrew.
log "Homebrew"
if command -v brew >/dev/null 2>&1; then
  skip "already installed ($(brew --prefix))"
else
  log "installing Homebrew (will prompt for sudo)"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# 3. Nim (Homebrew formula installs both nim and nimble).
log "Nim + nimble"
if command -v nim >/dev/null 2>&1 && command -v nimble >/dev/null 2>&1; then
  skip "already installed ($(nim --version | head -n1))"
else
  brew install nim
fi

# naylib itself (and the raylib C sources it bundles) is fetched by `nimble install -d`
# inside the project directory, which is the agent's job once `idle_clicker.nimble`
# exists. No system-level raylib needed.

ok "Nim toolchain ready. After writing idle_clicker.nimble, run: nimble install -d && nimble build -d:release"
