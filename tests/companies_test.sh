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

FIXTURE="$(dirname "$0")/fixtures/companies.json"

posted=0
while IFS= read -r company_json; do
    company_id="$(echo "$company_json" | jq -r '.company_id')"

    BODY_FILE="$(mktemp)"
    STATUS="$(curl -s -o "$BODY_FILE" -w '%{http_code}' -X POST -d "$company_json" "http://localhost:${PORT}/companies")"
    BODY="$(cat "$BODY_FILE")"
    rm -f "$BODY_FILE"

    assert_status 201 "$STATUS"
    if [[ "$BODY" != *"\"$company_id\""* ]]; then
        echo "expected POST response to contain $company_id, got '$BODY'"
        exit 1
    fi

    posted=$((posted + 1))
done < <(jq -c '.[]' "$FIXTURE")

expected_count="$(jq 'length' "$FIXTURE")"
if [[ "$posted" -ne "$expected_count" ]]; then
    echo "expected to post $expected_count companies, posted $posted"
    exit 1
fi

BODY_FILE="$(mktemp)"
STATUS="$(curl -s -o "$BODY_FILE" -w '%{http_code}' "http://localhost:${PORT}/companies")"
BODY="$(cat "$BODY_FILE")"
rm -f "$BODY_FILE"

assert_status 200 "$STATUS"

while IFS= read -r company_id; do
    if [[ "$BODY" != *"\"$company_id\""* ]]; then
        echo "expected GET /companies to include $company_id, got '$BODY'"
        exit 1
    fi
done < <(jq -r '.[].company_id' "$FIXTURE")
