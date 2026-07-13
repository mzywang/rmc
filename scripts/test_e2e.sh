#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

if [[ -z "${NO_COLOR:-}" ]]; then
    BOLD=$'\033[1m'
    DIM=$'\033[2m'
    RED=$'\033[31m'
    GREEN=$'\033[32m'
    RESET=$'\033[0m'
else
    BOLD=""
    DIM=""
    RED=""
    GREEN=""
    RESET=""
fi

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
failure_details=()

TIMEFORMAT='%R'

for test_file in tests/*_test.sh; do
    name="$(basename "$test_file")"

    total=$((total + 1))

    time_file="$(mktemp)"
    set +e
    {
        time {
            output="$("$test_file" 2>&1)"
            rc=$?
        }
    } 2>"$time_file"
    set -e
    elapsed="$(cat "$time_file")"
    rm -f "$time_file"

    if [[ "$rc" -eq 0 ]]; then
        echo "${GREEN}[PASS]${RESET} $name ${DIM}(${elapsed}s)${RESET}"
    else
        echo "${RED}[FAIL]${RESET} $name ${DIM}(${elapsed}s)${RESET}: $output"
        failures=$((failures + 1))
        failure_details+=("$name (${elapsed}s): $output")
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
    for detail in "${failure_details[@]}"; do
        echo "${RED}[FAIL]${RESET} $detail"
    done
    exit 1
fi
