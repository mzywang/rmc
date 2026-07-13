if [[ -z "${NO_COLOR:-}" ]]; then
    BOLD=$'\033[1m'
    DIM=$'\033[2m'
    RED=$'\033[31m'
    GREEN=$'\033[32m'
    RESET=$'\033[0m'
else
    BOLD=""
    DIM=""
    RED=""
    GREEN=""
    RESET=""
fi

SUBTEST_FAILURES=0

assert_status() {
    local expected="$1" actual="$2"
    if [[ "$actual" != "$expected" ]]; then
        echo "expected status $expected, got $actual"
        return 1
    fi
}

assert_body() {
    local expected="$1" actual="$2"
    if [[ "$actual" != "$expected" ]]; then
        echo "expected body '$expected', got '$actual'"
        return 1
    fi
}

subtest() {
    local name="$1" fn="$2"
    local output
    if output="$("$fn" 2>&1)"; then
        echo "  ${GREEN}[PASS]${RESET} $name"
    else
        echo "  ${RED}[FAIL]${RESET} $name"
        while IFS= read -r line; do
            echo "        $line"
        done <<<"$output"
        SUBTEST_FAILURES=$((SUBTEST_FAILURES + 1))
    fi
}

subtest_exit() {
    [[ "$SUBTEST_FAILURES" -eq 0 ]]
}
