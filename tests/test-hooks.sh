#!/usr/bin/env bash
# =============================================================================
# test-hooks.sh — Tests automatisés du pre-commit hook et du scan CI
# =============================================================================
# Usage : bash tests/test-hooks.sh
# Prérequis : git initialisé, .githooks/pre-commit existe
# =============================================================================

set -u

PASS=0
FAIL=0
TOTAL=0

# --- Couleurs ---
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# --- Helper ---
assert_blocked() {
    local description="$1"
    local fixture="$2"
    TOTAL=$((TOTAL + 1))

    # Copier la fixture, stage, tenter le commit
    cp "$fixture" test-hook-tmp.md
    git add test-hook-tmp.md > /dev/null 2>&1

    if git commit --no-gpg-sign -m "test: $description" > /dev/null 2>&1; then
        echo -e "  ${RED}❌ FAIL${NC}: $description (devait bloquer mais commit accepté)"
        git reset --soft HEAD~1 > /dev/null 2>&1
        FAIL=$((FAIL + 1))
    else
        echo -e "  ${GREEN}✅ PASS${NC}: $description (bloqué comme attendu)"
        PASS=$((PASS + 1))
    fi

    git reset HEAD test-hook-tmp.md > /dev/null 2>&1
    rm -f test-hook-tmp.md
}

assert_accepted() {
    local description="$1"
    local fixture="$2"
    TOTAL=$((TOTAL + 1))

    cp "$fixture" test-hook-tmp.md
    git add test-hook-tmp.md > /dev/null 2>&1

    if git commit --no-gpg-sign -m "test: $description" > /dev/null 2>&1; then
        echo -e "  ${GREEN}✅ PASS${NC}: $description (accepté comme attendu)"
        git reset --soft HEAD~1 > /dev/null 2>&1
        PASS=$((PASS + 1))
    else
        echo -e "  ${RED}❌ FAIL${NC}: $description (devait accepter mais bloqué)"
        FAIL=$((FAIL + 1))
    fi

    git reset HEAD test-hook-tmp.md > /dev/null 2>&1
    rm -f test-hook-tmp.md
}

assert_empty_accepted() {
    local description="$1"
    TOTAL=$((TOTAL + 1))

    # Commit sans fichier staged (--allow-empty)
    if git commit --no-gpg-sign --allow-empty -m "test: $description" > /dev/null 2>&1; then
        echo -e "  ${GREEN}✅ PASS${NC}: $description (accepté comme attendu)"
        git reset --soft HEAD~1 > /dev/null 2>&1
        PASS=$((PASS + 1))
    else
        echo -e "  ${RED}❌ FAIL${NC}: $description (devait accepter mais bloqué)"
        FAIL=$((FAIL + 1))
    fi
}

# --- Vérifications ---
if [ ! -f ".githooks/pre-commit" ]; then
    echo "❌ .githooks/pre-commit introuvable. Exécute ce test depuis la racine du repo content."
    exit 1
fi

# S'assurer que le hook est activé
git config --local core.hooksPath .githooks

echo ""
echo "=== Tests du pre-commit hook ==="
echo ""

# --- Tests : hook doit BLOQUER ---
assert_blocked "Prénom exact (Jeanne)" "tests/fixtures/hooks/invalid-jeanne.md"
assert_blocked "Prénom minuscule (tiphaine)" "tests/fixtures/hooks/invalid-lowercase.md"
assert_blocked "Prénom avec accent (Joséphine)" "tests/fixtures/hooks/invalid-accent.md"
assert_blocked "Prénom sans accent (Josephine)" "tests/fixtures/hooks/invalid-no-accent.md"
assert_blocked "Tous les 6 prénoms" "tests/fixtures/hooks/invalid-all-names.md"

# --- Tests : hook doit ACCEPTER ---
assert_accepted "Pseudonyme valide (monsieur)" "tests/fixtures/hooks/valid-pseudonym.md"
assert_accepted "Sous-chaîne non-prénom (Jeanneton)" "tests/fixtures/hooks/valid-substring.md"
assert_empty_accepted "Aucun fichier staged (commit vide)"

echo ""
echo "=== Tests du scan CI ==="
echo ""

# --- Test scan CI : détection ---
TOTAL=$((TOTAL + 1))
if bash scripts/scan-names-ci.sh tests/fixtures/hooks/ > /dev/null 2>&1; then
    echo -e "  ${RED}❌ FAIL${NC}: Scan CI sur fixtures invalides (devait détecter)"
    FAIL=$((FAIL + 1))
else
    echo -e "  ${GREEN}✅ PASS${NC}: Scan CI détecte les prénoms dans les fixtures invalides"
    PASS=$((PASS + 1))
fi

# --- Test scan CI : contenu propre ---
TOTAL=$((TOTAL + 1))
mkdir -p /tmp/test-ci-clean
cp tests/fixtures/hooks/valid-pseudonym.md /tmp/test-ci-clean/
cp tests/fixtures/hooks/valid-substring.md /tmp/test-ci-clean/
if bash scripts/scan-names-ci.sh /tmp/test-ci-clean/ > /dev/null 2>&1; then
    echo -e "  ${GREEN}✅ PASS${NC}: Scan CI passe sur contenu valide"
    PASS=$((PASS + 1))
else
    echo -e "  ${RED}❌ FAIL${NC}: Scan CI sur contenu valide (devait passer)"
    FAIL=$((FAIL + 1))
fi
rm -rf /tmp/test-ci-clean

# --- Résumé ---
echo ""
echo "==========================================="
echo "  Résultats : $PASS/$TOTAL pass, $FAIL fail"
echo "==========================================="

if [ $FAIL -gt 0 ]; then
    exit 1
fi
exit 0
