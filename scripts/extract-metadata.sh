#!/usr/bin/env bash
# =============================================================================
# extract-metadata.sh <fichier.md>
# =============================================================================
# Extrait les métadonnées du front matter YAML d'un article Hugo.
# Produit des variables shell réutilisables via source ou eval.
#
# Sortie (stdout) :
#   TITLE=...
#   DESCRIPTION=...
#   DATE=...
#   SLUG=...
#   URL=...
#   INSTAGRAM_IMAGE=...
#
# Usage :
#   eval "$(./scripts/extract-metadata.sh content/posts/2026-08-15-arrivee-sokode.md)"
#   echo "$TITLE"
#
# Référence : Architecture auto-notification §6.2
# =============================================================================

set -euo pipefail

FILE="${1:?Usage: extract-metadata.sh <fichier.md>}"

if [ ! -f "$FILE" ]; then
    echo "ERROR: Fichier introuvable : $FILE" >&2
    exit 1
fi

# Extraire le bloc front matter (entre les deux ---)
FRONTMATTER=$(sed -n '/^---$/,/^---$/p' "$FILE" | sed '1d;$d')

# Extraire les champs (gestion guillemets optionnels)
TITLE=$(echo "$FRONTMATTER" | grep '^title:' | sed 's/^title: *"\{0,1\}\(.*\)"\{0,1\}$/\1/' | sed 's/"$//')
DESCRIPTION=$(echo "$FRONTMATTER" | grep '^description:' | sed 's/^description: *"\{0,1\}\(.*\)"\{0,1\}$/\1/' | sed 's/"$//' || echo "")
DATE=$(echo "$FRONTMATTER" | grep '^date:' | sed 's/^date: *//' | cut -d'T' -f1)
INSTAGRAM_IMAGE=$(echo "$FRONTMATTER" | grep '^instagram_image:' | sed 's/^instagram_image: *"\{0,1\}\(.*\)"\{0,1\}$/\1/' | sed 's/"$//' || echo "")

# Construire le slug à partir du titre, en reproduisant l'algorithme par
# défaut de Hugo pour :slug (pas de champ `slug` explicite dans le front
# matter) : minuscules, espaces (début/fin/milieu) réduits à des tirets,
# accents et ponctuation conservés tels quels.
SLUG=$(printf '%s' "$TITLE" \
    | perl -CSD -pe '$_ = lc' \
    | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e 's/[[:space:]]\+/-/g')

# Construire l'URL depuis le permalink Hugo (/:year/:month/:slug/)
YEAR=$(echo "$DATE" | cut -d'-' -f1)
MONTH=$(echo "$DATE" | cut -d'-' -f2)
URL="https://toogoodtogo.blog/${YEAR}/${MONTH}/${SLUG}/"

# Sortie sous forme de variables shell
echo "TITLE=$(printf '%q' "$TITLE")"
echo "DESCRIPTION=$(printf '%q' "$DESCRIPTION")"
echo "DATE=$(printf '%q' "$DATE")"
echo "SLUG=$(printf '%q' "$SLUG")"
echo "URL=$(printf '%q' "$URL")"
echo "INSTAGRAM_IMAGE=$(printf '%q' "$INSTAGRAM_IMAGE")"
