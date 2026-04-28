#!/usr/bin/env bash
# =============================================================================
# Story 6.3 — Pages auteurs
# =============================================================================
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

ok()   { echo "✅ PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "❌ FAIL: $1"; FAIL=$((FAIL + 1)); }

LIST="$ROOT/layouts/authors/list.html"
TERM="$ROOT/layouts/authors/term.html"
CSS="$ROOT/assets/css/components.css"

echo "=== Story 6.3 — Pages auteurs ==="
echo ""

# --- AC1: Author page shows pseudonym, emoji, bio, articles ---
echo "--- AC1: Author page (pseudonym, emoji, bio, articles) ---"
if [ -f "$TERM" ]; then
    ok "AC1 — term.html exists"
else
    fail "AC1 — term.html not found"
fi
if grep -q 'author-page__emoji' "$TERM"; then
    ok "AC1 — emoji element present"
else
    fail "AC1 — emoji element missing"
fi
if grep -q 'author-page__bio' "$TERM"; then
    ok "AC1 — bio element present"
else
    fail "AC1 — bio element missing"
fi
if grep -q 'author-page__articles' "$TERM"; then
    ok "AC1 — articles section present"
else
    fail "AC1 — articles section missing"
fi

# --- AC2: Articles filtered by author, reverse chronological ---
echo ""
echo "--- AC2: Articles filtered by author ---"
if grep -q '\.Pages' "$TERM"; then
    ok "AC2 — uses .Pages for author-filtered articles"
else
    fail "AC2 — .Pages not used"
fi

# --- AC3: Stable URL /authors/plume/ ---
echo ""
echo "--- AC3: Stable URL ---"
# Taxonomy templates at layouts/authors/ produce /authors/<term>/ URLs
if [ -d "$ROOT/layouts/authors" ]; then
    ok "AC3 — layouts/authors/ directory exists (stable URLs)"
else
    fail "AC3 — layouts/authors/ directory missing"
fi

# --- AC4: 3 MVP authors with bio and emoji ---
echo ""
echo "--- AC4: 3 MVP authors ---"
for author in monsieur madame plume; do
    FILE="$ROOT/content/auteurs/$author.md"
    if [ -f "$FILE" ]; then
        ok "AC4 — $author.md exists"
    else
        fail "AC4 — $author.md not found"
    fi
    if grep -q 'emoji:' "$FILE"; then
        ok "AC4 — $author has emoji"
    else
        fail "AC4 — $author missing emoji"
    fi
    if grep -q 'description:' "$FILE"; then
        ok "AC4 — $author has description"
    else
        fail "AC4 — $author missing description"
    fi
done

# --- AC5: Author list page ---
echo ""
echo "--- AC5: Author list page ---"
if [ -f "$LIST" ]; then
    ok "AC5 — list.html exists"
else
    fail "AC5 — list.html not found"
fi
if grep -q 'authors-list' "$LIST"; then
    ok "AC5 — authors-list class present"
else
    fail "AC5 — authors-list class missing"
fi
if grep -q 'author-card' "$LIST"; then
    ok "AC5 — author-card class present"
else
    fail "AC5 — author-card class missing"
fi

# --- AC6: Responsive ---
echo ""
echo "--- AC6: Responsive ---"
if grep -q 'authors-list\|author-page' "$CSS"; then
    ok "AC6 — author CSS styles present"
else
    fail "AC6 — author CSS styles missing"
fi
if grep -q 'content-max-width' "$CSS" && grep -q 'author' "$CSS"; then
    ok "AC6 — author styles use content-max-width"
else
    fail "AC6 — author styles don't use content-max-width"
fi

# --- DoD: CSS uses tokens ---
echo ""
echo "--- DoD: CSS tokens usage ---"
AUTHOR_CSS=$(sed -n '/Author/,/^\/\*/p' "$CSS" || true)
if ! echo "$AUTHOR_CSS" | grep -qE 'color:\s*#[0-9a-fA-F]|background:\s*#[0-9a-fA-F]'; then
    ok "DoD — no hardcoded colors in author CSS"
else
    fail "DoD — hardcoded colors found in author CSS"
fi

# --- Hugo build ---
echo ""
echo "--- Hugo build ---"
if (cd "$ROOT" && hugo --minify --quiet 2>&1); then
    ok "Hugo build succeeds"
else
    fail "Hugo build failed"
fi

# --- Verify generated pages ---
echo ""
echo "--- Generated pages ---"
PUBLIC="$ROOT/public"
if [ -d "$PUBLIC/authors" ]; then
    ok "DoD — /authors/ directory generated"
else
    fail "DoD — /authors/ directory not generated"
fi

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
