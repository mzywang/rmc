#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

FIXTURE="$(dirname "$0")/fixtures/companies.json"

test_post_creates_company() {
    BODY_FILE="$(mktemp)"
    STATUS="$(curl -s -o "$BODY_FILE" -w '%{http_code}' -X POST -d '{"company_id":"acme"}' "http://localhost:${PORT}/companies")"
    BODY="$(cat "$BODY_FILE")"
    rm -f "$BODY_FILE"

    assert_status 201 "$STATUS" || return 1

    for key in '"company_id"' '"acme"' '"created_at"'; do
        if [[ "$BODY" != *"$key"* ]]; then
            echo "expected body to contain $key, got '$BODY'"
            return 1
        fi
    done
}

test_post_duplicate_company_id_rejected() {
    BODY_FILE="$(mktemp)"
    STATUS="$(curl -s -o "$BODY_FILE" -w '%{http_code}' -X POST -d '{"company_id":"acme"}' "http://localhost:${PORT}/companies")"
    BODY="$(cat "$BODY_FILE")"
    rm -f "$BODY_FILE"

    assert_status 409 "$STATUS" || return 1

    if [[ "$BODY" != *"company_id already exists"* ]]; then
        echo "expected body to contain duplicate-rejection message, got '$BODY'"
        return 1
    fi
}

test_get_companies_includes_created_company() {
    BODY_FILE="$(mktemp)"
    STATUS="$(curl -s -o "$BODY_FILE" -w '%{http_code}' "http://localhost:${PORT}/companies")"
    BODY="$(cat "$BODY_FILE")"
    rm -f "$BODY_FILE"

    assert_status 200 "$STATUS" || return 1

    for key in '"company_id"' '"acme"' '"created_at"'; do
        if [[ "$BODY" != *"$key"* ]]; then
            echo "expected GET /companies body to contain $key, got '$BODY'"
            return 1
        fi
    done
}

test_post_creates_all_fixture_companies() {
    local posted=0
    while IFS= read -r company_json; do
        local company_id
        company_id="$(echo "$company_json" | jq -r '.company_id')"

        BODY_FILE="$(mktemp)"
        STATUS="$(curl -s -o "$BODY_FILE" -w '%{http_code}' -X POST -d "$company_json" "http://localhost:${PORT}/companies")"
        BODY="$(cat "$BODY_FILE")"
        rm -f "$BODY_FILE"

        assert_status 201 "$STATUS" || return 1
        if [[ "$BODY" != *"\"$company_id\""* ]]; then
            echo "expected POST response to contain $company_id, got '$BODY'"
            return 1
        fi

        posted=$((posted + 1))
    done < <(jq -c '.[]' "$FIXTURE")

    local expected_count
    expected_count="$(jq 'length' "$FIXTURE")"
    if [[ "$posted" -ne "$expected_count" ]]; then
        echo "expected to post $expected_count companies, posted $posted"
        return 1
    fi
}

test_get_companies_includes_all_fixture_companies() {
    BODY_FILE="$(mktemp)"
    STATUS="$(curl -s -o "$BODY_FILE" -w '%{http_code}' "http://localhost:${PORT}/companies")"
    BODY="$(cat "$BODY_FILE")"
    rm -f "$BODY_FILE"

    assert_status 200 "$STATUS" || return 1

    while IFS= read -r company_id; do
        if [[ "$BODY" != *"\"$company_id\""* ]]; then
            echo "expected GET /companies to include $company_id, got '$BODY'"
            return 1
        fi
    done < <(jq -r '.[].company_id' "$FIXTURE")
}

subtest "POST /companies creates a company" test_post_creates_company
subtest "POST /companies rejects a duplicate company_id" test_post_duplicate_company_id_rejected
subtest "GET /companies includes the created company" test_get_companies_includes_created_company
subtest "POST /companies creates all fixture companies" test_post_creates_all_fixture_companies
subtest "GET /companies includes all fixture companies" test_get_companies_includes_all_fixture_companies

subtest_exit
