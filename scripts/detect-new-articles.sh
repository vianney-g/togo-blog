#!/usr/bin/env bash
# =============================================================================
# detect-new-articles.sh
# =============================================================================
# Détecte les articles nouvellement publiés dans la plage [BASE_REF, HEAD].
# Exécuté dans le répertoire content-repo/ (checkout du repo content).
#
# Usage : detect-new-articles.sh [base-ref]
#   base-ref : commit de référence à comparer à HEAD (défaut : HEAD~1).
#   Passer le SHA "before" du push réel (via repository_dispatch
#   client_payload) plutôt que de supposer HEAD~1, sinon un push contenant
#   plusieurs commits ne serait comparé qu'à son avant-dernier commit et
#   les commits plus anciens du même push seraient invisibles.
#
# Deux chemins de détection (statuts git A et M uniquement — un fichier
# renommé entre BASE_REF et HEAD, statut R, n'est délibérément pas suivi ici) :
#   1. Fichier ajouté avec draft: false
#   2. Fichier modifié avec draft: true → false
#
# Sortie : liste de chemins relatifs d'articles (un par ligne)
# Exit 0 toujours (aucun article = sortie vide, pas une erreur)
#
# Référence : Architecture auto-notification §6.1
# =============================================================================

set -euo pipefail

BASE_REF="${1:-HEAD~1}"

NEW_ARTICLES=""

# Cas 1 : fichiers ajoutés avec draft: false
ADDED_FILES=$(git diff "$BASE_REF" --name-only --diff-filter=A -- 'content/posts/*.md' 2>/dev/null || true)
while IFS= read -r file; do
    [ -z "$file" ] && continue
    if [ -f "$file" ] && grep -q '^draft: false' "$file"; then
        NEW_ARTICLES="${NEW_ARTICLES}${file}"$'\n'
    fi
done <<< "$ADDED_FILES"

# Cas 2 : fichiers modifiés avec draft: true → false
MODIFIED_FILES=$(git diff "$BASE_REF" --name-only --diff-filter=M -- 'content/posts/*.md' 2>/dev/null || true)
while IFS= read -r file; do
    [ -z "$file" ] && continue
    if git diff "$BASE_REF" -- "$file" | grep -q '^+draft: false'; then
        NEW_ARTICLES="${NEW_ARTICLES}${file}"$'\n'
    fi
done <<< "$MODIFIED_FILES"

# Dédupliquer et afficher (ignorer les lignes vides)
echo -n "$NEW_ARTICLES" | sort -u | grep -v '^$' || true
