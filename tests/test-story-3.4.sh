#!/usr/bin/env bash
# =============================================================================
# Story 3.4 — Configuration des taxonomies Hugo
# =============================================================================
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

ok()   { echo "✅ PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "❌ FAIL: $1"; FAIL=$((FAIL + 1)); }

echo "=== Story 3.4 — Taxonomies Hugo Tests ==="
echo ""

# --- AC1: Taxonomies configured in config.yaml ---
echo "--- AC1: Taxonomies in config.yaml ---"
if grep -A4 '^taxonomies:' "$ROOT/config.yaml" | grep -q 'author: authors' &&
   grep -A4 '^taxonomies:' "$ROOT/config.yaml" | grep -q 'category: categories' &&
   grep -A4 '^taxonomies:' "$ROOT/config.yaml" | grep -q 'tag: tags'; then
    ok "AC1 — taxonomies author/category/tag configured"
else
    fail "AC1 — taxonomies missing or incomplete"
fi

# --- AC5: Author skeleton pages exist with title ---
echo "--- AC5: Author skeleton pages ---"
ALL_AUTHORS=true
for author in monsieur madame plume; do
    FILE="$ROOT/content/authors/$author/_index.md"
    if [ ! -f "$FILE" ]; then
        fail "AC5 — $FILE missing"
        ALL_AUTHORS=false
    elif ! grep -q '^title:' "$FILE"; then
        fail "AC5 — $FILE has no title"
        ALL_AUTHORS=false
    fi
done
if $ALL_AUTHORS; then
    ok "AC5 — all author pages exist with title"
fi

# --- DoD: Author pages have description ---
echo "--- DoD: Author pages have description ---"
ALL_DESC=true
for author in monsieur madame plume; do
    FILE="$ROOT/content/authors/$author/_index.md"
    if [ -f "$FILE" ] && ! grep -q 'description:' "$FILE"; then
        fail "DoD — $FILE has no description"
        ALL_DESC=false
    fi
done
if $ALL_DESC; then
    ok "DoD — all author pages have description"
fi

# --- DoD: Section index pages ---
echo "--- DoD: Section index pages ---"
SECTIONS_OK=true
for section in posts; do
    FILE="$ROOT/content/$section/_index.md"
    if [ ! -f "$FILE" ]; then
        fail "DoD — $FILE missing"
        SECTIONS_OK=false
    elif ! grep -q '^title:' "$FILE"; then
        fail "DoD — $FILE has no title"
        SECTIONS_OK=false
    fi
done
if $SECTIONS_OK; then
    ok "DoD — section index pages exist with title"
fi

# --- DoD: Permalinks configured ---
echo "--- DoD: Permalinks ---"
if grep -A3 '^permalinks:' "$ROOT/config.yaml" | grep -q 'posts:'; then
    ok "DoD — permalinks configured for posts"
else
    fail "DoD — permalinks missing"
fi

# --- AC1/AC7: Hugo build succeeds ---
echo "--- AC1/AC7: Hugo build with drafts ---"
BUILD_OUTPUT=$(cd "$ROOT" && hugo -D 2>&1)
BUILD_RC=$?
if [ $BUILD_RC -eq 0 ]; then
    ok "AC1/AC7 — hugo -D builds without error"
else
    fail "AC1/AC7 — hugo -D failed: $BUILD_OUTPUT"
fi

# --- AC2: /authors/plume/ generated ---
echo "--- AC2: authors/plume page generated ---"
if [ -f "$ROOT/public/authors/plume/index.html" ]; then
    ok "AC2 — /authors/plume/ page exists"
else
    fail "AC2 — /authors/plume/index.html not found"
fi

# --- AC6: /authors/monsieur/ generated ---
echo "--- AC6: authors/monsieur page generated ---"
if [ -f "$ROOT/public/authors/monsieur/index.html" ]; then
    ok "AC6 — /authors/monsieur/ page exists"
else
    fail "AC6 — /authors/monsieur/index.html not found"
fi

# --- AC3: /categories/ directory generated ---
echo "--- AC3: categories directory generated ---"
if [ -d "$ROOT/public/categories" ]; then
    ok "AC3 — /categories/ directory exists"
else
    fail "AC3 — /categories/ directory not found"
fi

# --- AC4: /tags/ directory generated ---
echo "--- AC4: tags directory generated ---"
if [ -d "$ROOT/public/tags" ]; then
    ok "AC4 — /tags/ directory exists"
else
    fail "AC4 — /tags/ directory not found"
fi

# --- AC7: No custom taxonomy templates (Paper defaults used) ---
echo "--- AC7: No custom taxonomy templates ---"
if [ ! -d "$ROOT/layouts/taxonomy" ] && [ ! -d "$ROOT/layouts/_default/taxonomy" ]; then
    ok "AC7 — no custom taxonomy templates, Paper defaults used"
else
    fail "AC7 — custom taxonomy templates found (should use Paper defaults)"
fi

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
[ $FAIL -eq 0 ] && exit 0 || exit 1
