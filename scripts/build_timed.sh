#!/usr/bin/env bash
set -uo pipefail
cd "$(dirname "$0")/.."
start=$(python3 -c 'import time; print(time.time())')
nimble build -d:release
status=$?
end=$(python3 -c 'import time; print(time.time())')
python3 -c "print(f'Build time: {$end - $start:.3f}s')"
exit $status
