#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
nimble build -d:release
./idle_clicker
