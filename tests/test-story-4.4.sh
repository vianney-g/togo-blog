#!/usr/bin/env bash
# =============================================================================
# Story 4.4 — Workflow build-deploy.yml (repo code)
# Tests for .github/workflows/build-deploy.yml
# =============================================================================
set -uo pipefail

PASS=0
FAIL=0

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

echo ""
echo "=== Story 4.4 — build-deploy.yml Workflow Tests ==="
echo ""

WORKFLOW=".github/workflows/build-deploy.yml"

# --- T1: Workflow file exists ---
echo "--- T1: Workflow file exists ---"
if [ -f "$WORKFLOW" ]; then
    echo -e "  ${GREEN}✅ PASS${NC}: build-deploy.yml exists"
    PASS=$((PASS + 1))
else
    echo -e "  ${RED}❌ FAIL${NC}: build-deploy.yml not found"
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

# --- T3: Trigger repository_dispatch content-updated ---
echo "--- T3: Trigger repository_dispatch content-updated ---"
if grep -q 'repository_dispatch' "$WORKFLOW" && grep -q 'content-updated' "$WORKFLOW"; then
    echo -e "  ${GREEN}✅ PASS${NC}: repository_dispatch content-updated"
    PASS=$((PASS + 1))
else
    echo -e "  ${RED}❌ FAIL${NC}: repository_dispatch content-updated missing"
    FAIL=$((FAIL + 1))
fi

# --- T4: Trigger push main ---
echo "--- T4: Trigger push main ---"
if grep -q 'branches:.*main' "$WORKFLOW"; then
    echo -e "  ${GREEN}✅ PASS${NC}: push main trigger"
    PASS=$((PASS + 1))
else
    echo -e "  ${RED}❌ FAIL${NC}: push main trigger missing"
    FAIL=$((FAIL + 1))
fi

# --- T5: Trigger workflow_dispatch ---
echo "--- T5: Trigger workflow_dispatch ---"
if grep -q 'workflow_dispatch' "$WORKFLOW"; then
    echo -e "  ${GREEN}✅ PASS${NC}: workflow_dispatch trigger"
    PASS=$((PASS + 1))
else
    echo -e "  ${RED}❌ FAIL${NC}: workflow_dispatch trigger missing"
    FAIL=$((FAIL + 1))
fi

# --- T6: Checkout with submodules recursive ---
echo "--- T6: Checkout with submodules recursive ---"
if grep -q 'submodules: recursive' "$WORKFLOW"; then
    echo -e "  ${GREEN}✅ PASS${NC}: submodules: recursive"
    PASS=$((PASS + 1))
else
    echo -e "  ${RED}❌ FAIL${NC}: submodules: recursive missing"
    FAIL=$((FAIL + 1))
fi

# --- T7: Content checkout uses CONTENT_READ_PAT ---
echo "--- T7: Content checkout uses CONTENT_READ_PAT ---"
if grep -q 'secrets.CONTENT_READ_PAT' "$WORKFLOW"; then
    echo -e "  ${GREEN}✅ PASS${NC}: Uses CONTENT_READ_PAT"
    PASS=$((PASS + 1))
else
    echo -e "  ${RED}❌ FAIL${NC}: CONTENT_READ_PAT not referenced"
    FAIL=$((FAIL + 1))
fi

# --- T8: Content checkout targets correct repo ---
echo "--- T8: Content checkout targets correct repo ---"
if grep -q 'repository: vianney-g/togo-blog-content' "$WORKFLOW"; then
    echo -e "  ${GREEN}✅ PASS${NC}: Correct content repo"
    PASS=$((PASS + 1))
else
    echo -e "  ${RED}❌ FAIL${NC}: Wrong or missing content repo reference"
    FAIL=$((FAIL + 1))
fi

# --- T9: Merge content copies content/ and static/ ---
echo "--- T9: Merge content copies content/ and static/ ---"
if grep -q 'content-repo/content' "$WORKFLOW" && grep -q 'content-repo/static' "$WORKFLOW"; then
    echo -e "  ${GREEN}✅ PASS${NC}: Merge copies content/ and static/"
    PASS=$((PASS + 1))
else
    echo -e "  ${RED}❌ FAIL${NC}: Merge content step incomplete"
    FAIL=$((FAIL + 1))
fi

# --- T10: Hugo build uses --minify --gc ---
echo "--- T10: Hugo build uses --minify --gc ---"
if grep -q '\-\-minify' "$WORKFLOW" && grep -q '\-\-gc' "$WORKFLOW"; then
    echo -e "  ${GREEN}✅ PASS${NC}: hugo --minify --gc"
    PASS=$((PASS + 1))
else
    echo -e "  ${RED}❌ FAIL${NC}: --minify or --gc missing"
    FAIL=$((FAIL + 1))
fi

# --- T11: Deploy uses actions/deploy-pages ---
echo "--- T11: Deploy uses actions/deploy-pages ---"
if grep -q 'actions/deploy-pages' "$WORKFLOW"; then
    echo -e "  ${GREEN}✅ PASS${NC}: uses deploy-pages"
    PASS=$((PASS + 1))
else
    echo -e "  ${RED}❌ FAIL${NC}: deploy-pages action missing"
    FAIL=$((FAIL + 1))
fi

# --- T12: Has concurrency group ---
echo "--- T12: Has concurrency group ---"
if grep -q 'concurrency' "$WORKFLOW" && grep -q 'group:.*pages' "$WORKFLOW"; then
    echo -e "  ${GREEN}✅ PASS${NC}: concurrency group pages"
    PASS=$((PASS + 1))
else
    echo -e "  ${RED}❌ FAIL${NC}: concurrency group missing"
    FAIL=$((FAIL + 1))
fi

# --- T13: Permissions include pages write and id-token write ---
echo "--- T13: Permissions ---"
if grep -q 'pages: write' "$WORKFLOW" && grep -q 'id-token: write' "$WORKFLOW"; then
    echo -e "  ${GREEN}✅ PASS${NC}: Correct permissions"
    PASS=$((PASS + 1))
else
    echo -e "  ${RED}❌ FAIL${NC}: Permissions incomplete"
    FAIL=$((FAIL + 1))
fi

# --- T14: baseURL uses vianney-g (matches config.yaml) ---
echo "--- T14: baseURL uses vianney-g ---"
if grep -q 'vianney-g.github.io/togo-blog' "$WORKFLOW"; then
    echo -e "  ${GREEN}✅ PASS${NC}: baseURL matches config.yaml"
    PASS=$((PASS + 1))
else
    echo -e "  ${RED}❌ FAIL${NC}: baseURL mismatch with config.yaml"
    FAIL=$((FAIL + 1))
fi

# --- T15: Configure Pages step exists ---
echo "--- T15: Configure Pages step ---"
if grep -q 'actions/configure-pages' "$WORKFLOW"; then
    echo -e "  ${GREEN}✅ PASS${NC}: configure-pages step present"
    PASS=$((PASS + 1))
else
    echo -e "  ${RED}❌ FAIL${NC}: configure-pages step missing"
    FAIL=$((FAIL + 1))
fi

# --- T16: Deploy job depends on build ---
echo "--- T16: Deploy needs build ---"
if grep -q 'needs: build' "$WORKFLOW"; then
    echo -e "  ${GREEN}✅ PASS${NC}: deploy needs build"
    PASS=$((PASS + 1))
else
    echo -e "  ${RED}❌ FAIL${NC}: deploy does not depend on build"
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
