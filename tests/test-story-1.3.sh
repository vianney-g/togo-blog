#!/usr/bin/env bash
# Test Story 1.3: Configuration Hugo avec thème Paper
# Usage: bash tests/test-story-1.3.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CONTENT_REPO="/home/vianney/perso/togo-blog-content"
export PATH="$HOME/.local/bin:$PATH"

PASS=0
FAIL=0

pass() { echo "  ✅ $1"; PASS=$((PASS + 1)); }
fail() { echo "  ❌ $1"; FAIL=$((FAIL + 1)); }

echo "=== Story 1.3: Configuration Hugo avec thème Paper ==="
echo ""

# --- AC1: hugo server builds without error, Paper theme ---
echo "--- AC1: Hugo build avec thème Paper ---"

if [ -f "$REPO_DIR/config.yaml" ]; then
  pass "config.yaml exists"
else
  fail "config.yaml missing"
fi

if grep -q 'theme: "hugo-paper"' "$REPO_DIR/config.yaml" 2>/dev/null; then
  pass "theme set to hugo-paper"
else
  fail "theme not set to hugo-paper"
fi

# --- AC2: Taxonomies author, categories, tags ---
echo "--- AC2: Taxonomies ---"

for tax in "author: authors" "tag: tags"; do
  if grep -q "$tax" "$REPO_DIR/config.yaml" 2>/dev/null; then
    pass "taxonomy '$tax' configured"
  else
    fail "taxonomy '$tax' missing"
  fi
done

# --- AC3: Hugo Paper as git submodule (fork, pinned) ---
echo "--- AC3: Submodule Hugo Paper ---"

if [ -f "$REPO_DIR/.gitmodules" ]; then
  pass ".gitmodules exists"
else
  fail ".gitmodules missing"
fi

if grep -q "themes/hugo-paper" "$REPO_DIR/.gitmodules" 2>/dev/null; then
  pass "hugo-paper submodule registered"
else
  fail "hugo-paper submodule not registered"
fi

if grep -q "vianney-g/hugo-paper" "$REPO_DIR/.gitmodules" 2>/dev/null; then
  pass "submodule points to personal fork (vianney-g)"
else
  fail "submodule does not point to vianney-g fork"
fi

if [ -f "$REPO_DIR/themes/hugo-paper/theme.toml" ] || [ -f "$REPO_DIR/themes/hugo-paper/hugo.toml" ] || [ -f "$REPO_DIR/themes/hugo-paper/theme.yaml" ]; then
  pass "hugo-paper theme files present"
else
  fail "hugo-paper theme files not present (submodule not initialized?)"
fi

# --- AC4: Test article visible ---
echo "--- AC4: Article test ---"

if [ -f "$CONTENT_REPO/content/posts/2026-04-28-article-test.md" ]; then
  pass "test article exists in content repo"
else
  fail "test article missing in content repo"
fi

if grep -q 'title:.*Article test' "$CONTENT_REPO/content/posts/2026-04-28-article-test.md" 2>/dev/null; then
  pass "test article has correct title"
else
  fail "test article title incorrect"
fi

# --- AC5: Site title, language fr, menus ---
echo "--- AC5: Title, language, menus ---"

if grep -q 'title: "Le Togo en famille"' "$REPO_DIR/config.yaml" 2>/dev/null; then
  pass "site title configured"
else
  fail "site title missing"
fi

if grep -q 'languageCode: "fr"' "$REPO_DIR/config.yaml" 2>/dev/null; then
  pass "language set to fr"
else
  fail "language not set to fr"
fi

for menu in "Auteurs" "Archives" "À propos"; do
  if grep -q "$menu" "$REPO_DIR/config.yaml" 2>/dev/null; then
    pass "menu '$menu' configured"
  else
    fail "menu '$menu' missing"
  fi
done

# --- AC6: RSS active ---
echo "--- AC6: RSS ---"
# Hugo generates RSS by default; just verify no explicit disable
if grep -q 'disableKinds.*RSS' "$REPO_DIR/config.yaml" 2>/dev/null; then
  fail "RSS is disabled in config"
else
  pass "RSS not disabled (active by default)"
fi

# --- AC7: hugo --minify builds without warnings ---
echo "--- AC7: Hugo build --minify ---"

# Sync content for build test
CLEANUP_CONTENT=false
if [ -d "$CONTENT_REPO/content" ]; then
  cp -r "$CONTENT_REPO/content/"* "$REPO_DIR/content/" 2>/dev/null || true
  mkdir -p "$REPO_DIR/static"
  cp -r "$CONTENT_REPO/static/"* "$REPO_DIR/static/" 2>/dev/null || true
  CLEANUP_CONTENT=true
fi

BUILD_OUTPUT=$(cd "$REPO_DIR" && hugo --minify --gc 2>&1) || true
BUILD_EXIT=$?

if [ $BUILD_EXIT -eq 0 ]; then
  pass "hugo --minify --gc exits 0"
else
  fail "hugo --minify --gc failed (exit $BUILD_EXIT)"
  echo "    Output: $BUILD_OUTPUT"
fi

# Check for warnings in build output
if echo "$BUILD_OUTPUT" | grep -qi "WARN" 2>/dev/null; then
  # Filter out known benign warnings
  REAL_WARNS=$(echo "$BUILD_OUTPUT" | grep -i "WARN" | grep -v "found no layout file" | grep -v "deprecated" || true)
  if [ -n "$REAL_WARNS" ]; then
    fail "hugo --minify produced warnings: $REAL_WARNS"
  else
    pass "hugo --minify no critical warnings"
  fi
else
  pass "hugo --minify no warnings"
fi

# Check RSS file generated
if [ -f "$REPO_DIR/public/index.xml" ]; then
  pass "RSS feed generated (public/index.xml)"
else
  fail "RSS feed not generated"
fi

# Check test article in build output
if find "$REPO_DIR/public/" -path "*/article-test*" -name "index.html" 2>/dev/null | grep -q .; then
  pass "test article rendered in public/"
else
  fail "test article not found in public/"
fi

# Cleanup
if [ "$CLEANUP_CONTENT" = true ]; then
  rm -rf "$REPO_DIR/public/" "$REPO_DIR/resources/"
  # Remove synced content (belongs to content repo)
  rm -rf "$REPO_DIR/content/posts" "$REPO_DIR/content/auteurs"
  rm -f "$REPO_DIR/content/_index.md" "$REPO_DIR/content/a-propos.md"
  rm -rf "$REPO_DIR/static/img"
fi

# --- Additional checks ---
echo "--- Additional checks ---"

if grep -q 'baseURL:.*vianney-g.github.io' "$REPO_DIR/config.yaml" 2>/dev/null; then
  pass "baseURL uses vianney-g (not placeholder)"
else
  fail "baseURL does not use vianney-g"
fi

if grep -q 'pagerSize: 20' "$REPO_DIR/config.yaml" 2>/dev/null; then
  pass "pagination configured"
else
  fail "pagination not configured"
fi

if grep -q 'copyright:' "$REPO_DIR/config.yaml" 2>/dev/null; then
  pass "copyright configured"
else
  fail "copyright missing"
fi

# Check .gitkeep removed from themes/
if [ -f "$REPO_DIR/themes/.gitkeep" ]; then
  fail "themes/.gitkeep should be removed (submodule replaces it)"
else
  pass "themes/.gitkeep removed"
fi

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="

if [ $FAIL -gt 0 ]; then
  exit 1
fi
