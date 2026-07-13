#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

test_get_choices_returns_empty_list() {
    BODY_FILE="$(mktemp)"
    STATUS="$(curl -s -o "$BODY_FILE" -w '%{http_code}' "http://localhost:${PORT}/choices")"
    BODY="$(cat "$BODY_FILE")"
    rm -f "$BODY_FILE"

    assert_status 200 "$STATUS" || return 1
    assert_body "[]" "$BODY" || return 1
}

subtest "GET /choices returns an empty list" test_get_choices_returns_empty_list

subtest_exit
