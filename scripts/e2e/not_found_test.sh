#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

STATUS="$(curl -s -o /dev/null -w '%{http_code}' "http://localhost:${PORT}/does-not-exist")"

assert_status 404 "$STATUS"
