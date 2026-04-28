#!/usr/bin/env bash
# Test script for Story 1.2 — Acceptance Criteria verification
set -euo pipefail

REPO="/home/vianney/perso/togo-blog-content"
PASS=0
FAIL=0

check() {
  local desc="$1"; shift
  if "$@" >/dev/null 2>&1; then
    echo "✅ PASS: $desc"
    PASS=$((PASS + 1))
  else
    echo "❌ FAIL: $desc"
    FAIL=$((FAIL + 1))
  fi
}

echo "=== Story 1.2 — Acceptance Criteria Tests ==="
echo ""

# AC1: Root contains only expected dirs/files
echo "--- AC1: Root structure ---"
check "content/ exists" test -d "$REPO/content"
check "static/img/ exists" test -d "$REPO/static/img"
check "archetypes/ exists" test -d "$REPO/archetypes"
check "templates-typora/ exists" test -d "$REPO/templates-typora"
check ".githooks/ exists" test -d "$REPO/.githooks"
check ".github/workflows/ exists" test -d "$REPO/.github/workflows"
check "README.md exists" test -f "$REPO/README.md"
check ".gitignore exists" test -f "$REPO/.gitignore"

# AC2: No code files at root
echo ""
echo "--- AC2: No code files at root ---"
check "No .js files at root" bash -c '! ls "$1"/*.js 2>/dev/null | grep -q .' -- "$REPO"
check "No .go files at root" bash -c '! ls "$1"/*.go 2>/dev/null | grep -q .' -- "$REPO"
check "No .css files at root" bash -c '! ls "$1"/*.css 2>/dev/null | grep -q .' -- "$REPO"
check "No .yaml at root (except in .github)" bash -c '! ls "$1"/*.yaml "$1"/*.yml 2>/dev/null | grep -q .' -- "$REPO"

# AC3: content/ subdirectories
echo ""
echo "--- AC3: content/ structure ---"
check "content/posts/ exists" test -d "$REPO/content/posts"
check "content/auteurs/ exists" test -d "$REPO/content/auteurs"
check "content/a-propos.md exists" test -f "$REPO/content/a-propos.md"
check "content/_index.md exists" test -f "$REPO/content/_index.md"

# AC4: static/img/ ready
echo ""
echo "--- AC4: static/img/ ---"
check "static/img/ exists with .gitkeep" test -f "$REPO/static/img/.gitkeep"

# AC5: GitHub access — SKIP (cannot verify locally)
echo ""
echo "--- AC5: GitHub access ---"
echo "⏭️  SKIP: AC5 — GitHub access cannot be verified locally"

# AC6: .gitignore content
echo ""
echo "--- AC6: .gitignore ---"
check ".gitignore contains .DS_Store" grep -q "\.DS_Store" "$REPO/.gitignore"
check ".gitignore contains Thumbs.db" grep -q "Thumbs.db" "$REPO/.gitignore"
check ".gitignore contains .vscode/" grep -q "\.vscode/" "$REPO/.gitignore"
check ".gitignore contains .idea/" grep -q "\.idea/" "$REPO/.gitignore"
check ".gitignore contains *.swp" grep -q "\*\.swp" "$REPO/.gitignore"

# Git repo check
echo ""
echo "--- Git repo ---"
check "Is a git repository" test -d "$REPO/.git"
check "Has initial commit" bash -c 'cd "$1" && git log --oneline -1' -- "$REPO"

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
