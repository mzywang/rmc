#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

(zig build run 2>&1 | sed -u 's/^/[backend] /') &
BACKEND_PID=$!

(cd web && pnpm run dev 2>&1 | sed -u 's/^/[frontend] /') &
FRONTEND_PID=$!

cleanup() {
    kill "$BACKEND_PID" "$FRONTEND_PID" 2>/dev/null || true
    wait "$BACKEND_PID" "$FRONTEND_PID" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

wait
