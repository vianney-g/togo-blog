#!/usr/bin/env bash
# =============================================================================
# Story 4.2 — Script de validation front-matter
# Tests for scripts/validate-frontmatter.sh
# =============================================================================
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

echo ""
echo "=== Story 4.2 — validate-frontmatter.sh Tests ==="
echo ""

SCRIPT="$ROOT/scripts/validate-frontmatter.sh"
SCHEMA="$ROOT/schemas/frontmatter.schema.json"
FIXTURES="$ROOT/tests/fixtures/frontmatter"

# Helper: setup temp content dir with specific fixture files
setup_content() {
    local tmpdir
    tmpdir=$(mktemp -d)
    mkdir -p "$tmpdir/content/posts"
    for f in "$@"; do
        cp "$f" "$tmpdir/content/posts/"
    done
    echo "$tmpdir"
}

# --- AC1: Valid article → exit 0 ---
echo "--- AC1: Valid article passes validation ---"
TMPD=$(setup_content "$FIXTURES/valid-article.md")
if bash "$SCRIPT" "$TMPD/content" "$SCHEMA" > /dev/null 2>&1; then
    echo -e "  ${GREEN}✅ PASS${NC}: Valid article accepted"
    PASS=$((PASS + 1))
else
    echo -e "  ${RED}❌ FAIL${NC}: Valid article rejected"
    FAIL=$((FAIL + 1))
fi
rm -rf "$TMPD"

# --- AC2: Missing required field (author) → exit 1 with error ---
echo "--- AC2: Missing author → validation fails ---"
TMPD=$(setup_content "$FIXTURES/invalid-missing-author.md")
OUTPUT=$(bash "$SCRIPT" "$TMPD/content" "$SCHEMA" 2>&1)
EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ]; then
    echo -e "  ${GREEN}✅ PASS${NC}: Invalid article rejected (exit $EXIT_CODE)"
    PASS=$((PASS + 1))
else
    echo -e "  ${RED}❌ FAIL${NC}: Invalid article accepted (should fail)"
    FAIL=$((FAIL + 1))
fi
# Check error message mentions the file
if echo "$OUTPUT" | grep -qi "erreur\|error\|❌"; then
    echo -e "  ${GREEN}✅ PASS${NC}: Error message present"
    PASS=$((PASS + 1))
else
    echo -e "  ${RED}❌ FAIL${NC}: No error message in output"
    FAIL=$((FAIL + 1))
fi
rm -rf "$TMPD"

# --- AC3: Invalid category (hors enum) → exit 1 ---
echo "--- AC3: Bad category → validation fails ---"
TMPD=$(setup_content "$FIXTURES/invalid-bad-category.md")
if bash "$SCRIPT" "$TMPD/content" "$SCHEMA" > /dev/null 2>&1; then
    echo -e "  ${RED}❌ FAIL${NC}: Bad category accepted (should fail)"
    FAIL=$((FAIL + 1))
else
    echo -e "  ${GREEN}✅ PASS${NC}: Bad category rejected"
    PASS=$((PASS + 1))
fi
rm -rf "$TMPD"

# --- AC4: Multiple files → reports ALL errors (no early stop) ---
echo "--- AC4: Multiple files, reports all errors ---"
TMPD=$(setup_content "$FIXTURES/valid-article.md" "$FIXTURES/invalid-missing-author.md" "$FIXTURES/invalid-bad-category.md")
OUTPUT=$(bash "$SCRIPT" "$TMPD/content" "$SCHEMA" 2>&1)
# Should have exit 1 (errors present)
EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ]; then
    echo -e "  ${GREEN}✅ PASS${NC}: Exit 1 with mixed files"
    PASS=$((PASS + 1))
else
    echo -e "  ${RED}❌ FAIL${NC}: Exit 0 with invalid files"
    FAIL=$((FAIL + 1))
fi
# Should report 2 errors (missing-author + bad-category)
ERROR_COUNT=$(echo "$OUTPUT" | grep -c "❌ ERREUR" || true)
if [ "$ERROR_COUNT" -ge 2 ]; then
    echo -e "  ${GREEN}✅ PASS${NC}: All errors reported ($ERROR_COUNT errors)"
    PASS=$((PASS + 1))
else
    echo -e "  ${RED}❌ FAIL${NC}: Not all errors reported (got $ERROR_COUNT, expected >=2)"
    FAIL=$((FAIL + 1))
fi
rm -rf "$TMPD"

# --- AC5: No front-matter → warning, exit 0 ---
echo "--- AC5: No front-matter → skip with warning, no error ---"
TMPD=$(setup_content "$FIXTURES/no-frontmatter.md")
OUTPUT=$(bash "$SCRIPT" "$TMPD/content" "$SCHEMA" 2>&1)
EXIT_CODE=$?
if [ $EXIT_CODE -eq 0 ]; then
    echo -e "  ${GREEN}✅ PASS${NC}: No front-matter → exit 0"
    PASS=$((PASS + 1))
else
    echo -e "  ${RED}❌ FAIL${NC}: No front-matter → exit $EXIT_CODE (expected 0)"
    FAIL=$((FAIL + 1))
fi
if echo "$OUTPUT" | grep -qi "skip\|warning\|⚠️\|ignoré"; then
    echo -e "  ${GREEN}✅ PASS${NC}: Warning message present"
    PASS=$((PASS + 1))
else
    echo -e "  ${RED}❌ FAIL${NC}: No warning message"
    FAIL=$((FAIL + 1))
fi
rm -rf "$TMPD"

# --- AC6: _index.md excluded ---
echo "--- AC6: _index.md excluded from validation ---"
TMPD=$(mktemp -d)
mkdir -p "$TMPD/content/posts"
cp "$FIXTURES/_index.md" "$TMPD/content/posts/"
# Only _index.md → should find no files to validate → exit 0
if bash "$SCRIPT" "$TMPD/content" "$SCHEMA" > /dev/null 2>&1; then
    echo -e "  ${GREEN}✅ PASS${NC}: _index.md excluded"
    PASS=$((PASS + 1))
else
    echo -e "  ${RED}❌ FAIL${NC}: _index.md not excluded"
    FAIL=$((FAIL + 1))
fi
rm -rf "$TMPD"

# --- AC7: Exit codes (covered by AC1+AC2, explicit check) ---
echo "--- AC7: Exit codes 0/1 ---"
TMPD=$(setup_content "$FIXTURES/valid-article.md")
bash "$SCRIPT" "$TMPD/content" "$SCHEMA" > /dev/null 2>&1
EC_VALID=$?
rm -rf "$TMPD"
TMPD=$(setup_content "$FIXTURES/invalid-missing-author.md")
bash "$SCRIPT" "$TMPD/content" "$SCHEMA" > /dev/null 2>&1
EC_INVALID=$?
rm -rf "$TMPD"
if [ $EC_VALID -eq 0 ] && [ $EC_INVALID -eq 1 ]; then
    echo -e "  ${GREEN}✅ PASS${NC}: Exit 0 (valid) and 1 (invalid)"
    PASS=$((PASS + 1))
else
    echo -e "  ${RED}❌ FAIL${NC}: Exit codes wrong (valid=$EC_VALID, invalid=$EC_INVALID)"
    FAIL=$((FAIL + 1))
fi

# --- AC8: check-jsonschema not installed → clear message ---
echo "--- AC8: Missing check-jsonschema → helpful message ---"
OUTPUT=$(PATH=/usr/bin:/bin bash "$SCRIPT" content "$SCHEMA" 2>&1)
EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ] && echo "$OUTPUT" | grep -qi "check-jsonschema\|install"; then
    echo -e "  ${GREEN}✅ PASS${NC}: Missing tool detected with install hint"
    PASS=$((PASS + 1))
else
    echo -e "  ${RED}❌ FAIL${NC}: Missing tool not detected or no install hint"
    FAIL=$((FAIL + 1))
fi

# --- Extra: Schema not found → error ---
echo "--- Extra: Schema not found → error ---"
if bash "$SCRIPT" content /tmp/nonexistent-schema.json > /dev/null 2>&1; then
    echo -e "  ${RED}❌ FAIL${NC}: Missing schema not detected"
    FAIL=$((FAIL + 1))
else
    echo -e "  ${GREEN}✅ PASS${NC}: Missing schema detected"
    PASS=$((PASS + 1))
fi

# --- Extra: Directory not found → error ---
echo "--- Extra: Directory not found → error ---"
if bash "$SCRIPT" /tmp/nonexistent-dir "$SCHEMA" > /dev/null 2>&1; then
    echo -e "  ${RED}❌ FAIL${NC}: Missing directory not detected"
    FAIL=$((FAIL + 1))
else
    echo -e "  ${GREEN}✅ PASS${NC}: Missing directory detected"
    PASS=$((PASS + 1))
fi

# --- Summary ---
TOTAL=$((PASS + FAIL))
echo ""
echo "==========================================="
echo "  Results: $PASS/$TOTAL pass, $FAIL fail"
echo "==========================================="

if [ $FAIL -gt 0 ]; then
    exit 1
fi
exit 0
