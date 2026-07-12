#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

BIN="zig-out/bin/rmc"
export PORT="$(grep -E '^port:' config.yaml | awk '{print $2}')"

"$BIN" &
SERVER_PID=$!

cleanup() {
    kill "$SERVER_PID" 2>/dev/null || true
    wait "$SERVER_PID" 2>/dev/null || true
}
trap cleanup EXIT

for _ in $(seq 1 50); do
    if curl -s -o /dev/null "http://localhost:${PORT}/hello"; then
        break
    fi
    sleep 0.1
done

total=0
failures=0

for test_file in tests/*_test.sh; do
    name="$(basename "$test_file" _test.sh)"

    total=$((total + 1))
    if output="$("$test_file" 2>&1)"; then
        echo "[PASS] $name"
    else
        echo "[FAIL] $name: $output"
        failures=$((failures + 1))
    fi
done

echo
echo "$((total - failures))/$total tests passed"

if [[ "$failures" -gt 0 ]]; then
    exit 1
fi
