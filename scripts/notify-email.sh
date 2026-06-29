#!/usr/bin/env bash
# =============================================================================
# notify-email.sh <title> <description> <url>
# =============================================================================
# Envoie un email de notification à tous les abonnés Buttondown lorsqu'un
# nouvel article est publié sur Too Good Togo !
#
# Prérequis : variable d'environnement BUTTONDOWN_API_KEY
# Dépendances runtime : curl, jq (disponibles sur ubuntu-latest GitHub Actions)
#
# Exit 0 : email envoyé avec succès (HTTP 2xx)
# Exit 1 : clé absente/vide, ou erreur API (HTTP 4xx/5xx)
#           → configuré continue-on-error: true dans le job CI (story 9.6)
#
# Référence : Architecture auto-notification §6.3
# =============================================================================

set -euo pipefail

TITLE="${1:?Usage: notify-email.sh <title> <description> <url>}"
DESCRIPTION="${2:?Usage: notify-email.sh <title> <description> <url>}"
URL="${3:?Usage: notify-email.sh <title> <description> <url>}"

RESPONSE_FILE="/tmp/notify-email-response.txt"

# --- Vérification clé API ---
if [ -z "${BUTTONDOWN_API_KEY:-}" ]; then
    echo "⚠️ BUTTONDOWN_API_KEY non configuré — email skippé"
    exit 1
fi

# --- Construction du body Markdown ---
BODY="Nouvel article sur **Too Good Togo !**

## ${TITLE}

${DESCRIPTION}

👉 [Lire l'article](${URL})

---
*Vous recevez cet email car vous êtes inscrit(e) à la newsletter Too Good Togo !*"

# --- Construction du JSON (jq gère accents, guillemets, caractères spéciaux) ---
JSON_BODY=$(jq -n \
    --arg subject "Nouvel article sur Too Good Togo ! — ${TITLE}" \
    --arg body "$BODY" \
    '{subject: $subject, body: $body, status: "published"}')

# --- Appel API Buttondown ---
HTTP_CODE=$(curl -s \
    -o "$RESPONSE_FILE" \
    -w "%{http_code}" \
    -X POST "https://api.buttondown.com/v1/emails" \
    -H "Authorization: Token ${BUTTONDOWN_API_KEY}" \
    -H "Content-Type: application/json" \
    -d "$JSON_BODY")

# --- Évaluation de la réponse ---
if [ "$HTTP_CODE" -ge 200 ] && [ "$HTTP_CODE" -lt 300 ]; then
    echo "✅ Email envoyé (HTTP ${HTTP_CODE})"
    rm -f "$RESPONSE_FILE"
    exit 0
else
    echo "⚠️ Échec email (HTTP ${HTTP_CODE})"
    cat "$RESPONSE_FILE" 2>/dev/null || true
    rm -f "$RESPONSE_FILE"
    exit 1
fi
