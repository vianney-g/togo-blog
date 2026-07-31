#!/usr/bin/env bash
# =============================================================================
# Tests unitaires pour notify-email.sh
# =============================================================================
# 7 cas de test couvrant les acceptance criteria de la story 9.2.
# Utilise un faux `curl` injecté en tête de PATH pour éviter tout appel réseau.
#
# Usage : bash tests/test-story-9.2.sh
# =============================================================================

set -uo pipefail

PASS=0
FAIL=0
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
NOTIFY="$SCRIPT_DIR/scripts/notify-email.sh"

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

pass() { echo -e "  ${GREEN}PASS${NC}: $1"; ((PASS++)); }
fail() { echo -e "  ${RED}FAIL${NC}: $1 — $2"; ((FAIL++)); }

echo "=== Story 9.2 — notify-email.sh Tests ==="
echo ""

# --- Setup : répertoire temporaire avec mock curl ---
TMPDIR_TEST=$(mktemp -d)
trap "rm -rf $TMPDIR_TEST" EXIT

mkdir -p "$TMPDIR_TEST/bin"

# Mock curl : lit MOCK_HTTP_CODE et MOCK_RESPONSE_BODY depuis l'env.
# Parcourt les args pour trouver -o <fichier> et y écrire le body simulé.
# Capture aussi les args reçus (-d et -H) dans MOCK_CURL_ARGS_FILE pour inspection.
cat > "$TMPDIR_TEST/bin/curl" << 'MOCK_EOF'
#!/usr/bin/env bash
OUTPUT_FILE=""
args=("$@")
i=0
while [ $i -lt ${#args[@]} ]; do
    if [ "${args[$i]}" = "-o" ]; then
        i=$((i+1))
        OUTPUT_FILE="${args[$i]}"
    fi
    i=$((i+1))
done
if [ -n "$OUTPUT_FILE" ]; then
    echo -n "${MOCK_RESPONSE_BODY:-}" > "$OUTPUT_FILE"
fi
if [ -n "${MOCK_CURL_ARGS_FILE:-}" ]; then
    printf '%s\n' "${args[@]}" > "$MOCK_CURL_ARGS_FILE"
fi
echo -n "${MOCK_HTTP_CODE:-200}"
MOCK_EOF
chmod +x "$TMPDIR_TEST/bin/curl"

export PATH="$TMPDIR_TEST/bin:$PATH"

# --- Test AC1 : BUTTONDOWN_API_KEY absent → exit 1, message skippé ---
echo "Test AC1: BUTTONDOWN_API_KEY absent → exit 1, message skippé"
unset BUTTONDOWN_API_KEY
OUTPUT=$(bash "$NOTIFY" "Titre" "Description" "https://example.com" 2>&1) && EXIT_CODE=$? || EXIT_CODE=$?
if [ $EXIT_CODE -eq 1 ] && echo "$OUTPUT" | grep -q "non configuré"; then
    pass "AC1 — clé absente : exit 1, warning"
else
    fail "AC1 — clé absente" "exit=$EXIT_CODE output=$OUTPUT"
fi

# --- Test AC2 : BUTTONDOWN_API_KEY vide → exit 1 ---
echo "Test AC2: BUTTONDOWN_API_KEY vide (\"\") → exit 1"
OUTPUT=$(env BUTTONDOWN_API_KEY="" bash "$NOTIFY" "Titre" "Description" "https://example.com" 2>&1) && EXIT_CODE=$? || EXIT_CODE=$?
if [ $EXIT_CODE -eq 1 ] && echo "$OUTPUT" | grep -q "non configuré"; then
    pass "AC2 — clé vide : exit 1, warning"
else
    fail "AC2 — clé vide" "exit=$EXIT_CODE output=$OUTPUT"
fi

# --- Test AC3 : HTTP 201 → exit 0, message ✅ ---
echo "Test AC3: HTTP 201 → exit 0, message succès"
export MOCK_HTTP_CODE=201
export MOCK_RESPONSE_BODY='{"id":"abc123"}'
OUTPUT=$(BUTTONDOWN_API_KEY="sk-test" bash "$NOTIFY" "Arrivée à Sokodé" "Description." "https://toogoodtogo.blog/2026/08/arrivee/") && EXIT_CODE=$? || EXIT_CODE=$?
if [ $EXIT_CODE -eq 0 ] && echo "$OUTPUT" | grep -q "Email envoyé"; then
    pass "AC3 — HTTP 201 : exit 0, message ✅"
else
    fail "AC3 — HTTP 201" "exit=$EXIT_CODE output=$OUTPUT"
fi

# --- Test AC4 : HTTP 200 → exit 0 ---
echo "Test AC4: HTTP 200 → exit 0"
export MOCK_HTTP_CODE=200
OUTPUT=$(BUTTONDOWN_API_KEY="sk-test" bash "$NOTIFY" "Titre" "Desc" "https://example.com") && EXIT_CODE=$? || EXIT_CODE=$?
if [ $EXIT_CODE -eq 0 ] && echo "$OUTPUT" | grep -q "Email envoyé"; then
    pass "AC4 — HTTP 200 : exit 0"
else
    fail "AC4 — HTTP 200" "exit=$EXIT_CODE output=$OUTPUT"
fi

# --- Test AC5 : HTTP 401 → exit 1, message ⚠️ ---
echo "Test AC5: HTTP 401 → exit 1, message erreur"
export MOCK_HTTP_CODE=401
export MOCK_RESPONSE_BODY='{"detail":"Invalid token."}'
OUTPUT=$(BUTTONDOWN_API_KEY="wrong-key" bash "$NOTIFY" "Titre" "Desc" "https://example.com" 2>&1) && EXIT_CODE=$? || EXIT_CODE=$?
if [ $EXIT_CODE -eq 1 ] && echo "$OUTPUT" | grep -q "Échec email"; then
    pass "AC5 — HTTP 401 : exit 1, message ⚠️"
else
    fail "AC5 — HTTP 401" "exit=$EXIT_CODE output=$OUTPUT"
fi

# --- Test AC6 : HTTP 500 → exit 1 ---
echo "Test AC6: HTTP 500 → exit 1"
export MOCK_HTTP_CODE=500
export MOCK_RESPONSE_BODY='Internal Server Error'
OUTPUT=$(BUTTONDOWN_API_KEY="sk-test" bash "$NOTIFY" "Titre" "Desc" "https://example.com" 2>&1) && EXIT_CODE=$? || EXIT_CODE=$?
if [ $EXIT_CODE -eq 1 ] && echo "$OUTPUT" | grep -q "Échec email"; then
    pass "AC6 — HTTP 500 : exit 1"
else
    fail "AC6 — HTTP 500" "exit=$EXIT_CODE output=$OUTPUT"
fi

# --- Test AC7 : titre avec accents et guillemets français → JSON valide, exit 0 ---
echo "Test AC7: Titre avec accents/guillemets → JSON non cassé, exit 0"
export MOCK_HTTP_CODE=201
export MOCK_RESPONSE_BODY='{"id":"xyz"}'
TITRE_SPECIAL="L'arrivée à « Sokodé » — été & hiver"
OUTPUT=$(BUTTONDOWN_API_KEY="sk-test" bash "$NOTIFY" "$TITRE_SPECIAL" "Description avec éèêâç." "https://toogoodtogo.blog/2026/08/arrivee/") && EXIT_CODE=$? || EXIT_CODE=$?
if [ $EXIT_CODE -eq 0 ] && echo "$OUTPUT" | grep -q "Email envoyé"; then
    pass "AC7 — caractères spéciaux : JSON valide, exit 0"
else
    fail "AC7 — caractères spéciaux" "exit=$EXIT_CODE output=$OUTPUT"
fi

# --- Test AC8 : le JSON posté demande un envoi immédiat (pas un brouillon) ---
echo "Test AC8: JSON posté avec status about_to_send + en-tête de confirmation"
export MOCK_HTTP_CODE=201
export MOCK_RESPONSE_BODY='{"id":"abc123"}'
export MOCK_CURL_ARGS_FILE="$TMPDIR_TEST/curl-args.txt"
OUTPUT=$(BUTTONDOWN_API_KEY="sk-test" bash "$NOTIFY" "Titre" "Desc" "https://example.com") && EXIT_CODE=$? || EXIT_CODE=$?
POSTED_JSON=$(awk '/^-d$/{found=1; next} found' "$MOCK_CURL_ARGS_FILE")
if [ $EXIT_CODE -eq 0 ] \
    && echo "$POSTED_JSON" | tr -d ' \n' | grep -q '"status":"about_to_send"' \
    && grep -qi '^X-Buttondown-Live-Dangerously: true$' "$MOCK_CURL_ARGS_FILE"; then
    pass "AC8 — status about_to_send + en-tête de confirmation envoyés"
else
    fail "AC8 — status/en-tête d'envoi immédiat" "exit=$EXIT_CODE json=$POSTED_JSON args=$(cat "$MOCK_CURL_ARGS_FILE")"
fi
unset MOCK_CURL_ARGS_FILE

echo ""
echo "=== Résultats : $PASS pass, $FAIL fail ==="
[ $FAIL -eq 0 ] && exit 0 || exit 1
