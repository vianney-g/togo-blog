#!/usr/bin/env bash
# =============================================================================
# Story 7.3 — Documentation SETUP-TIPHAINE.md
# Tests statiques (vérifie structure + contenu du guide)
# =============================================================================
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

ok()   { echo "  ✅ PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  ❌ FAIL: $1"; FAIL=$((FAIL + 1)); }

DOC="$ROOT/docs/SETUP-TIPHAINE.md"

echo "=== Story 7.3 — Documentation SETUP-TIPHAINE.md ==="
echo ""

# --- AC1: Guide couvre Git, clone, hook, raccourci ---
echo "--- AC1: Couverture installation complète ---"

if [ -f "$DOC" ]; then
    ok "AC1 — SETUP-TIPHAINE.md exists"
else
    fail "AC1 — SETUP-TIPHAINE.md not found"
fi

if grep -qi 'Git for Windows\|git-scm' "$DOC" 2>/dev/null; then
    ok "AC1 — mentions Git for Windows"
else
    fail "AC1 — missing Git for Windows"
fi

if grep -q 'git clone' "$DOC" 2>/dev/null; then
    ok "AC1 — mentions git clone"
else
    fail "AC1 — missing git clone"
fi

if grep -qi 'install-hooks\|hook' "$DOC" 2>/dev/null; then
    ok "AC1 — mentions hook configuration"
else
    fail "AC1 — missing hook configuration"
fi

if grep -qi 'raccourci\|Publier' "$DOC" 2>/dev/null; then
    ok "AC1 — mentions raccourci Publier"
else
    fail "AC1 — missing raccourci"
fi

# --- AC2: Captures d'écran (placeholders) ---
echo ""
echo "--- AC2: Captures d'écran placeholders ---"

if grep -qi 'capture\|screenshot\|illustration\|!\[' "$DOC" 2>/dev/null; then
    ok "AC2 — screenshot placeholders present"
else
    fail "AC2 — missing screenshot placeholders"
fi

PLACEHOLDER_COUNT=$(grep -ci 'capture\|screenshot\|illustration\|!\[' "$DOC" 2>/dev/null || echo 0)
if [ "$PLACEHOLDER_COUNT" -ge 3 ]; then
    ok "AC2 — at least 3 screenshot references ($PLACEHOLDER_COUNT found)"
else
    fail "AC2 — fewer than 3 screenshot references ($PLACEHOLDER_COUNT found)"
fi

# --- AC3: Termes techniques expliqués ---
echo ""
echo "--- AC3: Termes techniques expliqués ---"

if grep -qi 'Git.*outil\|Git.*logiciel\|Git.*programme\|Git.*permet\|Git.*sert' "$DOC" 2>/dev/null; then
    ok "AC3 — Git explained in simple terms"
else
    fail "AC3 — Git not explained"
fi

if grep -qi 'clone.*copie\|clone.*récupér\|clone.*télécharg\|cloner.*copie' "$DOC" 2>/dev/null; then
    ok "AC3 — clone explained in simple terms"
else
    fail "AC3 — clone not explained"
fi

# --- AC4: Test de publication à la fin ---
echo ""
echo "--- AC4: Test de publication ---"

if grep -qi 'test\|essai\|premier article\|vérif' "$DOC" 2>/dev/null; then
    ok "AC4 — test/verification step present"
else
    fail "AC4 — missing test step"
fi

if grep -qi 'double.*clic\|📝 Publier' "$DOC" 2>/dev/null; then
    ok "AC4 — mentions using the shortcut for test"
else
    fail "AC4 — missing shortcut usage in test"
fi

# --- AC5: Section Dépannage ---
echo ""
echo "--- AC5: Section Dépannage ---"

if grep -qi 'Dépannage\|dépannage\|Problème' "$DOC" 2>/dev/null; then
    ok "AC5 — Dépannage section present"
else
    fail "AC5 — missing Dépannage section"
fi

DEPANNAGE_COUNT=$(grep -ci '###.*\|→\|Solution' "$DOC" 2>/dev/null || echo 0)
if [ "$DEPANNAGE_COUNT" -ge 4 ]; then
    ok "AC5 — at least 4 troubleshooting items"
else
    fail "AC5 — fewer than 4 troubleshooting items ($DEPANNAGE_COUNT)"
fi

# --- DoD: Structure et qualité ---
echo ""
echo "--- DoD: Structure et qualité ---"

if grep -q '^## ' "$DOC" 2>/dev/null; then
    ok "DoD — has H2 sections"
else
    fail "DoD — missing H2 sections"
fi

SECTION_COUNT=$(grep -c '^## ' "$DOC" 2>/dev/null || echo 0)
if [ "$SECTION_COUNT" -ge 5 ]; then
    ok "DoD — at least 5 main sections ($SECTION_COUNT found)"
else
    fail "DoD — fewer than 5 sections ($SECTION_COUNT)"
fi

if grep -qi 'tape\|ouvre\|clique\|va sur\|cherche' "$DOC" 2>/dev/null; then
    ok "DoD — uses imperative/tutoring tone"
else
    fail "DoD — missing imperative tone"
fi

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
exit $FAIL
