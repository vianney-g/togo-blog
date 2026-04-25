#!/usr/bin/env bash
# =============================================================================
# Story 2.3 — CI scan script tests
# =============================================================================
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$REPO_ROOT/scripts/scan-names-ci.sh"
PASS=0
FAIL=0
TMPBASE=$(mktemp -d)
trap 'rm -rf "$TMPBASE"' EXIT

echo "=== Story 2.3 — CI Scan Script Tests ==="
echo ""

# --- AC1: .md with "Jeanne" → exit 1, message with file + line ---
echo "--- AC1: Jeanne in .md → exit 1 with file+line ---"
dir="$TMPBASE/ac1"
mkdir -p "$dir"
echo "Bonjour Jeanne" > "$dir/article.md"
output=$(bash "$SCRIPT" "$dir" 2>&1)
rc=$?
if [ $rc -eq 1 ] && echo "$output" | grep -q "article.md" && echo "$output" | grep -q "Jeanne"; then
    echo "✅ PASS: AC1"; PASS=$((PASS + 1))
else
    echo "❌ FAIL: AC1 — rc=$rc"; echo "  $output"; FAIL=$((FAIL + 1))
fi

# --- AC2: Valid content (pseudonyms) → exit 0 ---
echo "--- AC2: Pseudonyms only → exit 0 ---"
dir="$TMPBASE/ac2"
mkdir -p "$dir"
echo "Article de Plume et Colibri" > "$dir/article.md"
output=$(bash "$SCRIPT" "$dir" 2>&1)
rc=$?
if [ $rc -eq 0 ]; then
    echo "✅ PASS: AC2"; PASS=$((PASS + 1))
else
    echo "❌ FAIL: AC2 — rc=$rc"; FAIL=$((FAIL + 1))
fi

# --- AC3: Scans ALL text files (not just staged) ---
echo "--- AC3: Scans all files in directory ---"
dir="$TMPBASE/ac3"
mkdir -p "$dir/sub"
echo "Safe content" > "$dir/page.md"
echo "Hidden Vianney" > "$dir/sub/deep.md"
output=$(bash "$SCRIPT" "$dir" 2>&1)
rc=$?
if [ $rc -eq 1 ] && echo "$output" | grep -q "deep.md"; then
    echo "✅ PASS: AC3"; PASS=$((PASS + 1))
else
    echo "❌ FAIL: AC3 — rc=$rc"; FAIL=$((FAIL + 1))
fi

# --- AC4: Lowercase name in .yaml → detected ---
echo "--- AC4: tiphaine in .yaml → detected ---"
dir="$TMPBASE/ac4"
mkdir -p "$dir"
echo "author: tiphaine" > "$dir/config.yaml"
output=$(bash "$SCRIPT" "$dir" 2>&1)
rc=$?
if [ $rc -eq 1 ] && echo "$output" | grep -q "config.yaml"; then
    echo "✅ PASS: AC4"; PASS=$((PASS + 1))
else
    echo "❌ FAIL: AC4 — rc=$rc"; FAIL=$((FAIL + 1))
fi

# --- AC5: Substring "Jeanneton" → ignored (word-boundary) ---
echo "--- AC5: Jeanneton → accepted ---"
dir="$TMPBASE/ac5"
mkdir -p "$dir"
echo "Le marché de Jeanneton" > "$dir/article.md"
output=$(bash "$SCRIPT" "$dir" 2>&1)
rc=$?
if [ $rc -eq 0 ]; then
    echo "✅ PASS: AC5"; PASS=$((PASS + 1))
else
    echo "❌ FAIL: AC5 — Jeanneton should be accepted, rc=$rc"; FAIL=$((FAIL + 1))
fi

# --- AC6: Exit codes are 0 or 1 ---
echo "--- AC6: Exit code 0 (clean) ---"
dir="$TMPBASE/ac6"
mkdir -p "$dir"
echo "Clean" > "$dir/ok.md"
bash "$SCRIPT" "$dir" >/dev/null 2>&1
rc=$?
if [ $rc -eq 0 ]; then
    echo "✅ PASS: AC6a — exit 0"; PASS=$((PASS + 1))
else
    echo "❌ FAIL: AC6a — rc=$rc"; FAIL=$((FAIL + 1))
fi

echo "--- AC6: Exit code 1 (name found) ---"
echo "Marthe est là" > "$dir/bad.md"
bash "$SCRIPT" "$dir" >/dev/null 2>&1
rc=$?
if [ $rc -eq 1 ]; then
    echo "✅ PASS: AC6b — exit 1"; PASS=$((PASS + 1))
else
    echo "❌ FAIL: AC6b — rc=$rc"; FAIL=$((FAIL + 1))
fi

# --- Extra: Script is executable ---
echo "--- Extra: Script is executable ---"
if [ -x "$SCRIPT" ]; then
    echo "✅ PASS: executable"; PASS=$((PASS + 1))
else
    echo "❌ FAIL: not executable"; FAIL=$((FAIL + 1))
fi

# --- Extra: Bash syntax valid ---
echo "--- Extra: Bash syntax ---"
if bash -n "$SCRIPT" 2>/dev/null; then
    echo "✅ PASS: syntax valid"; PASS=$((PASS + 1))
else
    echo "❌ FAIL: syntax error"; FAIL=$((FAIL + 1))
fi

# --- Extra: Default directory (no arg) ---
echo "--- Extra: Default directory ---"
cd "$TMPBASE/ac2"
output=$(bash "$SCRIPT" 2>&1)
rc=$?
if [ $rc -eq 0 ]; then
    echo "✅ PASS: default dir"; PASS=$((PASS + 1))
else
    echo "❌ FAIL: default dir — rc=$rc"; FAIL=$((FAIL + 1))
fi

# --- Extra: .git/ excluded ---
echo "--- Extra: .git/ excluded ---"
dir="$TMPBASE/gitexcl"
mkdir -p "$dir/.git"
echo "Vianney" > "$dir/.git/config.txt"
echo "Safe" > "$dir/ok.md"
output=$(bash "$SCRIPT" "$dir" 2>&1)
rc=$?
if [ $rc -eq 0 ]; then
    echo "✅ PASS: .git excluded"; PASS=$((PASS + 1))
else
    echo "❌ FAIL: .git should be excluded"; FAIL=$((FAIL + 1))
fi

# --- Extra: All 6 names detected ---
echo "--- Extra: All 6 names ---"
for name in Vianney Tiphaine Jeanne Joséphine Mayeul Marthe; do
    dir="$TMPBASE/name-$name"
    mkdir -p "$dir"
    echo "Test $name ici" > "$dir/test.md"
    bash "$SCRIPT" "$dir" >/dev/null 2>&1
    rc=$?
    if [ $rc -eq 1 ]; then
        echo "✅ PASS: $name detected"; PASS=$((PASS + 1))
    else
        echo "❌ FAIL: $name should be detected"; FAIL=$((FAIL + 1))
    fi
done

# --- Extra: Scans .yml, .toml, .txt, .json ---
echo "--- Extra: All file extensions ---"
for ext in yml toml txt json; do
    dir="$TMPBASE/ext-$ext"
    mkdir -p "$dir"
    echo "Mayeul" > "$dir/file.$ext"
    bash "$SCRIPT" "$dir" >/dev/null 2>&1
    rc=$?
    if [ $rc -eq 1 ]; then
        echo "✅ PASS: .$ext scanned"; PASS=$((PASS + 1))
    else
        echo "❌ FAIL: .$ext should be scanned"; FAIL=$((FAIL + 1))
    fi
done

# --- Extra: .jpg not scanned ---
echo "--- Extra: .jpg ignored ---"
dir="$TMPBASE/jpg"
mkdir -p "$dir"
echo "Vianney" > "$dir/photo.jpg"
output=$(bash "$SCRIPT" "$dir" 2>&1)
rc=$?
if [ $rc -eq 0 ]; then
    echo "✅ PASS: .jpg ignored"; PASS=$((PASS + 1))
else
    echo "❌ FAIL: .jpg should be ignored"; FAIL=$((FAIL + 1))
fi

# --- Extra: No files → exit 0 ---
echo "--- Extra: Empty dir → exit 0 ---"
dir="$TMPBASE/empty"
mkdir -p "$dir"
output=$(bash "$SCRIPT" "$dir" 2>&1)
rc=$?
if [ $rc -eq 0 ]; then
    echo "✅ PASS: empty dir"; PASS=$((PASS + 1))
else
    echo "❌ FAIL: empty dir — rc=$rc"; FAIL=$((FAIL + 1))
fi

# --- Extra: Same regex as pre-commit hook ---
echo "--- Extra: Regex matches pre-commit hook ---"
HOOK="$REPO_ROOT/.githooks/pre-commit"
hook_regex=$(grep -oP "FORBIDDEN='[^']+'" "$HOOK" | head -1)
script_regex=$(grep -oP "FORBIDDEN='[^']+'" "$SCRIPT" | head -1)
if [ "$hook_regex" = "$script_regex" ]; then
    echo "✅ PASS: same regex"; PASS=$((PASS + 1))
else
    echo "❌ FAIL: regex differs"; echo "  hook: $hook_regex"; echo "  script: $script_regex"; FAIL=$((FAIL + 1))
fi

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
[ $FAIL -eq 0 ] && exit 0 || exit 1
