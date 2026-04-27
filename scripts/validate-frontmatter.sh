#!/usr/bin/env bash
# =============================================================================
# validate-frontmatter.sh — Extraction + validation du front-matter YAML
# =============================================================================
# Extrait le front-matter YAML de chaque fichier .md dans content/,
# puis le valide contre le JSON Schema.
#
# Usage :
#   bash scripts/validate-frontmatter.sh [répertoire] [schema]
#
# Arguments :
#   $1 — Répertoire à scanner (défaut : content/)
#   $2 — Chemin vers le JSON Schema (défaut : schemas/frontmatter.schema.json)
#
# Prérequis :
#   - check-jsonschema (pip install check-jsonschema)
#
# Exit 0 = tout valide
# Exit 1 = au moins une erreur
# =============================================================================

set -u

CONTENT_DIR="${1:-content}"
SCHEMA="${2:-schemas/frontmatter.schema.json}"
TMPDIR=$(mktemp -d)
ERRORS=0
VALIDATED=0
SKIPPED=0

# --- Vérifier les prérequis ---
if ! command -v check-jsonschema > /dev/null 2>&1; then
    echo "❌ check-jsonschema n'est pas installé."
    echo "   Installe-le avec : pipx install check-jsonschema"
    echo "   ou : pip install check-jsonschema"
    exit 1
fi

if [ ! -f "$SCHEMA" ]; then
    echo "❌ Schema introuvable : $SCHEMA"
    exit 1
fi

if [ ! -d "$CONTENT_DIR" ]; then
    echo "❌ Répertoire introuvable : $CONTENT_DIR"
    exit 1
fi

# --- Trouver les fichiers .md (excluant _index.md) ---
FILES=$(find "$CONTENT_DIR" -type f -name "*.md" ! -name "_index.md" 2>/dev/null || true)

if [ -z "$FILES" ]; then
    echo "ℹ️  Aucun fichier .md trouvé dans $CONTENT_DIR"
    exit 0
fi

echo ""
echo "=== Validation front-matter ==="
echo "  Schema : $SCHEMA"
echo "  Répertoire : $CONTENT_DIR"
echo ""

# --- Extraire et valider chaque fichier ---
for file in $FILES; do
    # Extraire le front-matter entre les deux premiers ---
    FRONTMATTER=$(awk '
        /^---$/ { count++; next }
        count == 1 { print }
        count >= 2 { exit }
    ' "$file")

    # Vérifier qu'il y a du front-matter
    if [ -z "$FRONTMATTER" ]; then
        echo "  ⚠️  SKIP: $file (pas de front-matter détecté)"
        SKIPPED=$((SKIPPED + 1))
        continue
    fi

    # Écrire le front-matter dans un fichier temporaire
    TMPFILE="$TMPDIR/$(echo "$file" | tr '/' '_').yaml"
    echo "$FRONTMATTER" > "$TMPFILE"

    # Valider contre le schema
    if check-jsonschema --schemafile "$SCHEMA" "$TMPFILE" > /dev/null 2>&1; then
        VALIDATED=$((VALIDATED + 1))
    else
        echo "  ❌ ERREUR: $file"
        # Relancer pour afficher les détails de l'erreur
        check-jsonschema --schemafile "$SCHEMA" "$TMPFILE" 2>&1 | while IFS= read -r line; do
            echo "     $line"
        done
        echo ""
        ERRORS=$((ERRORS + 1))
    fi
done

# --- Nettoyage ---
rm -rf "$TMPDIR"

# --- Résumé ---
echo ""
echo "==========================================="
echo "  Résultats : $VALIDATED valides, $ERRORS erreurs, $SKIPPED ignorés"
echo "==========================================="

if [ $ERRORS -gt 0 ]; then
    exit 1
fi
exit 0
