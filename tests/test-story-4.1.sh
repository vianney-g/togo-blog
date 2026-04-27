#!/usr/bin/env bash
# =============================================================================
# Story 4.1 — Workflow validate.yml (repo content)
# Tests for .github/workflows/validate.yml
# =============================================================================
set -uo pipefail

PASS=0
FAIL=0

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

echo ""
echo "=== Story 4.1 — validate.yml Workflow Tests ==="
echo ""

CONTENT_REPO="/home/vianney/perso/togo-blog-content"
WORKFLOW="$CONTENT_REPO/.github/workflows/validate.yml"

# --- T1: Workflow file exists ---
echo "--- T1: Workflow file exists ---"
if [ -f "$WORKFLOW" ]; then
    echo -e "  ${GREEN}✅ PASS${NC}: validate.yml exists"
    PASS=$((PASS + 1))
else
    echo -e "  ${RED}❌ FAIL${NC}: validate.yml not found"
    FAIL=$((FAIL + 1))
fi

# --- T2: Valid YAML ---
echo "--- T2: Valid YAML syntax ---"
if python3 -c "import yaml; yaml.safe_load(open('$WORKFLOW'))" 2>/dev/null; then
    echo -e "  ${GREEN}✅ PASS${NC}: Valid YAML"
    PASS=$((PASS + 1))
else
    echo -e "  ${RED}❌ FAIL${NC}: Invalid YAML"
    FAIL=$((FAIL + 1))
fi

# --- T3: Trigger on push main ---
echo "--- T3: Trigger on push main ---"
if grep -q 'branches:.*main' "$WORKFLOW"; then
    echo -e "  ${GREEN}✅ PASS${NC}: push main trigger"
    PASS=$((PASS + 1))
else
    echo -e "  ${RED}❌ FAIL${NC}: push main trigger missing"
    FAIL=$((FAIL + 1))
fi

# --- T4: Trigger workflow_dispatch ---
echo "--- T4: Trigger workflow_dispatch ---"
if grep -q 'workflow_dispatch' "$WORKFLOW"; then
    echo -e "  ${GREEN}✅ PASS${NC}: workflow_dispatch trigger"
    PASS=$((PASS + 1))
else
    echo -e "  ${RED}❌ FAIL${NC}: workflow_dispatch trigger missing"
    FAIL=$((FAIL + 1))
fi

# --- T5: Step order — lint before validate before scan before dispatch ---
echo "--- T5: Step order (lint → validate → scan → dispatch) ---"
LINT_LINE=$(grep -n -- '- name: Lint Markdown' "$WORKFLOW" | head -1 | cut -d: -f1)
VALIDATE_LINE=$(grep -n -- '- name: Validate front-matter' "$WORKFLOW" | head -1 | cut -d: -f1)
SCAN_LINE=$(grep -n -- '- name: Scan' "$WORKFLOW" | head -1 | cut -d: -f1)
DISPATCH_LINE=$(grep -n -- '- name: Dispatch' "$WORKFLOW" | head -1 | cut -d: -f1)

if [ -n "$LINT_LINE" ] && [ -n "$VALIDATE_LINE" ] && [ -n "$SCAN_LINE" ] && [ -n "$DISPATCH_LINE" ] && \
   [ "$LINT_LINE" -lt "$VALIDATE_LINE" ] && [ "$VALIDATE_LINE" -lt "$SCAN_LINE" ] && [ "$SCAN_LINE" -lt "$DISPATCH_LINE" ]; then
    echo -e "  ${GREEN}✅ PASS${NC}: Steps in correct order"
    PASS=$((PASS + 1))
else
    echo -e "  ${RED}❌ FAIL${NC}: Steps not in correct order (lint=$LINT_LINE validate=$VALIDATE_LINE scan=$SCAN_LINE dispatch=$DISPATCH_LINE)"
    FAIL=$((FAIL + 1))
fi

# --- T6: Dependency files exist in content repo ---
echo "--- T6: Dependency files exist in content repo ---"
DEPS_OK=0
for f in "schemas/frontmatter.schema.json" "scripts/validate-frontmatter.sh" "scripts/scan-names-ci.sh"; do
    if [ -f "$CONTENT_REPO/$f" ]; then
        echo -e "  ${GREEN}✅ PASS${NC}: $f exists"
        PASS=$((PASS + 1))
        DEPS_OK=$((DEPS_OK + 1))
    else
        echo -e "  ${RED}❌ FAIL${NC}: $f missing"
        FAIL=$((FAIL + 1))
    fi
done

# --- T7: Scripts are executable ---
echo "--- T7: Scripts are executable ---"
for f in "scripts/validate-frontmatter.sh" "scripts/scan-names-ci.sh"; do
    if [ -x "$CONTENT_REPO/$f" ]; then
        echo -e "  ${GREEN}✅ PASS${NC}: $f is executable"
        PASS=$((PASS + 1))
    else
        echo -e "  ${RED}❌ FAIL${NC}: $f not executable"
        FAIL=$((FAIL + 1))
    fi
done

# --- T8: Workflow references correct paths ---
echo "--- T8: Workflow references correct paths ---"
if grep -q 'scripts/validate-frontmatter.sh' "$WORKFLOW"; then
    echo -e "  ${GREEN}✅ PASS${NC}: References validate-frontmatter.sh"
    PASS=$((PASS + 1))
else
    echo -e "  ${RED}❌ FAIL${NC}: Missing validate-frontmatter.sh reference"
    FAIL=$((FAIL + 1))
fi
if grep -q 'scripts/scan-names-ci.sh' "$WORKFLOW"; then
    echo -e "  ${GREEN}✅ PASS${NC}: References scan-names-ci.sh"
    PASS=$((PASS + 1))
else
    echo -e "  ${RED}❌ FAIL${NC}: Missing scan-names-ci.sh reference"
    FAIL=$((FAIL + 1))
fi
if grep -q 'schemas/frontmatter.schema.json' "$WORKFLOW"; then
    echo -e "  ${GREEN}✅ PASS${NC}: References frontmatter.schema.json"
    PASS=$((PASS + 1))
else
    echo -e "  ${RED}❌ FAIL${NC}: Missing frontmatter.schema.json reference"
    FAIL=$((FAIL + 1))
fi

# --- T9: Dispatch uses DISPATCH_PAT secret ---
echo "--- T9: Dispatch uses DISPATCH_PAT secret ---"
if grep -q 'secrets.DISPATCH_PAT' "$WORKFLOW"; then
    echo -e "  ${GREEN}✅ PASS${NC}: Uses DISPATCH_PAT"
    PASS=$((PASS + 1))
else
    echo -e "  ${RED}❌ FAIL${NC}: DISPATCH_PAT not referenced"
    FAIL=$((FAIL + 1))
fi

# --- T10: Dispatch event type is content-updated ---
echo "--- T10: Dispatch event type ---"
if grep -q 'content-updated' "$WORKFLOW"; then
    echo -e "  ${GREEN}✅ PASS${NC}: event-type content-updated"
    PASS=$((PASS + 1))
else
    echo -e "  ${RED}❌ FAIL${NC}: event-type missing"
    FAIL=$((FAIL + 1))
fi

# --- T11: Dispatch has if: success() ---
echo "--- T11: Dispatch conditional on success ---"
if grep -q 'if: success()' "$WORKFLOW"; then
    echo -e "  ${GREEN}✅ PASS${NC}: if: success() present"
    PASS=$((PASS + 1))
else
    echo -e "  ${RED}❌ FAIL${NC}: if: success() missing"
    FAIL=$((FAIL + 1))
fi

# --- T12: markdownlint config exists ---
echo "--- T12: markdownlint config exists ---"
if [ -f "$CONTENT_REPO/.markdownlint-cli2.yaml" ]; then
    echo -e "  ${GREEN}✅ PASS${NC}: .markdownlint-cli2.yaml exists"
    PASS=$((PASS + 1))
else
    echo -e "  ${RED}❌ FAIL${NC}: .markdownlint-cli2.yaml missing"
    FAIL=$((FAIL + 1))
fi

# --- Summary ---
TOTAL=$((PASS + FAIL))
echo ""
echo "==========================================="
echo "  Results: $PASS/$TOTAL pass, $FAIL fail"
echo "==========================================="

if [ $FAIL -gt 0 ]; then
    exit 1
fi
exit 0
