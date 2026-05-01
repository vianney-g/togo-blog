#!/usr/bin/env bash
# Verification script for Story 1.1 — Acceptance Criteria
set -uo pipefail

PASS=0
FAIL=0
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

check() {
  local desc="$1"; shift
  if "$@" >/dev/null 2>&1; then
    echo "  ✅ $desc"
    ((PASS++))
  else
    echo "  ❌ $desc"
    ((FAIL++))
  fi
}

echo "=== Story 1.1 Verification ==="

# AC3: Required directories
echo ""
echo "--- AC3: Directory structure ---"
for d in archetypes layouts/partials layouts/shortcodes layouts/_default assets/css themes scripts .githooks .github/workflows schemas docs tests/fixtures; do
  check "Directory $d exists" test -d "$ROOT/$d"
done

# AC4: .gitignore
echo ""
echo "--- AC4: .gitignore ---"
check ".gitignore exists" test -f "$ROOT/.gitignore"
check ".gitignore excludes public/" grep -q "^public/" "$ROOT/.gitignore"
check ".gitignore excludes resources/" grep -q "^resources/" "$ROOT/.gitignore"
check ".gitignore excludes .hugo_build.lock" grep -q "^\.hugo_build\.lock" "$ROOT/.gitignore"

# AC5: README.md
echo ""
echo "--- AC5: README.md ---"
check "README.md exists" test -f "$ROOT/README.md"
check "README.md contains project description" grep -q "Too Good Togo !" "$ROOT/README.md"
check "README.md contains structure table" grep -q "archetypes" "$ROOT/README.md"

# AC1: Git repo
echo ""
echo "--- AC1: Git repository ---"
check "Git repo initialized" test -d "$ROOT/.git"

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ]
