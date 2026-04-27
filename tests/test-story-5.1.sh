#!/usr/bin/env bash
# =============================================================================
# Story 5.1 — Tokens CSS et palette Asagi-Usuzumi
# =============================================================================
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

ok()   { echo "✅ PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "❌ FAIL: $1"; FAIL=$((FAIL + 1)); }

TOKENS="$ROOT/assets/css/tokens.css"

echo "=== Story 5.1 — Tokens CSS Tests ==="
echo ""

# --- AC1: tokens.css exists with all 10 raw palette colors ---
echo "--- AC1: Raw palette colors ---"
if [ ! -f "$TOKENS" ]; then
    fail "AC1 — tokens.css does not exist"
else
    AC1_OK=true
    for color in washi washi-ombre sumi sumi-doux usuzumi usuzumi-clair asagi-iro asagi-fonce kobaicha kobaicha-fonce; do
        if ! grep -q "\-\-color-${color}:" "$TOKENS"; then
            fail "AC1 — --color-${color} missing"
            AC1_OK=false
        fi
    done
    $AC1_OK && ok "AC1 — all 10 raw palette colors defined"
fi

# --- AC2: kobaicha-fonce is #8B4A3A and --color-link points to it ---
echo "--- AC2: Link color ---"
if [ -f "$TOKENS" ]; then
    if grep -q '\-\-color-kobaicha-fonce:.*#8B4A3A' "$TOKENS" &&
       grep -q '\-\-color-link:.*var(--color-kobaicha-fonce)' "$TOKENS"; then
        ok "AC2 — kobaicha-fonce=#8B4A3A and --color-link uses it"
    else
        fail "AC2 — link color mapping incorrect"
    fi
else
    fail "AC2 — tokens.css missing"
fi

# --- AC3: Spacing system (9 levels) ---
echo "--- AC3: Spacing system ---"
if [ -f "$TOKENS" ]; then
    AC3_OK=true
    for sp in 3xs 2xs xs s m l xl 2xl 3xl; do
        if ! grep -q "\-\-space-${sp}:" "$TOKENS"; then
            fail "AC3 — --space-${sp} missing"
            AC3_OK=false
        fi
    done
    $AC3_OK && ok "AC3 — all 9 spacing levels defined"
else
    fail "AC3 — tokens.css missing"
fi

# --- AC4: Breakpoints documented in comments ---
echo "--- AC4: Breakpoints ---"
if [ -f "$TOKENS" ]; then
    if grep -qi '640' "$TOKENS" && grep -qi '960' "$TOKENS" && grep -qi 'mobile' "$TOKENS"; then
        ok "AC4 — breakpoints documented (640, 960, mobile)"
    else
        fail "AC4 — breakpoint comments missing"
    fi
else
    fail "AC4 — tokens.css missing"
fi

# --- AC5: No hardcoded hex colors outside tokens.css ---
echo "--- AC5: No hardcoded colors outside tokens.css ---"
HARDCODED=$(grep -rn '#[0-9A-Fa-f]\{6\}' "$ROOT/assets/css/" --include='*.css' | grep -v 'tokens.css' || true)
if [ -z "$HARDCODED" ]; then
    ok "AC5 — no hardcoded hex colors outside tokens.css"
else
    fail "AC5 — hardcoded colors found: $HARDCODED"
fi

# --- AC6: Semantic mappings ---
echo "--- AC6: Semantic mappings ---"
if [ -f "$TOKENS" ]; then
    AC6_OK=true
    for sem in color-bg color-text color-link color-text-muted; do
        if ! grep -q "\-\-${sem}:" "$TOKENS"; then
            fail "AC6 — --${sem} missing"
            AC6_OK=false
        fi
    done
    $AC6_OK && ok "AC6 — semantic mappings defined"
else
    fail "AC6 — tokens.css missing"
fi

# --- DoD: --content-max-width defined ---
echo "--- DoD: content-max-width ---"
if [ -f "$TOKENS" ] && grep -q '\-\-content-max-width:.*42rem' "$TOKENS"; then
    ok "DoD — --content-max-width: 42rem defined"
else
    fail "DoD — --content-max-width missing"
fi

# --- DoD: Comments present ---
echo "--- DoD: Explanatory comments ---"
if [ -f "$TOKENS" ] && grep -q 'Palette' "$TOKENS" && grep -q 'Espacement' "$TOKENS"; then
    ok "DoD — explanatory comments present"
else
    fail "DoD — comments missing"
fi

# --- DoD: 11 semantic mappings ---
echo "--- DoD: 11 semantic mappings ---"
if [ -f "$TOKENS" ]; then
    SEM_COUNT=$(grep -c 'var(--color-' "$TOKENS" || true)
    if [ "$SEM_COUNT" -ge 11 ]; then
        ok "DoD — $SEM_COUNT semantic mappings (≥11)"
    else
        fail "DoD — only $SEM_COUNT semantic mappings (need ≥11)"
    fi
else
    fail "DoD — tokens.css missing"
fi

# --- DoD: Hugo build succeeds ---
echo "--- DoD: Hugo build ---"
BUILD_OUTPUT=$(cd "$ROOT" && hugo --minify --gc 2>&1)
BUILD_RC=$?
if [ $BUILD_RC -eq 0 ]; then
    ok "DoD — hugo --minify --gc builds without error"
else
    fail "DoD — hugo build failed: $BUILD_OUTPUT"
fi

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
[ $FAIL -eq 0 ] && exit 0 || exit 1
