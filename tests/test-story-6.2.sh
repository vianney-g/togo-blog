#!/usr/bin/env bash
# =============================================================================
# Story 6.2 — Page article complète
# =============================================================================
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

ok()   { echo "✅ PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "❌ FAIL: $1"; FAIL=$((FAIL + 1)); }

SINGLE="$ROOT/layouts/_default/single.html"
NAV="$ROOT/layouts/partials/article-nav.html"
CSS="$ROOT/assets/css/components.css"

echo "=== Story 6.2 — Page article complète ==="
echo ""

# --- AC1: Title, author, date, body ---
echo "--- AC1: Title, author, date, body ---"
if [ -f "$SINGLE" ]; then
    ok "AC1 — single.html exists"
else
    fail "AC1 — single.html not found"
fi
if grep -q 'article__title' "$SINGLE"; then
    ok "AC1 — title element present"
else
    fail "AC1 — title element missing"
fi
if grep -q 'article__author' "$SINGLE"; then
    ok "AC1 — author element present"
else
    fail "AC1 — author element missing"
fi
if grep -q 'article__date' "$SINGLE"; then
    ok "AC1 — date element present"
else
    fail "AC1 — date element missing"
fi
if grep -q '\.Content' "$SINGLE"; then
    ok "AC1 — content rendered"
else
    fail "AC1 — content not rendered"
fi

# --- AC2: Reading column width 65-70 chars ---
echo ""
echo "--- AC2: Reading column width ---"
if grep -q 'content-max-width' "$CSS"; then
    ok "AC2 — uses --content-max-width for column width"
else
    fail "AC2 — --content-max-width not used"
fi

# --- AC3: Signature + fleuron + nav ---
echo ""
echo "--- AC3: Signature, fleuron, nav ---"
if grep -q 'article__signature' "$SINGLE"; then
    ok "AC3 — signature present"
else
    fail "AC3 — signature missing"
fi
if grep -q 'small-caps' "$CSS"; then
    ok "AC3 — signature uses small-caps"
else
    fail "AC3 — small-caps missing"
fi
if grep -q '❦' "$SINGLE"; then
    ok "AC3 — fleuron (❦) present"
else
    fail "AC3 — fleuron missing"
fi
if grep -q 'article-nav' "$SINGLE"; then
    ok "AC3 — nav partial included"
else
    fail "AC3 — nav partial missing"
fi

# --- AC4: Prev/next navigation ---
echo ""
echo "--- AC4: Prev/next navigation ---"
if [ -f "$NAV" ]; then
    ok "AC4 — article-nav.html exists"
else
    fail "AC4 — article-nav.html not found"
fi
if grep -q 'PrevInSection' "$NAV"; then
    ok "AC4 — PrevInSection used"
else
    fail "AC4 — PrevInSection missing"
fi
if grep -q 'NextInSection' "$NAV"; then
    ok "AC4 — NextInSection used"
else
    fail "AC4 — NextInSection missing"
fi
if grep -q 'Article précédent' "$NAV"; then
    ok "AC4 — 'Article précédent' label"
else
    fail "AC4 — 'Article précédent' label missing"
fi
if grep -q 'Article suivant' "$NAV"; then
    ok "AC4 — 'Article suivant' label"
else
    fail "AC4 — 'Article suivant' label missing"
fi

# --- AC5: Responsive mobile ---
echo ""
echo "--- AC5: Responsive mobile ---"
if grep -q '@media.*max-width.*639px' "$CSS"; then
    ok "AC5 — mobile breakpoint styles present"
else
    fail "AC5 — mobile breakpoint styles missing"
fi

# --- AC6: Desktop centered ---
echo ""
echo "--- AC6: Desktop centered ---"
if grep -q 'margin: 0 auto' "$CSS"; then
    ok "AC6 — article centered with margin auto"
else
    fail "AC6 — article not centered"
fi

# --- AC7: Tags/categories clickable ---
echo ""
echo "--- AC7: Tags/categories clickable ---"
if grep -q 'tags/' "$SINGLE" && grep -q 'urlize' "$SINGLE"; then
    ok "AC7 — tags link to taxonomy pages"
else
    fail "AC7 — tags not linked"
fi
if grep -q 'categories/' "$SINGLE"; then
    ok "AC7 — categories link to taxonomy pages"
else
    fail "AC7 — categories not linked"
fi

# --- AC8: No parasitic UI elements ---
echo ""
echo "--- AC8: No parasitic UI elements ---"
if ! sed '/{{\/\*/,/\*\/}}/d; /\/\*/,/\*\//d' "$SINGLE" | grep -qi 'sticky\|progress.bar\|share\|partage\|vous aimerez'; then
    ok "AC8 — no parasitic UI elements"
else
    fail "AC8 — parasitic UI elements found"
fi
if ! grep -qi 'disqus\|giscus\|graphcomment' "$SINGLE"; then
    ok "AC8 — no comment systems"
else
    fail "AC8 — comment system found"
fi

# --- DoD: CSS uses tokens ---
echo ""
echo "--- DoD: CSS tokens usage ---"
ARTICLE_CSS=$(grep -A200 'Article page' "$CSS" || true)
if ! echo "$ARTICLE_CSS" | grep -qE 'color:\s*#[0-9a-fA-F]|background:\s*#[0-9a-fA-F]'; then
    ok "DoD — no hardcoded colors in article CSS"
else
    fail "DoD — hardcoded colors found in article CSS"
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
