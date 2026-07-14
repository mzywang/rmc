#!/usr/bin/env bash
set -euo pipefail

base_sha="$1"
head_sha="$2"

merge_base="$(git merge-base "$base_sha" "$head_sha")"

stage_for_file() {
    case "$1" in
        docs/*|README.md) echo 0 ;;
        tests/*) echo 1 ;;
        *) echo 2 ;;
    esac
}

stage_name() {
    case "$1" in
        0) echo "documentation" ;;
        1) echo "tests" ;;
        2) echo "implementation" ;;
    esac
}

max_stage=-1
violation=0

while IFS= read -r commit; do
    [[ -z "$commit" ]] && continue

    commit_stage=-1
    while IFS= read -r file; do
        [[ -z "$file" ]] && continue
        stage="$(stage_for_file "$file")"
        if (( stage > commit_stage )); then
            commit_stage=$stage
        fi
    done < <(git diff-tree --no-commit-id --name-only -r "$commit")

    if (( commit_stage == -1 )); then
        continue
    fi

    subject="$(git log -1 --format=%s "$commit")"

    if (( commit_stage < max_stage )); then
        echo "Commit $commit (\"$subject\") touches $(stage_name "$commit_stage"), but a later stage ($(stage_name "$max_stage")) was already committed earlier in this PR."
        violation=1
    fi

    if (( commit_stage > max_stage )); then
        max_stage=$commit_stage
    fi
done < <(git rev-list --reverse "${merge_base}..${head_sha}")

if (( violation == 1 )); then
    echo
    echo "Expected commit order: documentation, then tests, then implementation."
    echo "To bypass this check for a PR that doesn't fit that pattern, apply the 'skip-commit-order' label."
    exit 1
fi
