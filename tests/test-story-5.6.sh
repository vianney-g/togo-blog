#!/usr/bin/env bash
# =============================================================================
# Story 5.6 — Ornements typographiques et print stylesheet
# =============================================================================
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

ok()   { echo "✅ PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "❌ FAIL: $1"; FAIL=$((FAIL + 1)); }

CONFIG="$ROOT/config.yaml"
COMPONENTS="$ROOT/assets/css/components.css"
PRINT="$ROOT/assets/css/print.css"
FOOTER="$ROOT/layouts/partials/article-footer.html"
SINGLE="$ROOT/layouts/_default/single.html"
HEAD_CSS="$ROOT/layouts/partials/head-css.html"

echo "=== Story 5.6 — Ornements typographiques et print stylesheet ==="
echo ""

# --- AC1: Goldmark typographer guillemets français ---
echo "--- AC1: Guillemets français ---"
if grep -q 'leftDoubleQuote' "$CONFIG"; then
    ok "AC1 — leftDoubleQuote configured"
else
    fail "AC1 — leftDoubleQuote not found in config"
fi
if grep -q '«' "$CONFIG"; then
    ok "AC1 — French opening guillemet «"
else
    fail "AC1 — missing « in config"
fi
if grep -q '»' "$CONFIG"; then
    ok "AC1 — French closing guillemet »"
else
    fail "AC1 — missing » in config"
fi

# --- AC2: Fleuron de fin d'article ---
echo ""
echo "--- AC2: Fleuron de fin d'article ---"
if [ -f "$FOOTER" ]; then
    ok "AC2 — article-footer.html exists"
else
    fail "AC2 — article-footer.html not found"
fi
if grep -q '❦' "$FOOTER"; then
    ok "AC2 — fleuron character ❦ present"
else
    fail "AC2 — fleuron character ❦ missing"
fi
if grep -q 'class="fleuron"' "$FOOTER"; then
    ok "AC2 — fleuron CSS class"
else
    fail "AC2 — fleuron CSS class missing"
fi
if grep -q 'aria-hidden="true"' "$FOOTER"; then
    ok "AC2 — aria-hidden for accessibility"
else
    fail "AC2 — aria-hidden missing"
fi

# --- AC3: Astérisme (already in base.css from 5.3) ---
echo ""
echo "--- AC3: Astérisme (⁂) in base.css ---"
BASE="$ROOT/assets/css/base.css"
if grep -q '⁂' "$BASE"; then
    ok "AC3 — asterism ⁂ in base.css (Story 5.3)"
else
    fail "AC3 — asterism ⁂ not found in base.css"
fi

# --- AC4: Typographer enabled ---
echo ""
echo "--- AC4: Typographer enabled ---"
if grep -q 'typographer' "$CONFIG"; then
    ok "AC4 — typographer section in config"
else
    fail "AC4 — typographer not found in config"
fi
if grep -q 'disable: false' "$CONFIG"; then
    ok "AC4 — typographer enabled (disable: false)"
else
    fail "AC4 — typographer not explicitly enabled"
fi

# --- AC5: Print stylesheet ---
echo ""
echo "--- AC5: Print stylesheet ---"
if [ -f "$PRINT" ]; then
    ok "AC5 — print.css exists"
else
    fail "AC5 — print.css not found"
fi
if grep -q '@media print' "$PRINT"; then
    ok "AC5 — @media print block"
else
    fail "AC5 — missing @media print"
fi
if grep -q 'display: none' "$PRINT"; then
    ok "AC5 — elements hidden for print"
else
    fail "AC5 — no display:none for print"
fi
if grep -q 'background: #fff' "$PRINT"; then
    ok "AC5 — white background for print"
else
    fail "AC5 — missing white background"
fi
if grep -q 'color: #000' "$PRINT"; then
    ok "AC5 — black text for print"
else
    fail "AC5 — missing black text"
fi
if grep -q 'font-size: 12pt' "$PRINT"; then
    ok "AC5 — 12pt font for print"
else
    fail "AC5 — missing 12pt font"
fi
if grep -q '@page' "$PRINT"; then
    ok "AC5 — @page margins"
else
    fail "AC5 — missing @page margins"
fi
if grep -q 'page-break-after: avoid' "$PRINT"; then
    ok "AC5 — no page break after headings"
else
    fail "AC5 — missing page-break-after: avoid"
fi
if grep -q 'page-break-inside: avoid' "$PRINT"; then
    ok "AC5 — no page break inside figures/images"
else
    fail "AC5 — missing page-break-inside: avoid"
fi

# --- AC6: Print links show URL ---
echo ""
echo "--- AC6: Print links show URL ---"
if grep -q 'attr(href)' "$PRINT"; then
    ok "AC6 — links show URL via attr(href)"
else
    fail "AC6 — missing attr(href) for link URLs"
fi
if grep -q 'a\[href\^="#"\]' "$PRINT"; then
    ok "AC6 — anchor links excluded"
else
    fail "AC6 — anchor links not excluded"
fi

# --- DoD: Fleuron style in components.css ---
echo ""
echo "--- DoD: Ornament styles ---"
if grep -q '\.article-end' "$COMPONENTS"; then
    ok "DoD — .article-end in components.css"
else
    fail "DoD — .article-end missing from components.css"
fi
if grep -q '\.fleuron' "$COMPONENTS"; then
    ok "DoD — .fleuron in components.css"
else
    fail "DoD — .fleuron missing from components.css"
fi

# --- DoD: print.css in pipeline ---
echo ""
echo "--- DoD: Pipeline integration ---"
if grep -q 'print.css' "$HEAD_CSS"; then
    ok "DoD — print.css in head-css.html pipeline"
else
    fail "DoD — print.css not in pipeline"
fi

# --- DoD: Fleuron partial in single.html ---
echo ""
echo "--- DoD: Fleuron in single template ---"
if [ -f "$SINGLE" ]; then
    ok "DoD — single.html override exists"
else
    fail "DoD — single.html override not found"
fi
if grep -q 'article-footer' "$SINGLE"; then
    ok "DoD — article-footer partial called in single.html"
else
    fail "DoD — article-footer partial not called"
fi

# --- Hugo build ---
echo ""
echo "--- Hugo build ---"
if (cd "$ROOT" && hugo --minify --quiet 2>&1); then
    ok "Hugo build succeeds"
else
    fail "Hugo build failed"
fi

# --- CSS size check ---
echo ""
echo "--- CSS size check ---"
CSS_SIZE=$(cat "$ROOT"/assets/css/*.css | wc -c)
if [ "$CSS_SIZE" -lt 20480 ]; then
    ok "CSS total size ${CSS_SIZE} bytes < 20 Ko"
else
    fail "CSS total size ${CSS_SIZE} bytes >= 20 Ko"
fi

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
