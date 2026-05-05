#!/usr/bin/env bash
# =============================================================================
# Story 9.1 — Scripts de détection des nouveaux articles
# Tests for scripts/detect-new-articles.sh & scripts/extract-metadata.sh
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
echo "=== Story 9.1 — detect-new-articles.sh & extract-metadata.sh Tests ==="
echo ""

DETECT="$ROOT/scripts/detect-new-articles.sh"
EXTRACT="$ROOT/scripts/extract-metadata.sh"

# --- Verify scripts exist ---
if [ ! -x "$DETECT" ]; then
    echo -e "${RED}FATAL: $DETECT not found or not executable${NC}"
    exit 1
fi
if [ ! -x "$EXTRACT" ]; then
    echo -e "${RED}FATAL: $EXTRACT not found or not executable${NC}"
    exit 1
fi

# --- Setup: temporary git repo ---
TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT

cd "$TMPDIR"
git init -q
git config user.email "test@test.com"
git config user.name "Test"
mkdir -p content/posts content/puits-de-jacob

# ============================================================
# AC8: Premier commit (pas de HEAD~1) → exit 0, sortie vide
# ============================================================
echo "Test AC8: Premier commit (no HEAD~1) → exit 0, empty output"
# Only the initial empty commit exists — no HEAD~1
git commit --allow-empty -m "initial" -q
RESULT=$("$DETECT" 2>&1)
RC=$?
if [ $RC -eq 0 ] && [ -z "$RESULT" ]; then
    pass "AC8 — first commit: exit 0, empty output"
else
    fail "AC8 — first commit" "rc=$RC output='$RESULT'"
fi

# ============================================================
# AC1: Fichier ajouté draft: false → détecté
# ============================================================
echo "Test AC1: Article added with draft: false → detected"
cat > content/posts/2026-08-15-arrivee-sokode.md << 'EOF'
---
title: "Arrivée à Sokodé"
date: 2026-08-15
author: "monsieur"
draft: false
description: "Notre premier jour au Togo."
instagram_image: "/images/sokode.jpg"
---
Contenu de l'article.
EOF
git add . && git commit -q -m "add article"
RESULT=$("$DETECT")
if echo "$RESULT" | grep -q "arrivee-sokode"; then
    pass "AC1 — added draft:false detected"
else
    fail "AC1 — added draft:false" "output='$RESULT'"
fi

# ============================================================
# AC2: Fichier ajouté draft: true → NON détecté
# ============================================================
echo "Test AC2: Article added with draft: true → NOT detected"
cat > content/posts/2026-08-16-brouillon.md << 'EOF'
---
title: "Brouillon"
date: 2026-08-16
author: "madame"
draft: true
---
Brouillon.
EOF
git add . && git commit -q -m "add draft"
RESULT=$("$DETECT")
if [ -z "$RESULT" ]; then
    pass "AC2 — added draft:true not detected"
else
    fail "AC2 — added draft:true" "detected: '$RESULT'"
fi

# ============================================================
# AC3: Fichier modifié draft: true → false → détecté
# ============================================================
echo "Test AC3: Modified draft: true → false → detected"
sed -i 's/^draft: true/draft: false/' content/posts/2026-08-16-brouillon.md
git add . && git commit -q -m "publish draft"
RESULT=$("$DETECT")
if echo "$RESULT" | grep -q "brouillon"; then
    pass "AC3 — modified draft true→false detected"
else
    fail "AC3 — modified draft true→false" "output='$RESULT'"
fi

# ============================================================
# AC4: Fichier modifié (autre champ) → NON détecté
# ============================================================
echo "Test AC4: Modified other field → NOT detected"
sed -i 's/^description:.*/description: "Mis à jour"/' content/posts/2026-08-15-arrivee-sokode.md
git add . && git commit -q -m "update description"
RESULT=$("$DETECT")
if [ -z "$RESULT" ]; then
    pass "AC4 — other field modification not detected"
else
    fail "AC4 — other field modification" "detected: '$RESULT'"
fi

# ============================================================
# AC5: Fichier hors content/posts/ → NON détecté
# ============================================================
echo "Test AC5: File outside content/posts/ → NOT detected"
cat > content/puits-de-jacob/2026-08-17-meditation.md << 'EOF'
---
title: "Méditation"
date: 2026-08-17
author: "plume"
draft: false
---
Contenu.
EOF
git add . && git commit -q -m "add puits de jacob"
RESULT=$("$DETECT")
if [ -z "$RESULT" ]; then
    pass "AC5 — file outside posts/ not detected"
else
    fail "AC5 — file outside posts/" "detected: '$RESULT'"
fi

# ============================================================
# AC9: Aucun fichier content/posts/*.md modifié → vide, exit 0
# ============================================================
echo "Test AC9: No content/posts/*.md modified → empty, exit 0"
echo "unrelated" > README.md
git add . && git commit -q -m "unrelated change"
RESULT=$("$DETECT" 2>&1)
RC=$?
if [ $RC -eq 0 ] && [ -z "$RESULT" ]; then
    pass "AC9 — no posts modified: exit 0, empty output"
else
    fail "AC9 — no posts modified" "rc=$RC output='$RESULT'"
fi

# ============================================================
# AC6: extract-metadata.sh — extraction correcte
# ============================================================
echo "Test AC6: extract-metadata.sh — correct metadata extraction"
eval "$("$EXTRACT" content/posts/2026-08-15-arrivee-sokode.md)"
ALL_OK=true
[ "$TITLE" = "Arrivée à Sokodé" ] || ALL_OK=false
[ "$DESCRIPTION" = "Mis à jour" ] || ALL_OK=false
[ "$DATE" = "2026-08-15" ] || ALL_OK=false
[ "$SLUG" = "arrivee-sokode" ] || ALL_OK=false
[ "$INSTAGRAM_IMAGE" = "/images/sokode.jpg" ] || ALL_OK=false
if $ALL_OK; then
    pass "AC6 — metadata extraction (title, description, date, slug, instagram_image)"
else
    fail "AC6 — metadata extraction" "TITLE=$TITLE DESC=$DESCRIPTION DATE=$DATE SLUG=$SLUG IMG=$INSTAGRAM_IMAGE"
fi

# ============================================================
# AC7: Construction URL /:year/:month/:slug/
# ============================================================
echo "Test AC7: URL construction from date + slug"
if [ "$URL" = "https://toogoodtogo.blog/2026/08/arrivee-sokode/" ]; then
    pass "AC7 — URL = https://toogoodtogo.blog/2026/08/arrivee-sokode/"
else
    fail "AC7 — URL construction" "URL=$URL"
fi

# ============================================================
# Summary
# ============================================================
echo ""
echo "=== Results: $PASS pass, $FAIL fail ==="
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
