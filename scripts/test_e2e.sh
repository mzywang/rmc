#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
source "tests/lib.sh"

section() {
    echo
    echo "${BOLD}── $1 ──${RESET}"
}

BIN="zig-out/bin/rmc"
TEST_CONFIG="tests/config.yaml"
export PORT="$(grep -E '^port:' "$TEST_CONFIG" | awk '{print $2}')"

SERVER_LOG="$(mktemp)"

"$BIN" --config "$TEST_CONFIG" > "$SERVER_LOG" 2>&1 &
SERVER_PID=$!

cleanup() {
    kill "$SERVER_PID" 2>/dev/null || true
    wait "$SERVER_PID" 2>/dev/null || true
    rm -f "$SERVER_LOG"
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
failure_names=()

TIMEFORMAT='%R'

for test_file in tests/*_test.sh; do
    name="$(basename "$test_file")"

    total=$((total + 1))

    echo
    echo "${BOLD}${name}${RESET}"

    time_file="$(mktemp)"
    set +e
    { time "$test_file"; } 2>"$time_file"
    rc=$?
    set -e
    elapsed="$(cat "$time_file")"
    rm -f "$time_file"

    if [[ "$rc" -eq 0 ]]; then
        echo "${GREEN}[PASS]${RESET} $name ${DIM}(${elapsed}s)${RESET}"
    else
        echo "${RED}[FAIL]${RESET} $name ${DIM}(${elapsed}s)${RESET}"
        failures=$((failures + 1))
        failure_names+=("$name (${elapsed}s)")
    fi
done

if [[ "$failures" -eq 0 ]]; then
    echo
    echo "${GREEN}${BOLD}$((total - failures))/$total tests passed${RESET}"
else
    echo
    echo "${RED}${BOLD}$((total - failures))/$total tests passed${RESET}"

    section "server log"
    cat "$SERVER_LOG"

    section "failures"
    for name in "${failure_names[@]}"; do
        echo "${RED}[FAIL]${RESET} $name"
    done
    exit 1
fi
