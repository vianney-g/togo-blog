#!/usr/bin/env bash
# =============================================================================
# Story 7.1 — Script PowerShell Publier avec GUI WinForms
# Tests statiques (le script est Windows-only, on vérifie structure + contenu)
# =============================================================================
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

ok()   { echo "  ✅ PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  ❌ FAIL: $1"; FAIL=$((FAIL + 1)); }

SCRIPT="$ROOT/scripts/publier.ps1"

echo "=== Story 7.1 — Script PowerShell Publier avec GUI WinForms ==="
echo ""

# --- AC1: Fenêtre GUI avec label, TextBox, bouton "Publier" ---
echo "--- AC1: GUI WinForms (fenêtre, label, TextBox, bouton) ---"

if [ -f "$SCRIPT" ]; then
    ok "AC1 — publier.ps1 exists"
else
    fail "AC1 — publier.ps1 not found"
fi

if grep -q 'System\.Windows\.Forms' "$SCRIPT" 2>/dev/null; then
    ok "AC1 — loads WinForms assembly"
else
    fail "AC1 — missing WinForms assembly"
fi

if grep -q 'System\.Drawing' "$SCRIPT" 2>/dev/null; then
    ok "AC1 — loads Drawing assembly"
else
    fail "AC1 — missing Drawing assembly"
fi

if grep -q 'Windows\.Forms\.Form' "$SCRIPT" 2>/dev/null; then
    ok "AC1 — creates Form"
else
    fail "AC1 — missing Form creation"
fi

if grep -qi 'Message.*optionnel' "$SCRIPT" 2>/dev/null; then
    ok "AC1 — label 'Message (optionnel)'"
else
    fail "AC1 — missing label text"
fi

if grep -q 'Windows\.Forms\.TextBox' "$SCRIPT" 2>/dev/null; then
    ok "AC1 — TextBox present"
else
    fail "AC1 — missing TextBox"
fi

if grep -q 'Publier' "$SCRIPT" 2>/dev/null; then
    ok "AC1 — button text contains 'Publier'"
else
    fail "AC1 — missing Publier button"
fi

if grep -q 'ShowDialog' "$SCRIPT" 2>/dev/null; then
    ok "AC1 — ShowDialog called (modal window)"
else
    fail "AC1 — missing ShowDialog"
fi

# --- AC2: git add/commit/push on button click ---
echo ""
echo "--- AC2: git add && git commit && git push ---"

if grep -q 'git add' "$SCRIPT" 2>/dev/null; then
    ok "AC2 — git add present"
else
    fail "AC2 — missing git add"
fi

if grep -q 'git commit' "$SCRIPT" 2>/dev/null; then
    ok "AC2 — git commit present"
else
    fail "AC2 — missing git commit"
fi

if grep -q 'git push' "$SCRIPT" 2>/dev/null; then
    ok "AC2 — git push present"
else
    fail "AC2 — missing git push"
fi

# --- AC3: MessageBox verte (succès) ---
echo ""
echo "--- AC3: MessageBox succès ---"

if grep -qi 'Article publié' "$SCRIPT" 2>/dev/null; then
    ok "AC3 — success message present"
else
    fail "AC3 — missing success message"
fi

if grep -qi '2 minutes' "$SCRIPT" 2>/dev/null; then
    ok "AC3 — mentions ~2 minutes delay"
else
    fail "AC3 — missing ~2 minutes delay message"
fi

# --- AC4: MessageBox rouge (hook blocks) ---
echo ""
echo "--- AC4: MessageBox erreur hook ---"

if grep -q 'LASTEXITCODE' "$SCRIPT" 2>/dev/null; then
    ok "AC4 — checks LASTEXITCODE after commit"
else
    fail "AC4 — missing LASTEXITCODE check"
fi

if grep -qi 'Error' "$SCRIPT" 2>/dev/null; then
    ok "AC4 — error MessageBox icon used"
else
    fail "AC4 — missing Error MessageBox"
fi

# --- AC5: MessageBox warning (push échoue) ---
echo ""
echo "--- AC5: MessageBox warning push échoué ---"

if grep -qi 'push.*échoué\|push a échoué' "$SCRIPT" 2>/dev/null; then
    ok "AC5 — push failure message present"
else
    fail "AC5 — missing push failure message"
fi

if grep -qi 'Warning' "$SCRIPT" 2>/dev/null; then
    ok "AC5 — warning MessageBox icon used"
else
    fail "AC5 — missing Warning MessageBox"
fi

if grep -qi 'réessayez\|Réessayez' "$SCRIPT" 2>/dev/null; then
    ok "AC5 — retry instruction present"
else
    fail "AC5 — missing retry instruction"
fi

# --- AC6: MessageBox info (rien à publier) ---
echo ""
echo "--- AC6: MessageBox rien à publier ---"

if grep -qi 'aucune modification' "$SCRIPT" 2>/dev/null; then
    ok "AC6 — no changes message present"
else
    fail "AC6 — missing no changes message"
fi

if grep -q 'git status --porcelain' "$SCRIPT" 2>/dev/null; then
    ok "AC6 — uses git status --porcelain to detect changes"
else
    fail "AC6 — missing git status --porcelain"
fi

if grep -qi 'Information' "$SCRIPT" 2>/dev/null; then
    ok "AC6 — Information MessageBox icon used"
else
    fail "AC6 — missing Information MessageBox"
fi

# --- AC7: Message commit par défaut "nouvel article" ---
echo ""
echo "--- AC7: Message commit par défaut ---"

if grep -q 'nouvel article' "$SCRIPT" 2>/dev/null; then
    ok "AC7 — default commit message 'nouvel article'"
else
    fail "AC7 — missing default commit message"
fi

# --- AC8: Message personnalisé ---
echo ""
echo "--- AC8: Message commit personnalisé ---"

if grep -q 'Trim()' "$SCRIPT" 2>/dev/null; then
    ok "AC8 — trims user input"
else
    fail "AC8 — missing Trim on user input"
fi

if grep -q 'PlaceholderText' "$SCRIPT" 2>/dev/null; then
    ok "AC8 — PlaceholderText set on TextBox"
else
    fail "AC8 — missing PlaceholderText"
fi

# --- AC9: Répertoire de travail = $env:USERPROFILE\togo-blog-content ---
echo ""
echo "--- AC9: Répertoire de travail ---"

if grep -q 'USERPROFILE' "$SCRIPT" 2>/dev/null; then
    ok "AC9 — references USERPROFILE"
else
    fail "AC9 — missing USERPROFILE"
fi

if grep -q 'togo-blog-content' "$SCRIPT" 2>/dev/null; then
    ok "AC9 — references togo-blog-content"
else
    fail "AC9 — missing togo-blog-content"
fi

if grep -q 'Set-Location' "$SCRIPT" 2>/dev/null; then
    ok "AC9 — Set-Location to content dir"
else
    fail "AC9 — missing Set-Location"
fi

if grep -q 'Test-Path' "$SCRIPT" 2>/dev/null; then
    ok "AC9 — Test-Path validates dir existence"
else
    fail "AC9 — missing Test-Path validation"
fi

# --- DoD: Structure et qualité ---
echo ""
echo "--- DoD: Structure et qualité ---"

if grep -q 'Add_Click' "$SCRIPT" 2>/dev/null; then
    ok "DoD — button click handler registered"
else
    fail "DoD — missing button click handler"
fi

if grep -q 'Enabled.*false\|Enabled = \$false' "$SCRIPT" 2>/dev/null; then
    ok "DoD — button disabled during operation"
else
    fail "DoD — button not disabled during operation"
fi

if grep -q 'catch' "$SCRIPT" 2>/dev/null; then
    ok "DoD — error handling (try/catch) present"
else
    fail "DoD — missing error handling"
fi

if grep -q 'CenterScreen' "$SCRIPT" 2>/dev/null; then
    ok "DoD — window centered on screen"
else
    fail "DoD — window not centered"
fi

if grep -q 'FixedDialog' "$SCRIPT" 2>/dev/null; then
    ok "DoD — fixed dialog (not resizable)"
else
    fail "DoD — missing FixedDialog border style"
fi

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
exit $FAIL
