#!/usr/bin/env bash
# =============================================================================
# Story 5.3 — Styles de base et layout responsive
# =============================================================================
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

ok()   { echo "✅ PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "❌ FAIL: $1"; FAIL=$((FAIL + 1)); }

BASE="$ROOT/assets/css/base.css"
LAYOUT="$ROOT/assets/css/layout.css"
COMPONENTS="$ROOT/assets/css/components.css"
HEAD_CSS="$ROOT/layouts/partials/head-css.html"

echo "=== Story 5.3 — Styles de base et layout responsive ==="
echo ""

# --- AC1: Mobile layout — column unique, mobile-first ---
echo "--- AC1: Mobile-first layout ---"
if [ -f "$LAYOUT" ]; then
    if grep -q 'flex-direction: column' "$LAYOUT" && grep -q 'width: 100%' "$LAYOUT"; then
        ok "AC1 — mobile-first column layout (flex-direction: column, width: 100%)"
    else
        fail "AC1 — missing mobile-first column layout"
    fi
else
    fail "AC1 — layout.css does not exist"
fi

# --- AC2: Desktop (≥960px) — centered content with generous margins ---
echo "--- AC2: Desktop breakpoint ---"
if [ -f "$LAYOUT" ]; then
    if grep -q 'min-width: 960px' "$LAYOUT" && grep -q 'max-width: var(--content-max-width)' "$LAYOUT"; then
        ok "AC2 — desktop breakpoint at 960px with max-width"
    else
        fail "AC2 — missing desktop breakpoint or max-width"
    fi
else
    fail "AC2 — layout.css does not exist"
fi

# --- AC3: HTML elements styled with palette/typo tokens ---
echo "--- AC3: Elements use CSS tokens ---"
if [ -f "$BASE" ]; then
    if grep -q 'var(--color-' "$BASE" && grep -q 'var(--space-' "$BASE"; then
        ok "AC3 — base.css uses color and spacing tokens"
    else
        fail "AC3 — base.css does not use CSS tokens"
    fi
else
    fail "AC3 — base.css does not exist"
fi

# --- AC4: Blockquotes — vertical asagi-iro border + italic ---
echo "--- AC4: Blockquotes ---"
if [ -f "$BASE" ]; then
    if grep -q 'border-left.*var(--color-accent-cold)' "$BASE" && grep -q 'font-style: italic' "$BASE"; then
        ok "AC4 — blockquotes have asagi-iro border-left and italic"
    else
        fail "AC4 — blockquote styling incorrect"
    fi
else
    fail "AC4 — base.css does not exist"
fi

# --- AC5: Links — kobaicha-fonce with subtle underline ---
echo "--- AC5: Link styling ---"
if [ -f "$BASE" ]; then
    if grep -q 'color: var(--color-link)' "$BASE" && grep -q 'text-decoration: underline' "$BASE"; then
        ok "AC5 — links use --color-link with underline"
    else
        fail "AC5 — link styling incorrect"
    fi
else
    fail "AC5 — base.css does not exist"
fi

# --- AC6: Header — clickable blog title + horizontal menu ---
echo "--- AC6: Header styles ---"
if [ -f "$LAYOUT" ]; then
    AC6_OK=true
    for sel in '.site-header' '.site-title' '.site-nav'; do
        if ! grep -q "$sel" "$LAYOUT"; then
            fail "AC6 — $sel missing from layout.css"
            AC6_OK=false
        fi
    done
    $AC6_OK && ok "AC6 — header styles (.site-header, .site-title, .site-nav)"
else
    fail "AC6 — layout.css does not exist"
fi

# --- AC7: Footer — minimal ---
echo "--- AC7: Footer styles ---"
if [ -f "$LAYOUT" ] && grep -q '.site-footer' "$LAYOUT"; then
    ok "AC7 — .site-footer styles present"
else
    fail "AC7 — .site-footer missing"
fi

# --- AC8: Background washi (#F5F2EB) via token ---
echo "--- AC8: Background washi ---"
if [ -f "$BASE" ] && grep -q 'background-color: var(--color-bg)' "$BASE"; then
    ok "AC8 — body uses var(--color-bg) for washi background"
else
    fail "AC8 — body background not using --color-bg"
fi

# --- AC9: CSS total < 20 Ko before minification ---
echo "--- AC9: CSS size < 20 Ko ---"
if [ -d "$ROOT/assets/css" ]; then
    TOTAL=$(cat "$ROOT/assets/css/"*.css | wc -c)
    if [ "$TOTAL" -lt 20480 ]; then
        ok "AC9 — CSS total = ${TOTAL} bytes (< 20480)"
    else
        fail "AC9 — CSS total = ${TOTAL} bytes (≥ 20480)"
    fi
else
    fail "AC9 — assets/css/ directory missing"
fi

# --- AC10: Hugo CSS pipeline — concat + minify ---
echo "--- AC10: CSS pipeline ---"
if [ -f "$HEAD_CSS" ]; then
    if grep -q 'resources.Concat' "$HEAD_CSS" && grep -q 'minify' "$HEAD_CSS"; then
        ok "AC10 — head-css.html uses resources.Concat and minify"
    else
        fail "AC10 — head-css.html missing Concat or minify"
    fi
else
    fail "AC10 — head-css.html does not exist"
fi

# --- DoD: base.css exists ---
echo "--- DoD: base.css ---"
[ -f "$BASE" ] && ok "DoD — base.css exists" || fail "DoD — base.css missing"

# --- DoD: layout.css exists ---
echo "--- DoD: layout.css ---"
[ -f "$LAYOUT" ] && ok "DoD — layout.css exists" || fail "DoD — layout.css missing"

# --- DoD: components.css exists ---
echo "--- DoD: components.css ---"
[ -f "$COMPONENTS" ] && ok "DoD — components.css exists" || fail "DoD — components.css missing"

# --- DoD: head-css.html exists ---
echo "--- DoD: head-css.html ---"
[ -f "$HEAD_CSS" ] && ok "DoD — head-css.html exists" || fail "DoD — head-css.html missing"

# --- DoD: No hardcoded hex colors outside tokens.css ---
echo "--- DoD: No hardcoded colors ---"
HARDCODED=$(grep -rn '#[0-9A-Fa-f]\{6\}' "$ROOT/assets/css/" --include='*.css' | grep -v 'tokens.css' || true)
if [ -z "$HARDCODED" ]; then
    ok "DoD — no hardcoded hex colors outside tokens.css"
else
    fail "DoD — hardcoded colors found: $HARDCODED"
fi

# --- DoD: hr rendered as astérisme ---
echo "--- DoD: hr astérisme ---"
if [ -f "$BASE" ] && grep -q '⁂' "$BASE"; then
    ok "DoD — hr uses astérisme (⁂)"
else
    fail "DoD — hr astérisme missing"
fi

# --- DoD: article-card component ---
echo "--- DoD: article-card ---"
if [ -f "$COMPONENTS" ] && grep -q '.article-card' "$COMPONENTS"; then
    ok "DoD — .article-card component exists"
else
    fail "DoD — .article-card missing"
fi

# --- DoD: tag-list component ---
echo "--- DoD: tag-list ---"
if [ -f "$COMPONENTS" ] && grep -q '.tag-list' "$COMPONENTS"; then
    ok "DoD — .tag-list component exists"
else
    fail "DoD — .tag-list missing"
fi

# --- DoD: Tablet breakpoint at 640px ---
echo "--- DoD: Tablet breakpoint ---"
if [ -f "$LAYOUT" ] && grep -q 'min-width: 640px' "$LAYOUT"; then
    ok "DoD — tablet breakpoint at 640px"
else
    fail "DoD — tablet breakpoint missing"
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
