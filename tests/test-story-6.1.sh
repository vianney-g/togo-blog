#!/usr/bin/env bash
# =============================================================================
# Story 6.1 — Page d'accueil (liste chronologique)
# =============================================================================
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

ok()   { echo "✅ PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "❌ FAIL: $1"; FAIL=$((FAIL + 1)); }

INDEX="$ROOT/layouts/index.html"
COMPONENTS_CSS="$ROOT/assets/css/components.css"
LAYOUT_CSS="$ROOT/assets/css/layout.css"

echo "=== Story 6.1 — Page d'accueil (liste chronologique) ==="
echo ""

# --- AC1: Articles les plus récents en premier ---
echo "--- AC1: Chronological listing (most recent first) ---"
if [ -f "$INDEX" ]; then
    ok "AC1 — index.html exists"
else
    fail "AC1 — index.html not found"
fi
if grep -q 'Paginate' "$INDEX"; then
    ok "AC1 — uses Hugo pagination"
else
    fail "AC1 — no Paginate call found"
fi
# GroupByDate ensures chronological grouping (Hugo default: most recent first)
if grep -q 'GroupByDate' "$INDEX"; then
    ok "AC1 — uses GroupByDate for chronological order"
else
    fail "AC1 — GroupByDate not found"
fi

# --- AC2: Each article entry shows title, author, date, summary ---
echo ""
echo "--- AC2: Article card content (title, author, date, summary) ---"
if grep -q 'article-card__title' "$INDEX"; then
    ok "AC2 — title element present"
else
    fail "AC2 — title element missing"
fi
if grep -q '\.Title' "$INDEX"; then
    ok "AC2 — renders .Title"
else
    fail "AC2 — .Title not rendered"
fi
if grep -q 'article-card__meta' "$INDEX"; then
    ok "AC2 — meta element present"
else
    fail "AC2 — meta element missing"
fi
if grep -qE '(\.Params\.author|\.Params\.auteur)' "$INDEX"; then
    ok "AC2 — author rendered"
else
    fail "AC2 — author not rendered"
fi
if grep -q 'datetime=' "$INDEX"; then
    ok "AC2 — date with datetime attribute"
else
    fail "AC2 — date missing datetime attribute"
fi
if grep -q 'article-card__excerpt' "$INDEX"; then
    ok "AC2 — excerpt/summary element present"
else
    fail "AC2 — excerpt/summary element missing"
fi
if grep -q '\.Summary' "$INDEX"; then
    ok "AC2 — renders .Summary"
else
    fail "AC2 — .Summary not rendered"
fi

# --- AC3: Articles grouped by month ---
echo ""
echo "--- AC3: Grouped by month ---"
if grep -q 'month-group' "$INDEX"; then
    ok "AC3 — month-group section present"
else
    fail "AC3 — month-group section missing"
fi
if grep -q 'month-heading' "$INDEX"; then
    ok "AC3 — month-heading present"
else
    fail "AC3 — month-heading missing"
fi

# --- AC4: Pagination (20 articles per page) ---
echo ""
echo "--- AC4: Pagination ---"
if grep -qE 'Paginate.*20' "$INDEX"; then
    ok "AC4 — paginate with 20 items"
else
    fail "AC4 — pagination not set to 20"
fi
if grep -q 'pagination' "$INDEX" || [ -f "$ROOT/layouts/partials/pagination.html" ]; then
    ok "AC4 — pagination template referenced or exists"
else
    fail "AC4 — pagination template missing"
fi

# --- AC5 & AC6: Responsive layout (mobile 360px, desktop centered) ---
echo ""
echo "--- AC5/AC6: Responsive layout ---"
# The .home class should use --content-max-width and auto margins
if grep -q '\.home' "$COMPONENTS_CSS" || grep -q '\.home' "$LAYOUT_CSS"; then
    ok "AC5/AC6 — .home class styled"
else
    fail "AC5/AC6 — .home class not styled"
fi
if grep -q 'content-max-width' "$COMPONENTS_CSS" || grep -q 'content-max-width' "$LAYOUT_CSS"; then
    ok "AC6 — uses --content-max-width"
else
    fail "AC6 — --content-max-width not used"
fi

# --- AC7: Article card is clickable (links to full article) ---
echo ""
echo "--- AC7: Clickable article card ---"
if grep -q '\.RelPermalink' "$INDEX"; then
    ok "AC7 — links to article via .RelPermalink"
else
    fail "AC7 — .RelPermalink not found"
fi
if grep -q '<a ' "$INDEX"; then
    ok "AC7 — anchor tag present"
else
    fail "AC7 — no anchor tag"
fi

# --- AC8: No hero, no carousel, no featured section ---
echo ""
echo "--- AC8: No forbidden elements ---"
if ! grep -qi 'hero' "$INDEX"; then
    ok "AC8 — no hero element"
else
    fail "AC8 — hero element found"
fi
if ! grep -qi 'carousel' "$INDEX"; then
    ok "AC8 — no carousel"
else
    fail "AC8 — carousel found"
fi
if ! grep -qi 'featured' "$INDEX" && ! grep -qi 'mise-en-avant' "$INDEX"; then
    ok "AC8 — no featured/mise-en-avant section"
else
    fail "AC8 — featured section found"
fi

# --- DoD: Uses design tokens (no hardcoded colors) ---
echo ""
echo "--- DoD: Design tokens compliance ---"
if ! grep -qE '#[0-9a-fA-F]{3,6}' "$INDEX"; then
    ok "DoD — no hardcoded colors in template"
else
    fail "DoD — hardcoded colors found in template"
fi

# --- DoD: Articles from posts/ and puits-de-jacob/ ---
echo ""
echo "--- DoD: Multi-section content ---"
if grep -q 'posts' "$INDEX" && grep -q 'puits-de-jacob' "$INDEX"; then
    ok "DoD — includes both posts and puits-de-jacob sections"
else
    fail "DoD — not including both content sections"
fi

# --- DoD: Uses existing article-card component ---
echo ""
echo "--- DoD: Reuses article-card component ---"
if grep -q 'article-card' "$INDEX"; then
    ok "DoD — uses article-card component class"
else
    fail "DoD — article-card component not used"
fi

# --- Hugo build test ---
echo ""
echo "--- Build: Hugo compiles without errors ---"
# Create temporary test content if needed
TEMP_CONTENT=false
if [ ! -d "$ROOT/content/posts" ]; then
    TEMP_CONTENT=true
    mkdir -p "$ROOT/content/posts"
    mkdir -p "$ROOT/content/puits-de-jacob"
    cat > "$ROOT/content/_index.md" << 'EOMD'
---
title: "Le Togo en famille"
---
EOMD
    for i in $(seq 1 3); do
        cat > "$ROOT/content/posts/2026-04-0${i}-test-${i}.md" << EOMD
---
title: "Article test ${i}"
date: 2026-04-0${i}
author: "Papa"
summary: "Résumé de l'article test ${i} pour vérifier la page d'accueil."
---
Contenu de l'article test ${i}.
EOMD
    done
    cat > "$ROOT/content/puits-de-jacob/2026-03-15-puits-test.md" << 'EOMD'
---
title: "Article Puits de Jacob"
date: 2026-03-15
author: "Maman"
summary: "Un article du Puits de Jacob."
---
Contenu puits de jacob.
EOMD
fi

BUILD_OUTPUT=$(cd "$ROOT" && hugo --quiet 2>&1)
BUILD_EXIT=$?
if [ $BUILD_EXIT -eq 0 ]; then
    ok "Build — hugo builds successfully"
else
    fail "Build — hugo build failed: $BUILD_OUTPUT"
fi

# Check that index.html was generated
if [ -f "$ROOT/public/index.html" ]; then
    ok "Build — public/index.html generated"
    # Verify content in generated HTML
    if grep -q 'article-card' "$ROOT/public/index.html"; then
        ok "Build — article-card rendered in output"
    else
        fail "Build — article-card not in output"
    fi
    if grep -q 'month-group' "$ROOT/public/index.html"; then
        ok "Build — month-group rendered in output"
    else
        fail "Build — month-group not in output"
    fi
else
    fail "Build — public/index.html not generated"
    fail "Build — (skipped content checks)"
    fail "Build — (skipped content checks)"
fi

# Cleanup temp content
if [ "$TEMP_CONTENT" = true ]; then
    rm -rf "$ROOT/content/posts" "$ROOT/content/puits-de-jacob" "$ROOT/content/_index.md"
    rm -rf "$ROOT/public"
fi

# --- Month heading styles ---
echo ""
echo "--- Styles: Month heading ---"
if grep -q 'month-heading' "$COMPONENTS_CSS" || grep -q 'month-heading' "$LAYOUT_CSS"; then
    ok "Styles — .month-heading styled"
else
    fail "Styles — .month-heading not styled"
fi

# --- Pagination styles ---
echo ""
echo "--- Styles: Pagination ---"
if grep -q 'pagination' "$COMPONENTS_CSS" || grep -q 'pagination' "$LAYOUT_CSS"; then
    ok "Styles — pagination styled"
else
    fail "Styles — pagination not styled"
fi

echo ""
echo "==========================================="
echo "=== Results: $PASS passed, $FAIL failed ==="
echo "==========================================="
exit $FAIL
