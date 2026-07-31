#!/usr/bin/env bash
# =============================================================================
# notify-new-articles.sh <content-repo-dir>
# =============================================================================
# Enchaîne detect-new-articles.sh → extract-metadata.sh → notify-email.sh
# pour notifier par email chaque article nouvellement publié dans le commit
# entrant du dépôt content.
#
# Ne fait jamais échouer le job CI qui l'appelle : une notification en échec
# (clé API absente, erreur Buttondown) est loguée puis ignorée, le script
# termine toujours en exit 0.
#
# Référence : Architecture auto-notification §6.1/§6.2/§6.3 (story 9.6)
# =============================================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONTENT_DIR="${1:?Usage: notify-new-articles.sh <content-repo-dir>}"

NEW_ARTICLES=$(cd "$CONTENT_DIR" && "$SCRIPT_DIR/detect-new-articles.sh")

if [ -z "$NEW_ARTICLES" ]; then
    echo "Aucun nouvel article détecté"
    exit 0
fi

while IFS= read -r article; do
    [ -z "$article" ] && continue
    echo "Nouvel article détecté : ${article}"
    if ! eval "$("$SCRIPT_DIR/extract-metadata.sh" "$CONTENT_DIR/$article")"; then
        echo "⚠️ Extraction des métadonnées échouée pour ${article}"
        continue
    fi
    "$SCRIPT_DIR/notify-email.sh" "$TITLE" "$DESCRIPTION" "$URL" \
        || echo "⚠️ Notification échouée pour ${article}"
done <<< "$NEW_ARTICLES"

exit 0
