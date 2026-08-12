#!/usr/bin/env bash
# =============================================================================
# detect-new-articles.sh
# =============================================================================
# Détecte les articles nouvellement publiés dans le commit entrant.
# Exécuté dans le répertoire content-repo/ (checkout du repo content).
#
# Deux chemins de détection :
#   1. Fichier ajouté avec draft: false
#   2. Fichier modifié avec draft: true → false
#
# Sortie : liste de chemins relatifs d'articles (un par ligne)
# Exit 0 toujours (aucun article = sortie vide, pas une erreur)
#
# Référence : Architecture auto-notification §6.1
# =============================================================================

set -euo pipefail

NEW_ARTICLES=""

# Cas 1 : fichiers ajoutés avec draft: false
ADDED_FILES=$(git diff HEAD~1 --name-only --diff-filter=A -- 'content/posts/*.md' 2>/dev/null || true)
while IFS= read -r file; do
    [ -z "$file" ] && continue
    if [ -f "$file" ] && grep -q '^draft: false' "$file"; then
        NEW_ARTICLES="${NEW_ARTICLES}${file}"$'\n'
    fi
done <<< "$ADDED_FILES"

# Cas 2 : fichiers modifiés avec draft: true → false
MODIFIED_FILES=$(git diff HEAD~1 --name-only --diff-filter=M -- 'content/posts/*.md' 2>/dev/null || true)
while IFS= read -r file; do
    [ -z "$file" ] && continue
    if git diff HEAD~1 -- "$file" | grep -q '^+draft: false'; then
        NEW_ARTICLES="${NEW_ARTICLES}${file}"$'\n'
    fi
done <<< "$MODIFIED_FILES"

# Dédupliquer et afficher (ignorer les lignes vides)
echo -n "$NEW_ARTICLES" | sort -u | grep -v '^$' || true
