assert_status() {
    local expected="$1" actual="$2"
    if [[ "$actual" != "$expected" ]]; then
        echo "expected status $expected, got $actual"
        exit 1
    fi
}

assert_body() {
    local expected="$1" actual="$2"
    if [[ "$actual" != "$expected" ]]; then
        echo "expected body '$expected', got '$actual'"
        exit 1
    fi
}
