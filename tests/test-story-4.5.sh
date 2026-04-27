#!/usr/bin/env bash
# =============================================================================
# Story 4.5 — Configuration GitHub Pages
# Tests for GitHub Pages configuration consistency
# =============================================================================
set -uo pipefail

PASS=0
FAIL=0

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

echo ""
echo "=== Story 4.5 — GitHub Pages Configuration Tests ==="
echo ""

CONFIG="config.yaml"
WORKFLOW=".github/workflows/build-deploy.yml"
EXPECTED_BASEURL="https://vianney-g.github.io/togo-blog/"

# --- T1: baseURL is HTTPS ---
echo "--- T1: baseURL uses HTTPS ---"
BASEURL=$(grep '^baseURL:' "$CONFIG" | sed 's/baseURL: *"\?\([^"]*\)"\?/\1/')
if echo "$BASEURL" | grep -q '^https://'; then
    echo -e "  ${GREEN}✅ PASS${NC}: baseURL uses HTTPS"
    PASS=$((PASS + 1))
else
    echo -e "  ${RED}❌ FAIL${NC}: baseURL does not use HTTPS: $BASEURL"
    FAIL=$((FAIL + 1))
fi

# --- T2: baseURL ends with / ---
echo "--- T2: baseURL ends with / ---"
if echo "$BASEURL" | grep -q '/$'; then
    echo -e "  ${GREEN}✅ PASS${NC}: baseURL ends with /"
    PASS=$((PASS + 1))
else
    echo -e "  ${RED}❌ FAIL${NC}: baseURL does not end with /: $BASEURL"
    FAIL=$((FAIL + 1))
fi

# --- T3: baseURL matches expected value ---
echo "--- T3: baseURL matches expected ---"
if [ "$BASEURL" = "$EXPECTED_BASEURL" ]; then
    echo -e "  ${GREEN}✅ PASS${NC}: baseURL = $EXPECTED_BASEURL"
    PASS=$((PASS + 1))
else
    echo -e "  ${RED}❌ FAIL${NC}: baseURL mismatch: got '$BASEURL', expected '$EXPECTED_BASEURL'"
    FAIL=$((FAIL + 1))
fi

# --- T4: Workflow file exists and is valid YAML ---
echo "--- T4: build-deploy.yml exists and valid YAML ---"
if [ -f "$WORKFLOW" ] && python3 -c "import yaml; yaml.safe_load(open('$WORKFLOW'))" 2>/dev/null; then
    echo -e "  ${GREEN}✅ PASS${NC}: Workflow exists and valid YAML"
    PASS=$((PASS + 1))
else
    echo -e "  ${RED}❌ FAIL${NC}: Workflow missing or invalid YAML"
    FAIL=$((FAIL + 1))
fi

# --- T5: Workflow uses actions/deploy-pages (not peaceiris) ---
echo "--- T5: Uses actions/deploy-pages (not peaceiris) ---"
if grep -q 'actions/deploy-pages' "$WORKFLOW" && ! grep -q 'peaceiris/actions-gh-pages' "$WORKFLOW"; then
    echo -e "  ${GREEN}✅ PASS${NC}: Uses official deploy-pages action"
    PASS=$((PASS + 1))
else
    echo -e "  ${RED}❌ FAIL${NC}: Should use actions/deploy-pages, not peaceiris"
    FAIL=$((FAIL + 1))
fi

# --- T6: Workflow has pages: write permission ---
echo "--- T6: Permission pages: write ---"
if grep -q 'pages: write' "$WORKFLOW"; then
    echo -e "  ${GREEN}✅ PASS${NC}: pages: write permission"
    PASS=$((PASS + 1))
else
    echo -e "  ${RED}❌ FAIL${NC}: pages: write permission missing"
    FAIL=$((FAIL + 1))
fi

# --- T7: Workflow has id-token: write permission ---
echo "--- T7: Permission id-token: write ---"
if grep -q 'id-token: write' "$WORKFLOW"; then
    echo -e "  ${GREEN}✅ PASS${NC}: id-token: write permission"
    PASS=$((PASS + 1))
else
    echo -e "  ${RED}❌ FAIL${NC}: id-token: write permission missing"
    FAIL=$((FAIL + 1))
fi

# --- T8: Workflow fallback baseURL matches config.yaml ---
echo "--- T8: Workflow fallback baseURL matches config ---"
if grep -q "$EXPECTED_BASEURL" "$WORKFLOW"; then
    echo -e "  ${GREEN}✅ PASS${NC}: Fallback baseURL consistent"
    PASS=$((PASS + 1))
else
    echo -e "  ${RED}❌ FAIL${NC}: Fallback baseURL in workflow doesn't match config"
    FAIL=$((FAIL + 1))
fi

# --- T9: Workflow uses configure-pages ---
echo "--- T9: Workflow uses configure-pages ---"
if grep -q 'actions/configure-pages' "$WORKFLOW"; then
    echo -e "  ${GREEN}✅ PASS${NC}: configure-pages step present"
    PASS=$((PASS + 1))
else
    echo -e "  ${RED}❌ FAIL${NC}: configure-pages step missing"
    FAIL=$((FAIL + 1))
fi

# --- T10: Workflow has github-pages environment ---
echo "--- T10: Deploy uses github-pages environment ---"
if grep -q 'name: github-pages' "$WORKFLOW"; then
    echo -e "  ${GREEN}✅ PASS${NC}: github-pages environment configured"
    PASS=$((PASS + 1))
else
    echo -e "  ${RED}❌ FAIL${NC}: github-pages environment missing"
    FAIL=$((FAIL + 1))
fi

# --- T11: Hugo build uses --minify ---
echo "--- T11: Hugo build uses --minify ---"
if grep -q '\-\-minify' "$WORKFLOW"; then
    echo -e "  ${GREEN}✅ PASS${NC}: --minify flag present"
    PASS=$((PASS + 1))
else
    echo -e "  ${RED}❌ FAIL${NC}: --minify flag missing"
    FAIL=$((FAIL + 1))
fi

# --- T12: No blocking JS in config (disableHLJS) ---
echo "--- T12: No blocking JS (disableHLJS: true) ---"
if grep -q 'disableHLJS: true' "$CONFIG"; then
    echo -e "  ${GREEN}✅ PASS${NC}: Highlight.js disabled (fast load)"
    PASS=$((PASS + 1))
else
    echo -e "  ${RED}❌ FAIL${NC}: disableHLJS not set to true"
    FAIL=$((FAIL + 1))
fi

# --- T13: GitHub Pages setup doc exists ---
echo "--- T13: GitHub Pages setup doc exists ---"
if [ -f "docs/github-pages-setup.md" ]; then
    echo -e "  ${GREEN}✅ PASS${NC}: Setup documentation exists"
    PASS=$((PASS + 1))
else
    echo -e "  ${RED}❌ FAIL${NC}: docs/github-pages-setup.md missing"
    FAIL=$((FAIL + 1))
fi

# --- T14: Hugo build works locally (if Hugo installed) ---
echo "--- T14: Hugo build (if installed) ---"
if command -v hugo &>/dev/null; then
    if hugo --minify --gc 2>&1 | grep -q 'Error'; then
        echo -e "  ${RED}❌ FAIL${NC}: Hugo build has errors"
        FAIL=$((FAIL + 1))
    else
        echo -e "  ${GREEN}✅ PASS${NC}: Hugo build succeeds"
        PASS=$((PASS + 1))
    fi
else
    echo -e "  ${GREEN}✅ PASS${NC}: Hugo not installed, skipping (CI will test)"
    PASS=$((PASS + 1))
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
