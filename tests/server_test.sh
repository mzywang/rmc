#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

BODY_FILE="$(mktemp)"
STATUS="$(curl -s -o "$BODY_FILE" -w '%{http_code}' "http://localhost:${PORT}/hello")"
BODY="$(cat "$BODY_FILE")"
rm -f "$BODY_FILE"

assert_status 200 "$STATUS"
assert_body "Hello, world!" "$BODY"

STATUS="$(curl -s -o /dev/null -w '%{http_code}' "http://localhost:${PORT}/does-not-exist")"

assert_status 404 "$STATUS"
