#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

BODY_FILE="$(mktemp)"
STATUS="$(curl -s -o "$BODY_FILE" -w '%{http_code}' -X POST -d '{"company_id":"acme"}' "http://localhost:${PORT}/companies")"
BODY="$(cat "$BODY_FILE")"
rm -f "$BODY_FILE"

assert_status 201 "$STATUS"

for key in '"company_id"' '"acme"' '"created_at"'; do
    if [[ "$BODY" != *"$key"* ]]; then
        echo "expected body to contain $key, got '$BODY'"
        exit 1
    fi
done

BODY_FILE="$(mktemp)"
STATUS="$(curl -s -o "$BODY_FILE" -w '%{http_code}' -X POST -d '{"company_id":"acme"}' "http://localhost:${PORT}/companies")"
BODY="$(cat "$BODY_FILE")"
rm -f "$BODY_FILE"

assert_status 409 "$STATUS"

if [[ "$BODY" != *"company_id already exists"* ]]; then
    echo "expected body to contain duplicate-rejection message, got '$BODY'"
    exit 1
fi

BODY_FILE="$(mktemp)"
STATUS="$(curl -s -o "$BODY_FILE" -w '%{http_code}' "http://localhost:${PORT}/companies")"
BODY="$(cat "$BODY_FILE")"
rm -f "$BODY_FILE"

assert_status 200 "$STATUS"

for key in '"company_id"' '"acme"' '"created_at"'; do
    if [[ "$BODY" != *"$key"* ]]; then
        echo "expected GET /companies body to contain $key, got '$BODY'"
        exit 1
    fi
done
