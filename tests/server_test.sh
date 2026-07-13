#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

test_unknown_route_returns_404() {
    STATUS="$(curl -s -o /dev/null -w '%{http_code}' "http://localhost:${PORT}/does-not-exist")"
    assert_status 404 "$STATUS" || return 1
}

subtest "GET on an unknown route returns 404" test_unknown_route_returns_404

subtest_exit
