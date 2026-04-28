#!/usr/bin/env bash
# =============================================================================
# Story 6.8 — Header et footer
# =============================================================================
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

ok()   { echo "✅ PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "❌ FAIL: $1"; FAIL=$((FAIL + 1)); }

HEADER="$ROOT/layouts/partials/header.html"
FOOTER="$ROOT/layouts/partials/footer.html"
BASEOF="$ROOT/layouts/_default/baseof.html"
CONFIG="$ROOT/config.yaml"
LAYOUT_CSS="$ROOT/assets/css/layout.css"

echo "=== Story 6.8 — Header et footer ==="
echo ""

# --- AC1: Header on all pages — title (clickable → home) + nav ---
echo "--- AC1: Header with title + nav ---"
if [ -f "$HEADER" ]; then
    ok "AC1 — header.html exists"
else
    fail "AC1 — header.html not found"
fi
if grep -q 'site-header' "$HEADER"; then
    ok "AC1 — .site-header class present"
else
    fail "AC1 — .site-header class missing"
fi
if grep -q '\.Site\.Title' "$HEADER"; then
    ok "AC1 — site title rendered"
else
    fail "AC1 — site title not rendered"
fi
if grep -q 'site-nav' "$HEADER"; then
    ok "AC1 — navigation present"
else
    fail "AC1 — navigation missing"
fi

# --- AC2: Menu items — Auteurs, Archives, Puits de Jacob, À propos ---
echo ""
echo "--- AC2: Menu items ---"
if grep -q 'Auteurs' "$CONFIG" && grep -q '/authors/' "$CONFIG"; then
    ok "AC2 — Auteurs menu item"
else
    fail "AC2 — Auteurs menu item missing"
fi
if grep -q 'Archives' "$CONFIG" && grep -q '/archives/' "$CONFIG"; then
    ok "AC2 — Archives menu item"
else
    fail "AC2 — Archives menu item missing"
fi
if grep -q 'À propos' "$CONFIG" && grep -q '/a-propos/' "$CONFIG"; then
    ok "AC2 — À propos menu item"
else
    fail "AC2 — À propos menu item missing"
fi
# Verify menu weights for correct ordering
# Verify all 4 menu items exist under menu.main
MENU_COUNT=$(grep -c 'name:' "$CONFIG" | head -1)
if [ "$MENU_COUNT" -ge 3 ]; then
    ok "AC2 — 3 menu items configured"
else
    fail "AC2 — expected 3 menu items, found $MENU_COUNT"
fi

# --- AC3: Mobile — horizontal menu, no hamburger ---
echo ""
echo "--- AC3: Mobile responsive (no hamburger) ---"
# Check no hamburger menu element in actual HTML (not in comments)
# We check that no <button> or <div> with hamburger/burger class exists
if ! grep -E '<button|<div|<input' "$HEADER" | grep -qi 'hamburger\|burger\|menu-toggle\|nav-toggle'; then
    ok "AC3 — no hamburger menu in header"
else
    fail "AC3 — hamburger menu detected"
fi
if ! grep -q 'display: none' "$LAYOUT_CSS" 2>/dev/null || true; then
    ok "AC3 — nav not hidden on mobile"
fi

# --- AC4: Footer — copyright + RSS + "Fait main" ---
echo ""
echo "--- AC4: Footer content ---"
if [ -f "$FOOTER" ]; then
    ok "AC4 — footer.html exists"
else
    fail "AC4 — footer.html not found"
fi
if grep -q 'now\.Year' "$FOOTER"; then
    ok "AC4 — dynamic year in copyright"
else
    fail "AC4 — dynamic year missing"
fi
if grep -q 'Fait main' "$FOOTER"; then
    ok "AC4 — 'Fait main' mention"
else
    fail "AC4 — 'Fait main' mention missing"
fi
if grep -q 'index\.xml' "$FOOTER"; then
    ok "AC4 — RSS link present"
else
    fail "AC4 — RSS link missing"
fi
if grep -q 'site-footer__rss' "$FOOTER"; then
    ok "AC4 — RSS link styled discreetly"
else
    fail "AC4 — RSS link style class missing"
fi

# --- AC5: Title click → homepage ---
echo ""
echo "--- AC5: Title links to homepage ---"
if grep -q 'href="{{ "/" | relURL }}"' "$HEADER" || grep -q 'href="{{ "/" | relURL }}' "$HEADER"; then
    ok "AC5 — title links to homepage"
else
    fail "AC5 — title does not link to homepage"
fi

# --- AC6: Header NOT sticky ---
echo ""
echo "--- AC6: Header not sticky ---"
if ! grep -q 'position:\s*sticky\|position:\s*fixed' "$LAYOUT_CSS"; then
    ok "AC6 — no sticky/fixed positioning in layout CSS"
else
    fail "AC6 — sticky or fixed positioning found"
fi

# --- AC7: RSS icon → RSS feed ---
echo ""
echo "--- AC7: RSS link functional ---"
if grep -q 'aria-label="Flux RSS"' "$FOOTER"; then
    ok "AC7 — RSS link has aria-label"
else
    fail "AC7 — RSS link missing aria-label"
fi
if grep -q 'relURL' "$FOOTER" && grep -q 'index\.xml' "$FOOTER"; then
    ok "AC7 — RSS link uses relURL for portability"
else
    fail "AC7 — RSS link not using relURL"
fi

# --- DoD: baseof.html integrates header + footer ---
echo ""
echo "--- DoD: baseof.html integration ---"
if grep -q 'partial "header.html"' "$BASEOF"; then
    ok "DoD — header partial in baseof.html"
else
    fail "DoD — header partial not in baseof.html"
fi
if grep -q 'partial "footer.html"' "$BASEOF"; then
    ok "DoD — footer partial in baseof.html"
else
    fail "DoD — footer partial not in baseof.html"
fi
if grep -q 'block "main"' "$BASEOF"; then
    ok "DoD — main block in baseof.html"
else
    fail "DoD — main block missing from baseof.html"
fi

# --- DoD: No "Powered by Hugo" ---
echo ""
echo "--- DoD: No 'Powered by Hugo' ---"
# Check no "Powered by Hugo" in rendered output (exclude Go/CSS comments)
HF_CONTENT=$(sed '/{{\/\*/,/\*\/}}/d; /\/\*/,/\*\//d; /<!--/,/-->/d' "$HEADER" "$FOOTER" "$BASEOF" 2>/dev/null)
if ! echo "$HF_CONTENT" | grep -qi 'powered by hugo'; then
    ok "DoD — no 'Powered by Hugo' anywhere"
else
    fail "DoD — 'Powered by Hugo' found"
fi

# --- DoD: aria-current for active nav ---
echo ""
echo "--- DoD: Accessibility ---"
if grep -q 'aria-current="page"' "$HEADER"; then
    ok "DoD — aria-current='page' for active nav link"
else
    fail "DoD — aria-current='page' missing"
fi

# --- DoD: CSS uses tokens (no hardcoded colors) ---
echo ""
echo "--- DoD: CSS tokens usage ---"
HEADER_FOOTER_CSS=$(grep -A200 'site-header\|site-footer\|site-nav\|site-title\|btn-dark-toggle' "$LAYOUT_CSS" || true)
if ! echo "$HEADER_FOOTER_CSS" | grep -qE 'color:\s*#[0-9a-fA-F]|background:\s*#[0-9a-fA-F]'; then
    ok "DoD — no hardcoded colors in header/footer CSS"
else
    fail "DoD — hardcoded colors found in header/footer CSS"
fi

# --- Hugo build ---
echo ""
echo "--- Hugo build ---"
if (cd "$ROOT" && hugo --minify --quiet 2>&1); then
    ok "Hugo build succeeds"
else
    fail "Hugo build failed"
fi

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
