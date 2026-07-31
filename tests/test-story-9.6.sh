#!/usr/bin/env bash
# =============================================================================
# Story 9.6 — Orchestration CI : notify-new-articles.sh
# Tests for scripts/notify-new-articles.sh (detect → extract → notify-email)
# =============================================================================
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

pass() { echo -e "  ${GREEN}PASS${NC}: $1"; ((PASS++)); }
fail() { echo -e "  ${RED}FAIL${NC}: $1 — $2"; ((FAIL++)); }

echo ""
echo "=== Story 9.6 — notify-new-articles.sh Tests ==="
echo ""

NOTIFY_NEW="$ROOT/scripts/notify-new-articles.sh"

if [ ! -x "$NOTIFY_NEW" ]; then
    echo -e "${RED}FATAL: $NOTIFY_NEW not found or not executable${NC}"
    exit 1
fi

# --- Setup : dépôt git temporaire (fait office de content-repo) ---
TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT

CONTENT_DIR="$TMPDIR/content-repo"
mkdir -p "$CONTENT_DIR/content/posts"
cd "$CONTENT_DIR"
git init -q
git config user.email "test@test.com"
git config user.name "Test"
git commit --allow-empty -m "initial" -q

# --- Mock curl (capture les requêtes, ne fait aucun appel réseau) ---
mkdir -p "$TMPDIR/bin"
CALLS_FILE="$TMPDIR/curl-calls.txt"
cat > "$TMPDIR/bin/curl" << MOCK_EOF
#!/usr/bin/env bash
echo "call" >> "$CALLS_FILE"
OUTPUT_FILE=""
args=("\$@")
i=0
while [ \$i -lt \${#args[@]} ]; do
    if [ "\${args[\$i]}" = "-o" ]; then
        i=\$((i+1))
        OUTPUT_FILE="\${args[\$i]}"
    fi
    i=\$((i+1))
done
if [ -n "\$OUTPUT_FILE" ]; then
    echo -n "\${MOCK_RESPONSE_BODY:-{}}" > "\$OUTPUT_FILE"
fi
if [ -n "\${MOCK_CURL_ARGS_FILE:-}" ]; then
    printf '%s\n' "\${args[@]}" >> "\$MOCK_CURL_ARGS_FILE"
fi
echo -n "\${MOCK_HTTP_CODE:-201}"
MOCK_EOF
chmod +x "$TMPDIR/bin/curl"
export PATH="$TMPDIR/bin:$PATH"
export BUTTONDOWN_API_KEY="sk-test"

# ============================================================
# Test 1 : aucun nouvel article → exit 0, notify-email jamais appelé
# ============================================================
echo "Test 1: Aucun nouvel article → exit 0, curl jamais appelé"
rm -f "$CALLS_FILE"
export MOCK_HTTP_CODE=201
OUTPUT=$("$NOTIFY_NEW" "$CONTENT_DIR" 2>&1)
RC=$?
if [ $RC -eq 0 ] && [ ! -f "$CALLS_FILE" ]; then
    pass "Test 1 — aucun article : exit 0, aucun appel API"
else
    fail "Test 1 — aucun article" "rc=$RC calls=$(cat "$CALLS_FILE" 2>/dev/null | wc -l) output=$OUTPUT"
fi

# ============================================================
# Test 2 : un article publié → notify-email appelé avec le bon contenu
# ============================================================
echo "Test 2: Un article publié → notify-email appelé (titre/description/URL corrects)"
cat > "$CONTENT_DIR/content/posts/2026-08-15-arrivee-sokode.md" << 'EOF'
---
title: "Arrivée à Sokodé"
date: 2026-08-15
author: "monsieur"
draft: false
description: "Notre premier jour au Togo."
---
Contenu de l'article.
EOF
git -C "$CONTENT_DIR" add .
git -C "$CONTENT_DIR" commit -q -m "add article"

rm -f "$CALLS_FILE"
export MOCK_CURL_ARGS_FILE="$TMPDIR/curl-args.txt"
rm -f "$MOCK_CURL_ARGS_FILE"
export MOCK_HTTP_CODE=201
export MOCK_RESPONSE_BODY='{"id":"abc123"}'
OUTPUT=$("$NOTIFY_NEW" "$CONTENT_DIR" 2>&1)
RC=$?
POSTED_JSON=$(awk '/^-d$/{found=1; next} found' "$MOCK_CURL_ARGS_FILE" 2>/dev/null)
if [ $RC -eq 0 ] \
    && [ "$(cat "$CALLS_FILE" 2>/dev/null | wc -l)" -eq 1 ] \
    && echo "$POSTED_JSON" | grep -q "Arrivée à Sokodé" \
    && echo "$POSTED_JSON" | grep -q "toogoodtogo.blog/2026/08/arrivee-sokode/"; then
    pass "Test 2 — article publié : notify-email appelé une fois avec le bon contenu"
else
    fail "Test 2 — article publié" "rc=$RC json=$POSTED_JSON output=$OUTPUT"
fi
unset MOCK_CURL_ARGS_FILE

# ============================================================
# Test 3 : échec API (HTTP 500) → le script continue, exit 0 quand même
# ============================================================
echo "Test 3: Échec API (HTTP 500) → exit 0 malgré l'échec de notification"
cat > "$CONTENT_DIR/content/posts/2026-08-16-second-article.md" << 'EOF'
---
title: "Second article"
date: 2026-08-16
author: "madame"
draft: false
description: "Suite du séjour."
---
Contenu.
EOF
git -C "$CONTENT_DIR" add .
git -C "$CONTENT_DIR" commit -q -m "add second article"

export MOCK_HTTP_CODE=500
export MOCK_RESPONSE_BODY='Internal Server Error'
OUTPUT=$("$NOTIFY_NEW" "$CONTENT_DIR" 2>&1)
RC=$?
if [ $RC -eq 0 ] && echo "$OUTPUT" | grep -q "Notification échouée"; then
    pass "Test 3 — échec API : exit 0, erreur loguée mais non bloquante"
else
    fail "Test 3 — échec API" "rc=$RC output=$OUTPUT"
fi

# ============================================================
# Test 4 : plusieurs articles publiés dans le même commit → une notification chacun
# ============================================================
echo "Test 4: Deux articles publiés dans le même commit → deux notifications"
cat > "$CONTENT_DIR/content/posts/2026-08-17-troisieme.md" << 'EOF'
---
title: "Troisième article"
date: 2026-08-17
author: "plume"
draft: false
description: "Encore un article."
---
Contenu.
EOF
cat > "$CONTENT_DIR/content/posts/2026-08-18-quatrieme.md" << 'EOF'
---
title: "Quatrième article"
date: 2026-08-18
author: "plume"
draft: false
description: "Un dernier article."
---
Contenu.
EOF
git -C "$CONTENT_DIR" add .
git -C "$CONTENT_DIR" commit -q -m "add two articles"

rm -f "$CALLS_FILE"
export MOCK_HTTP_CODE=201
export MOCK_RESPONSE_BODY='{"id":"abc123"}'
OUTPUT=$("$NOTIFY_NEW" "$CONTENT_DIR" 2>&1)
RC=$?
if [ $RC -eq 0 ] && [ "$(cat "$CALLS_FILE" 2>/dev/null | wc -l)" -eq 2 ]; then
    pass "Test 4 — deux articles publiés : deux appels notify-email"
else
    fail "Test 4 — deux articles publiés" "rc=$RC calls=$(cat "$CALLS_FILE" 2>/dev/null | wc -l) output=$OUTPUT"
fi

# ============================================================
# Summary
# ============================================================
echo ""
echo "=== Results: $PASS pass, $FAIL fail ==="
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
