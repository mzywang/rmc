#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

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
