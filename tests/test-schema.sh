#!/usr/bin/env bash
# tests/test-schema.sh — Validation du JSON Schema avec fixtures

SCHEMA="schemas/frontmatter.schema.json"
CHECK_CMD="${CHECK_JSONSCHEMA:-check-jsonschema}"
PASS=0
FAIL=0

echo "=== Test JSON Schema front-matter ==="
echo ""

# --- Tests positifs (doivent passer) ---
for f in tests/fixtures/valid-*.yaml; do
    if $CHECK_CMD --schemafile "$SCHEMA" "$f" > /dev/null 2>&1; then
        echo "  ✅ PASS: $f (validé)"
        PASS=$((PASS + 1))
    else
        echo "  ❌ FAIL: $f (devait être valide mais rejeté)"
        FAIL=$((FAIL + 1))
    fi
done

# --- Tests négatifs (doivent échouer) ---
for f in tests/fixtures/invalid-*.yaml; do
    if $CHECK_CMD --schemafile "$SCHEMA" "$f" > /dev/null 2>&1; then
        echo "  ❌ FAIL: $f (devait être invalide mais accepté)"
        FAIL=$((FAIL + 1))
    else
        echo "  ✅ PASS: $f (rejeté comme attendu)"
        PASS=$((PASS + 1))
    fi
done

echo ""
echo "=== Résultats : $PASS pass, $FAIL fail ==="

if [ $FAIL -gt 0 ]; then
    exit 1
fi
exit 0
