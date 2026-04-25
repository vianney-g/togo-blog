#!/usr/bin/env bash
# =============================================================================
# Story 3.3 — Templates Typora pour Tiphaine
# =============================================================================
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

echo "=== Story 3.3 — Templates Typora Tests ==="
echo ""

FAMILLE="$ROOT/templates-typora/article-famille.md"
README="$ROOT/templates-typora/README.md"
SCHEMA="$ROOT/schemas/frontmatter.schema.json"

# --- AC1: article-famille.md exists with French placeholders ---
echo "--- AC1: article-famille.md exists with French placeholders ---"
if [ -f "$FAMILLE" ] && grep -q '\[Ton titre ici\]' "$FAMILLE"; then
    echo "✅ PASS: AC1 — article-famille.md with French placeholders"
    PASS=$((PASS + 1))
else
    echo "❌ FAIL: AC1 — article-famille.md missing or no French placeholders"
    FAIL=$((FAIL + 1))
fi

# --- AC3: Filled template validates against JSON Schema ---
echo "--- AC3: Filled template validates against JSON Schema ---"
result=$(python3 -c "
import sys, yaml, json
try:
    from jsonschema import validate, ValidationError
except ImportError:
    print('SKIP'); sys.exit(0)

with open('$FAMILLE') as f:
    content = f.read()
parts = content.split('---', 2)
fm = yaml.safe_load(parts[1])
# Replace placeholders with real values
fm['title'] = 'Mon premier article'
fm['date'] = '2026-08-15T10:00:00+01:00'
fm['author'] = 'madame'
fm['description'] = 'Un bel article'
fm['tags'] = ['sokode', 'cuisine']
with open('$SCHEMA') as f:
    schema = json.load(f)
try:
    validate(fm, schema)
    print('VALID')
except ValidationError as e:
    print(f'INVALID: {e.message}')
" 2>&1)
if [ "$result" = "VALID" ]; then
    echo "✅ PASS: AC3 — Filled template validates against schema"
    PASS=$((PASS + 1))
elif [ "$result" = "SKIP" ]; then
    echo "⏭️  SKIP: AC3 — jsonschema not installed"
else
    echo "❌ FAIL: AC3 — $result"
    FAIL=$((FAIL + 1))
fi

# --- AC4: Author field contains pseudonym reminder ---
echo "--- AC4: Author placeholder contains pseudonym reminder ---"
if grep -q 'nom de plume.*PAS ton vrai prénom\|PAS ton vrai prénom' "$FAMILLE" 2>/dev/null; then
    echo "✅ PASS: AC4 — Pseudonym reminder in author field"
    PASS=$((PASS + 1))
else
    echo "❌ FAIL: AC4 — Missing pseudonym reminder"
    FAIL=$((FAIL + 1))
fi

# --- AC5: Template has clean YAML (valid syntax) ---
echo "--- AC5: Front-matter is valid YAML ---"
if python3 -c "
import yaml, sys
with open('$FAMILLE') as fh:
    parts = fh.read().split('---', 2)
    yaml.safe_load(parts[1])
" 2>/dev/null; then
    echo "✅ PASS: AC5 — Valid YAML in template"
    PASS=$((PASS + 1))
else
    echo "❌ FAIL: AC5 — Invalid YAML"
    FAIL=$((FAIL + 1))
fi

# --- AC6: README exists with French instructions ---
echo "--- AC6: README with French instructions ---"
if [ -f "$README" ] && grep -q 'Comment les utiliser' "$README" && grep -q 'Nom de plume' "$README"; then
    echo "✅ PASS: AC6 — README with French instructions"
    PASS=$((PASS + 1))
else
    echo "❌ FAIL: AC6 — README missing or not in French"
    FAIL=$((FAIL + 1))
fi

# --- DoD: draft: true by default ---
echo "--- DoD: draft: true by default ---"
if grep -q '^draft: true' "$FAMILLE" 2>/dev/null; then
    echo "✅ PASS: DoD — draft: true"
    PASS=$((PASS + 1))
else
    echo "❌ FAIL: DoD — draft should be true"
    FAIL=$((FAIL + 1))
fi

# --- DoD: Suppression instructions in body ---
echo "--- DoD: Suppression instructions in body ---"
if grep -q 'Supprime ces instructions' "$FAMILLE" 2>/dev/null; then
    echo "✅ PASS: DoD — Suppression instructions present"
    PASS=$((PASS + 1))
else
    echo "❌ FAIL: DoD — Missing suppression instructions"
    FAIL=$((FAIL + 1))
fi

# --- DoD: famille has categories: quotidien ---
echo "--- DoD: famille template has quotidien category ---"
if grep -q 'quotidien' "$FAMILLE" 2>/dev/null; then
    echo "✅ PASS: DoD — quotidien category in famille"
    PASS=$((PASS + 1))
else
    echo "❌ FAIL: DoD — quotidien category missing"
    FAIL=$((FAIL + 1))
fi

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
[ $FAIL -eq 0 ] && exit 0 || exit 1
