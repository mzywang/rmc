#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

BIN="zig-out/bin/rmc"
PORT="$(grep -E '^port:' config.yaml | awk '{print $2}')"

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

BODY_FILE="$(mktemp)"
STATUS="$(curl -s -o "$BODY_FILE" -w '%{http_code}' "http://localhost:${PORT}/hello")"
BODY="$(cat "$BODY_FILE")"
rm -f "$BODY_FILE"

if [[ "$STATUS" != "200" ]]; then
    echo "expected status 200, got $STATUS"
    exit 1
fi

if [[ "$BODY" != "Hello, world!" ]]; then
    echo "expected body 'Hello, world!', got '$BODY'"
    exit 1
fi

echo "e2e test passed"
