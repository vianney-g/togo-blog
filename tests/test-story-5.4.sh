#!/usr/bin/env bash
# =============================================================================
# Story 5.4 — Mode sombre automatique
# =============================================================================
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

ok()   { echo "✅ PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "❌ FAIL: $1"; FAIL=$((FAIL + 1)); }

DARK="$ROOT/assets/css/dark.css"
HEAD_CSS="$ROOT/layouts/partials/head-css.html"

echo "=== Story 5.4 — Mode sombre automatique ==="
echo ""

# --- AC1: dark.css exists with .dark class selector ---
# (Paper's JS handles prefers-color-scheme detection and adds .dark to <html>)
echo "--- AC1: Fond sumi foncé et texte washi crème ---"
if [ -f "$DARK" ]; then
    if grep -q ':root\.dark' "$DARK" || grep -q '\.dark' "$DARK"; then
        ok "AC1 — dark.css uses .dark class selector (Paper JS handles system pref)"
    else
        fail "AC1 — missing .dark class selector"
    fi
    if grep -q 'color-sumi-doux' "$DARK" && grep -q 'color-washi-ombre' "$DARK"; then
        ok "AC1 — bg=sumi-doux, text=washi-ombre tokens present"
    else
        fail "AC1 — missing sumi-doux or washi-ombre tokens"
    fi
else
    fail "AC1 — dark.css not found"
fi

# --- AC2: WCAG AA — semantic tokens overridden ---
echo ""
echo "--- AC2: Tokens sémantiques overridés ---"
for token in color-bg color-bg-secondary color-text color-text-muted color-link color-link-hover color-accent-cold color-accent-warm color-border; do
    if grep -q "\-\-${token}:" "$DARK"; then
        ok "AC2 — --${token} overridden"
    else
        fail "AC2 — --${token} NOT overridden"
    fi
done

# --- AC3: Accents inversés ---
echo ""
echo "--- AC3: Accents asagi/kobaicha inversés ---"
if grep -q 'color-asagi-fonce' "$DARK" && grep -q 'color-kobaicha-fonce' "$DARK"; then
    ok "AC3 — accent variants inverted (asagi-fonce, kobaicha-fonce)"
else
    fail "AC3 — accent variants not properly inverted"
fi

# --- AC4: Mode clair par défaut — dark only via .dark class ---
echo ""
echo "--- AC4: Mode clair par défaut ---"
# Dark styles are scoped under :root.dark or .dark — light is the default
count=$(grep -c ':root\.dark' "$DARK")
if [ "$count" -ge 1 ]; then
    ok "AC4 — dark styles scoped under :root.dark (light is default)"
else
    fail "AC4 — expected :root.dark selector, found none"
fi

# --- AC5: Pas de toggle UI ---
echo ""
echo "--- AC5: Pas de toggle UI ---"
toggle_hits=$(grep -rn 'dark-mode\|theme-toggle\|color-scheme-toggle' "$ROOT/layouts/" "$ROOT/assets/css/" --include='*.html' --include='*.js' 2>/dev/null | wc -l)
if [ "$toggle_hits" -eq 0 ]; then
    ok "AC5 — no dark mode toggle found"
else
    fail "AC5 — found $toggle_hits toggle references"
fi

# --- AC6: Images lisibles (opacity, no invert) ---
echo ""
echo "--- AC6: Images lisibles ---"
if grep -q 'opacity: 0.92' "$DARK"; then
    ok "AC6 — images dimmed with opacity 0.92"
else
    fail "AC6 — missing image opacity rule"
fi
if ! grep -q 'filter.*invert' "$DARK"; then
    ok "AC6 — no invert filter on images"
else
    fail "AC6 — found invert filter on images"
fi
if grep -q 'img:hover' "$DARK" && grep -q 'opacity: 1' "$DARK"; then
    ok "AC6 — hover restores full brightness"
else
    fail "AC6 — missing hover full brightness"
fi

# --- AC7: Astérisme lisible (inherits text color via tokens) ---
echo ""
echo "--- AC7: Astérisme lisible ---"
if grep -q 'color-text' "$DARK"; then
    ok "AC7 — text color token overridden (astérisme inherits)"
else
    fail "AC7 — text color not overridden"
fi

# --- Pipeline integration ---
echo ""
echo "--- Pipeline: dark.css in head-css.html ---"
if grep -q 'dark.css' "$HEAD_CSS"; then
    ok "Pipeline — dark.css referenced in head-css.html"
else
    fail "Pipeline — dark.css NOT in head-css.html"
fi

# --- Hugo build ---
echo ""
echo "--- Hugo build ---"
if (cd "$ROOT" && hugo --minify --quiet 2>&1); then
    ok "Hugo build succeeds with dark.css"
else
    fail "Hugo build failed"
fi

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
