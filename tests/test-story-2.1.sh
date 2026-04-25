#!/usr/bin/env bash
# =============================================================================
# Story 2.1 — Pre-commit hook tests
# Tests the hook script via real git repos for all 9 AC
# =============================================================================
set -uo pipefail

HOOK="$(cd "$(dirname "$0")/.." && pwd)/.githooks/pre-commit"
PASS=0
FAIL=0
TMPBASE=$(mktemp -d)
trap 'rm -rf "$TMPBASE"' EXIT
COUNTER=0

echo "=== Story 2.1 — Pre-commit Hook Tests ==="
echo ""

setup_repo() {
    COUNTER=$((COUNTER + 1))
    local repo="$TMPBASE/repo-$COUNTER"
    mkdir -p "$repo/.githooks"
    cp "$HOOK" "$repo/.githooks/pre-commit"
    chmod +x "$repo/.githooks/pre-commit"
    cd "$repo"
    git init -q
    git config user.email "test@test.com"
    git config user.name "Test"
    git config core.hooksPath .githooks
    touch .gitkeep
    git add .gitkeep
    git commit -q -m "init"
}

# --- AC1: .md with "Jeanne" → refused with file:line ---
echo "--- AC1: Jeanne in .md → refused ---"
setup_repo
echo "Bonjour Jeanne" > test.md
git add test.md
output=$(git commit -m "test" 2>&1 || true)
if echo "$output" | grep -q "test.md" && echo "$output" | grep -q "Jeanne"; then
    echo "✅ PASS: AC1 — Jeanne detected with file reference"
    PASS=$((PASS + 1))
else
    echo "❌ FAIL: AC1 — Expected file:line message for Jeanne"
    echo "  Output: $output"
    FAIL=$((FAIL + 1))
fi

# --- AC2: "tiphaine" lowercase → refused ---
echo "--- AC2: tiphaine lowercase → refused ---"
setup_repo
echo "bonjour tiphaine" > test.md
git add test.md
if git commit -m "test" 2>&1 >/dev/null; then
    echo "❌ FAIL: AC2 — tiphaine lowercase should be refused"
    FAIL=$((FAIL + 1))
else
    echo "✅ PASS: AC2 — tiphaine lowercase refused"
    PASS=$((PASS + 1))
fi

# --- AC3: "Joséphine" with accent → refused ---
echo "--- AC3: Joséphine with accent → refused ---"
setup_repo
echo "Message de Joséphine" > test.md
git add test.md
if git commit -m "test" 2>&1 >/dev/null; then
    echo "❌ FAIL: AC3 — Joséphine should be refused"
    FAIL=$((FAIL + 1))
else
    echo "✅ PASS: AC3 — Joséphine refused"
    PASS=$((PASS + 1))
fi

# --- AC4: "Josephine" without accent → refused ---
echo "--- AC4: Josephine without accent → refused ---"
setup_repo
echo "Message de Josephine" > test.md
git add test.md
if git commit -m "test" 2>&1 >/dev/null; then
    echo "❌ FAIL: AC4 — Josephine should be refused"
    FAIL=$((FAIL + 1))
else
    echo "✅ PASS: AC4 — Josephine refused"
    PASS=$((PASS + 1))
fi

# --- AC5: "Jeanneton" → accepted (word-boundary) ---
echo "--- AC5: Jeanneton → accepted ---"
setup_repo
echo "Le marché de Jeanneton" > test.md
git add test.md
if git commit -m "test" 2>&1 >/dev/null; then
    echo "✅ PASS: AC5 — Jeanneton accepted (word-boundary)"
    PASS=$((PASS + 1))
else
    echo "❌ FAIL: AC5 — Jeanneton should be accepted"
    FAIL=$((FAIL + 1))
fi

# --- AC6: "author: plume" → accepted ---
echo "--- AC6: author: plume → accepted ---"
setup_repo
cat > test.md << 'EOF'
---
title: "Mon article"
author: plume
---
Contenu valide sans prénom.
EOF
git add test.md
if git commit -m "test" 2>&1 >/dev/null; then
    echo "✅ PASS: AC6 — pseudonym accepted"
    PASS=$((PASS + 1))
else
    echo "❌ FAIL: AC6 — pseudonym should be accepted"
    FAIL=$((FAIL + 1))
fi

# --- AC7: .jpg file → ignored ---
echo "--- AC7: .jpg file → ignored ---"
setup_repo
echo "fake jpg with Jeanne" > photo.jpg
git add photo.jpg
if git commit -m "test" 2>&1 >/dev/null; then
    echo "✅ PASS: AC7 — .jpg ignored"
    PASS=$((PASS + 1))
else
    echo "❌ FAIL: AC7 — .jpg should be ignored"
    FAIL=$((FAIL + 1))
fi

# --- AC8: No staged files → exit 0 ---
echo "--- AC8: No staged files → pass ---"
setup_repo
# Run hook directly (no staged files after init commit)
output=$(./.githooks/pre-commit 2>&1)
exit_code=$?
if [ $exit_code -eq 0 ]; then
    echo "✅ PASS: AC8 — No staged files, exit 0"
    PASS=$((PASS + 1))
else
    echo "❌ FAIL: AC8 — Should exit 0 with no staged files"
    FAIL=$((FAIL + 1))
fi

# --- AC9: Error message contains "pseudonyme" ---
echo "--- AC9: Error message is clear and non-punitive ---"
setup_repo
echo "Bonjour Jeanne" > test.md
git add test.md
output=$(git commit -m "test" 2>&1 || true)
if echo "$output" | grep -qi "pseudonyme"; then
    echo "✅ PASS: AC9 — Message contains 'pseudonyme'"
    PASS=$((PASS + 1))
else
    echo "❌ FAIL: AC9 — Message should contain 'pseudonyme'"
    echo "  Output: $output"
    FAIL=$((FAIL + 1))
fi

# --- Extra: All 6 names detected ---
echo "--- Extra: All 6 forbidden names ---"
for name in Vianney Tiphaine Jeanne Joséphine Mayeul Marthe; do
    setup_repo
    echo "Test $name ici" > test.md
    git add test.md
    if git commit -m "test" 2>&1 >/dev/null; then
        echo "❌ FAIL: $name should be refused"
        FAIL=$((FAIL + 1))
    else
        echo "✅ PASS: $name refused"
        PASS=$((PASS + 1))
    fi
done

# --- Extra: Hook is executable ---
echo "--- Extra: Hook is executable ---"
if [ -x "$HOOK" ]; then
    echo "✅ PASS: Hook is executable"
    PASS=$((PASS + 1))
else
    echo "❌ FAIL: Hook should be executable"
    FAIL=$((FAIL + 1))
fi

# --- Extra: Bash syntax valid ---
echo "--- Extra: Bash syntax valid ---"
if bash -n "$HOOK" 2>/dev/null; then
    echo "✅ PASS: Bash syntax valid"
    PASS=$((PASS + 1))
else
    echo "❌ FAIL: Bash syntax error"
    FAIL=$((FAIL + 1))
fi

# --- Extra: Content repo copy exists and is executable ---
echo "--- Extra: Content repo copy ---"
CONTENT_HOOK="/home/vianney/perso/togo-blog-content/.githooks/pre-commit"
if [ -x "$CONTENT_HOOK" ]; then
    echo "✅ PASS: Content repo hook exists and is executable"
    PASS=$((PASS + 1))
else
    echo "❌ FAIL: Content repo hook missing or not executable"
    FAIL=$((FAIL + 1))
fi

# --- Extra: Both hooks are identical ---
echo "--- Extra: Both hooks identical ---"
if diff -q "$HOOK" "$CONTENT_HOOK" >/dev/null 2>&1; then
    echo "✅ PASS: Both hooks are identical"
    PASS=$((PASS + 1))
else
    echo "❌ FAIL: Hooks differ"
    FAIL=$((FAIL + 1))
fi

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
[ $FAIL -eq 0 ] && exit 0 || exit 1
