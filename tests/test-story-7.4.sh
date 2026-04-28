#!/usr/bin/env bash
# =============================================================================
# Story 7.4 — Documentation SETUP-VIANNEY.md
# Tests statiques
# =============================================================================
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

ok()   { echo "  ✅ PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  ❌ FAIL: $1"; FAIL=$((FAIL + 1)); }

DOC="$ROOT/docs/SETUP-VIANNEY.md"

echo "=== Story 7.4 — Documentation SETUP-VIANNEY.md ==="
echo ""

# --- AC1: Hugo, repos, hooks, hugo server ---
echo "--- AC1: Couverture setup complet ---"

if [ -f "$DOC" ]; then
    ok "AC1 — SETUP-VIANNEY.md exists"
else
    fail "AC1 — SETUP-VIANNEY.md not found"
fi

if grep -qi 'hugo' "$DOC" 2>/dev/null; then
    ok "AC1 — mentions Hugo"
else
    fail "AC1 — missing Hugo"
fi

if grep -q 'togo-blog-content' "$DOC" 2>/dev/null; then
    ok "AC1 — mentions repo content"
else
    fail "AC1 — missing repo content"
fi

if grep -q 'togo-blog' "$DOC" 2>/dev/null; then
    ok "AC1 — mentions repo code"
else
    fail "AC1 — missing repo code"
fi

if grep -q 'core.hooksPath' "$DOC" 2>/dev/null; then
    ok "AC1 — mentions hooks config"
else
    fail "AC1 — missing hooks config"
fi

if grep -q 'hugo server' "$DOC" 2>/dev/null; then
    ok "AC1 — mentions hugo server"
else
    fail "AC1 — missing hugo server"
fi

# --- AC2: Alias et config git ---
echo ""
echo "--- AC2: Alias et config git ---"

if grep -q 'alias' "$DOC" 2>/dev/null; then
    ok "AC2 — alias section present"
else
    fail "AC2 — missing alias"
fi

if grep -q 'git config\|git clone' "$DOC" 2>/dev/null; then
    ok "AC2 — git config/clone present"
else
    fail "AC2 — missing git config"
fi

# --- AC3: Concis (1-2 pages) ---
echo ""
echo "--- AC3: Concis ---"

if [ -f "$DOC" ]; then
    LINE_COUNT=$(wc -l < "$DOC")
    if [ "$LINE_COUNT" -le 120 ]; then
        ok "AC3 — concise ($LINE_COUNT lines, ≤120)"
    else
        fail "AC3 — too long ($LINE_COUNT lines, expected ≤120)"
    fi
else
    fail "AC3 — file not found"
fi

# --- DoD ---
echo ""
echo "--- DoD ---"

if grep -qi 'dépannage\|troubleshoot\|problème' "$DOC" 2>/dev/null; then
    ok "DoD — troubleshooting section"
else
    fail "DoD — missing troubleshooting"
fi

if grep -q 'submodule' "$DOC" 2>/dev/null; then
    ok "DoD — mentions submodule"
else
    fail "DoD — missing submodule"
fi

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
exit $FAIL
