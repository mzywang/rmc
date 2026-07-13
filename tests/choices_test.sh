#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

post_company() {
    local company_id="$1"
    local status
    status="$(curl -s -o /dev/null -w '%{http_code}' -X POST -d "{\"company_id\":\"$company_id\"}" "http://localhost:${PORT}/companies")"
    assert_status 201 "$status" || return 1
}

get_choices() {
    local query="${1:-}"
    BODY_FILE="$(mktemp)"
    STATUS="$(curl -s -o "$BODY_FILE" -w '%{http_code}' "http://localhost:${PORT}/choices${query}")"
    BODY="$(cat "$BODY_FILE")"
    rm -f "$BODY_FILE"
}

test_get_choices_returns_empty_page_with_no_companies() {
    get_choices
    assert_status 200 "$STATUS" || return 1

    if [[ "$(echo "$BODY" | jq -c '.choices')" != "[]" ]]; then
        echo "expected no choices, got '$BODY'"
        return 1
    fi
    if [[ "$(echo "$BODY" | jq -c '.next_cursor')" != "null" ]]; then
        echo "expected next_cursor null, got '$BODY'"
        return 1
    fi
}

test_get_choices_returns_empty_page_for_a_single_company() {
    post_company "choices-alpha" || return 1

    get_choices
    assert_status 200 "$STATUS" || return 1

    if [[ "$(echo "$BODY" | jq -c '.choices')" != "[]" ]]; then
        echo "expected no choices for a single company, got '$BODY'"
        return 1
    fi
    if [[ "$(echo "$BODY" | jq -c '.next_cursor')" != "null" ]]; then
        echo "expected next_cursor null, got '$BODY'"
        return 1
    fi
}

test_get_choices_returns_every_pair_of_companies() {
    post_company "choices-bravo" || return 1
    post_company "choices-charlie" || return 1

    get_choices
    assert_status 200 "$STATUS" || return 1

    local expected
    expected='[
        {"id":"choices-alpha:choices-bravo","option_a":"choices-alpha","option_b":"choices-bravo"},
        {"id":"choices-alpha:choices-charlie","option_a":"choices-alpha","option_b":"choices-charlie"},
        {"id":"choices-bravo:choices-charlie","option_a":"choices-bravo","option_b":"choices-charlie"}
    ]'
    local actual
    actual="$(echo "$BODY" | jq -c '.choices')"
    if [[ "$actual" != "$(echo "$expected" | jq -c '.')" ]]; then
        echo "expected all three pairs, got '$actual'"
        return 1
    fi
    if [[ "$(echo "$BODY" | jq -c '.next_cursor')" != "null" ]]; then
        echo "expected next_cursor null on the only page, got '$BODY'"
        return 1
    fi
}

test_get_choices_paginates_with_cursor_and_limit() {
    get_choices "?limit=1"
    assert_status 200 "$STATUS" || return 1

    if [[ "$(echo "$BODY" | jq -c '.choices')" != '[{"id":"choices-alpha:choices-bravo","option_a":"choices-alpha","option_b":"choices-bravo"}]' ]]; then
        echo "expected first page to hold only the alpha/bravo pair, got '$BODY'"
        return 1
    fi
    local cursor
    cursor="$(echo "$BODY" | jq -r '.next_cursor')"
    if [[ "$cursor" == "null" ]]; then
        echo "expected a next_cursor after the first page, got '$BODY'"
        return 1
    fi

    get_choices "?limit=1&cursor=${cursor}"
    assert_status 200 "$STATUS" || return 1
    if [[ "$(echo "$BODY" | jq -c '.choices')" != '[{"id":"choices-alpha:choices-charlie","option_a":"choices-alpha","option_b":"choices-charlie"}]' ]]; then
        echo "expected second page to hold only the alpha/charlie pair, got '$BODY'"
        return 1
    fi
    cursor="$(echo "$BODY" | jq -r '.next_cursor')"
    if [[ "$cursor" == "null" ]]; then
        echo "expected a next_cursor after the second page, got '$BODY'"
        return 1
    fi

    get_choices "?limit=1&cursor=${cursor}"
    assert_status 200 "$STATUS" || return 1
    if [[ "$(echo "$BODY" | jq -c '.choices')" != '[{"id":"choices-bravo:choices-charlie","option_a":"choices-bravo","option_b":"choices-charlie"}]' ]]; then
        echo "expected third page to hold only the bravo/charlie pair, got '$BODY'"
        return 1
    fi
    if [[ "$(echo "$BODY" | jq -c '.next_cursor')" != "null" ]]; then
        echo "expected next_cursor null after the last page, got '$BODY'"
        return 1
    fi
}

subtest "GET /choices returns an empty page with no companies" test_get_choices_returns_empty_page_with_no_companies
subtest "GET /choices returns an empty page for a single company" test_get_choices_returns_empty_page_for_a_single_company
subtest "GET /choices returns every pair of companies" test_get_choices_returns_every_pair_of_companies
subtest "GET /choices paginates with cursor and limit" test_get_choices_paginates_with_cursor_and_limit

subtest_exit
