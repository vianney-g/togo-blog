#!/usr/bin/env bash
# =============================================================================
# Story 3.2 — Archetypes Hugo (templates de posts)
# Tests hugo new with default archetype
# =============================================================================
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

echo "=== Story 3.2 — Archetypes Tests ==="
echo ""

cleanup() {
    rm -f "$ROOT/content/posts/2026-test-archetype.md"
    rmdir "$ROOT/content/posts" 2>/dev/null || true
}
trap cleanup EXIT
cleanup

# --- AC1: hugo new generates file with complete front-matter ---
echo "--- AC1: default archetype generates complete front-matter ---"
hugo new content/posts/2026-test-archetype.md -s "$ROOT" >/dev/null 2>&1
FILE="$ROOT/content/posts/2026-test-archetype.md"
if [ -f "$FILE" ]; then
    fm=$(sed -n '/^---$/,/^---$/p' "$FILE")
    ok=true
    for field in title date author draft tags; do
        if ! echo "$fm" | grep -q "^${field}:"; then
            echo "  Missing field: $field"
            ok=false
        fi
    done
    if $ok; then
        echo "✅ PASS: AC1 — All required front-matter fields present"
        PASS=$((PASS + 1))
    else
        echo "❌ FAIL: AC1 — Missing front-matter fields"
        FAIL=$((FAIL + 1))
    fi
else
    echo "❌ FAIL: AC1 — File not created"
    FAIL=$((FAIL + 1))
fi

# --- AC2: draft is true ---
echo "--- AC2: draft: true by default ---"
if grep -q '^draft: true' "$FILE" 2>/dev/null; then
    echo "✅ PASS: AC2 — draft: true"
    PASS=$((PASS + 1))
else
    echo "❌ FAIL: AC2 — draft should be true"
    FAIL=$((FAIL + 1))
fi

# --- AC3: author is empty string ---
echo "--- AC3: author is empty string ---"
if grep -q '^author: ""' "$FILE" 2>/dev/null; then
    echo "✅ PASS: AC3 — author: \"\" (empty)"
    PASS=$((PASS + 1))
else
    echo "❌ FAIL: AC3 — author should be empty string"
    FAIL=$((FAIL + 1))
fi

# --- AC4: French guide comments in body ---
echo "--- AC4: French guide comments in body ---"
body=$(awk 'BEGIN{c=0} /^---$/{c++;next} c>=2' "$FILE")
if echo "$body" | grep -q "pseudonyme\|Remplace author\|nom de plume"; then
    echo "✅ PASS: AC4 — French guide comments present"
    PASS=$((PASS + 1))
else
    echo "❌ FAIL: AC4 — Missing French guide comments"
    FAIL=$((FAIL + 1))
fi

cleanup

# --- AC-schema: Generated YAML is valid (once placeholders filled) ---
echo "--- AC-schema: Generated front-matter is valid YAML ---"
# Re-generate default for YAML check
cleanup
hugo new content/posts/2026-test-archetype.md -s "$ROOT" >/dev/null 2>&1
FILE="$ROOT/content/posts/2026-test-archetype.md"
# Extract front-matter, fill author placeholder, validate with python
fm_yaml=$(sed -n '2,/^---$/{ /^---$/d; p }' "$FILE")
if echo "$fm_yaml" | python3 -c "import sys, yaml; yaml.safe_load(sys.stdin)" 2>/dev/null; then
    echo "✅ PASS: AC-schema — Valid YAML"
    PASS=$((PASS + 1))
else
    echo "❌ FAIL: AC-schema — Invalid YAML"
    FAIL=$((FAIL + 1))
fi

# --- AC-schema2: Front-matter validates against JSON Schema (with author filled) ---
echo "--- AC-schema2: Front-matter validates against JSON Schema ---"
SCHEMA="$ROOT/schemas/frontmatter.schema.json"
if command -v python3 >/dev/null 2>&1; then
    result=$(python3 -c "
import sys, yaml, json
try:
    from jsonschema import validate, ValidationError
except ImportError:
    print('SKIP')
    sys.exit(0)

with open('$FILE') as f:
    content = f.read()
# Extract front-matter
parts = content.split('---')
fm = yaml.safe_load(parts[1])
# Fill placeholder: author must be non-empty for schema
fm['author'] = 'plume'
# Hugo generates datetime object; schema expects ISO string
if hasattr(fm.get('date', ''), 'isoformat'):
    fm['date'] = fm['date'].isoformat()
with open('$SCHEMA') as f:
    schema = json.load(f)
try:
    validate(fm, schema)
    print('VALID')
except ValidationError as e:
    print(f'INVALID: {e.message}')
" 2>&1)
    if [ "$result" = "VALID" ]; then
        echo "✅ PASS: AC-schema2 — Validates against JSON Schema"
        PASS=$((PASS + 1))
    elif [ "$result" = "SKIP" ]; then
        echo "⏭️  SKIP: AC-schema2 — jsonschema not installed"
    else
        echo "❌ FAIL: AC-schema2 — $result"
        FAIL=$((FAIL + 1))
    fi
else
    echo "⏭️  SKIP: AC-schema2 — python3 not available"
fi

# --- Archetype files exist ---
echo "--- Extra: Archetype files exist ---"
if [ -f "$ROOT/archetypes/default.md" ]; then
    echo "✅ PASS: Default archetype file exists"
    PASS=$((PASS + 1))
else
    echo "❌ FAIL: Missing archetype files"
    FAIL=$((FAIL + 1))
fi

# --- .gitkeep removed ---
echo "--- Extra: .gitkeep removed ---"
if [ ! -f "$ROOT/archetypes/.gitkeep" ]; then
    echo "✅ PASS: .gitkeep removed"
    PASS=$((PASS + 1))
else
    echo "❌ FAIL: .gitkeep should be removed"
    FAIL=$((FAIL + 1))
fi

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
[ $FAIL -eq 0 ] && exit 0 || exit 1
