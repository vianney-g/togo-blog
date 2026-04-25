#!/usr/bin/env bash
# =============================================================================
# scan-names-ci.sh — Scan CI des prénoms réels (filet de sécurité n°2)
# =============================================================================
# Différence avec le pre-commit hook :
#   - Scanne TOUS les fichiers texte du repo (pas seulement les staged)
#   - Conçu pour tourner comme step GitHub Actions
#   - Même regex que le hook local
#
# Exit 0 = aucun prénom détecté
# Exit 1 = prénom(s) détecté(s)
# =============================================================================

set -e

# --- Prénoms interdits (même regex que le hook local) ---
FORBIDDEN='Vianney|Tiphaine|Jeanne|Jos[eé]phine|Mayeul|Marthe'

# --- Répertoire de scan ---
# Par défaut : le répertoire courant (racine du repo en CI)
SCAN_DIR="${1:-.}"

# --- Trouver tous les fichiers texte pertinents ---
FILES=$(find "$SCAN_DIR" -type f \( \
    -name "*.md" -o \
    -name "*.yaml" -o \
    -name "*.yml" -o \
    -name "*.toml" -o \
    -name "*.txt" -o \
    -name "*.json" \
\) ! -path "*/.git/*" ! -path "*/node_modules/*" 2>/dev/null || true)

if [ -z "$FILES" ]; then
    echo "ℹ️  Aucun fichier texte trouvé dans $SCAN_DIR"
    exit 0
fi

# --- Scan ---
FOUND=0

for file in $FILES; do
    if grep -nEi "\b($FORBIDDEN)\b" "$file" > /tmp/ci_scan_match.$$ 2>/dev/null; then
        if [ $FOUND -eq 0 ]; then
            echo ""
            echo "╔══════════════════════════════════════════════════╗"
            echo "║  ERREUR CI : Prénom(s) réel(s) détecté(s)        ║"
            echo "╚══════════════════════════════════════════════════╝"
            echo ""
        fi
        echo "  📄 $file :"
        while IFS= read -r line; do
            echo "     $line"
        done < /tmp/ci_scan_match.$$
        echo ""
        FOUND=1
    fi
    rm -f /tmp/ci_scan_match.$$
done

if [ $FOUND -eq 1 ]; then
    echo "  ❌ Le déploiement est bloqué."
    echo "  ℹ️  Remplace les prénoms réels par des pseudonymes."
    echo ""
    exit 1
fi

echo "✅ Scan CI : aucun prénom réel détecté."
exit 0
