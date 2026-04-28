#!/usr/bin/env bash
# =============================================================================
# Story 7.2 — Raccourci bureau Windows (install-hooks.ps1)
# Tests statiques (Windows-only, on vérifie structure + contenu)
# =============================================================================
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

ok()   { echo "  ✅ PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  ❌ FAIL: $1"; FAIL=$((FAIL + 1)); }

SCRIPT="$ROOT/scripts/install-hooks.ps1"

echo "=== Story 7.2 — Raccourci bureau Windows ==="
echo ""

# --- AC1: Nom lisible "📝 Publier" et icône reconnaissable ---
echo "--- AC1: Nom et icône du raccourci ---"

if [ -f "$SCRIPT" ]; then
    ok "AC1 — install-hooks.ps1 exists"
else
    fail "AC1 — install-hooks.ps1 not found"
fi

if grep -q '📝 Publier' "$SCRIPT" 2>/dev/null; then
    ok "AC1 — shortcut name '📝 Publier'"
else
    fail "AC1 — missing shortcut name"
fi

if grep -q 'IconLocation' "$SCRIPT" 2>/dev/null; then
    ok "AC1 — icon configured"
else
    fail "AC1 — missing icon configuration"
fi

if grep -q 'shell32.dll' "$SCRIPT" 2>/dev/null; then
    ok "AC1 — uses shell32.dll icon"
else
    fail "AC1 — missing shell32.dll icon"
fi

# --- AC2: Double-clic lance publier.ps1 avec GUI ---
echo ""
echo "--- AC2: Raccourci lance publier.ps1 ---"

if grep -q 'powershell.exe' "$SCRIPT" 2>/dev/null; then
    ok "AC2 — TargetPath is powershell.exe"
else
    fail "AC2 — missing powershell.exe target"
fi

if grep -q 'ExecutionPolicy Bypass' "$SCRIPT" 2>/dev/null; then
    ok "AC2 — ExecutionPolicy Bypass"
else
    fail "AC2 — missing ExecutionPolicy Bypass"
fi

if grep -q 'WindowStyle Hidden' "$SCRIPT" 2>/dev/null; then
    ok "AC2 — WindowStyle Hidden (hides PS window)"
else
    fail "AC2 — missing WindowStyle Hidden"
fi

if grep -q 'publier.ps1' "$SCRIPT" 2>/dev/null; then
    ok "AC2 — references publier.ps1"
else
    fail "AC2 — missing publier.ps1 reference"
fi

# --- AC3: Pointe vers le bon chemin ---
echo ""
echo "--- AC3: Chemin correct du script ---"

if grep -q 'togo-blog' "$SCRIPT" 2>/dev/null; then
    ok "AC3 — references togo-blog path"
else
    fail "AC3 — missing togo-blog path"
fi

if grep -q 'USERPROFILE' "$SCRIPT" 2>/dev/null; then
    ok "AC3 — uses USERPROFILE for path"
else
    fail "AC3 — missing USERPROFILE"
fi

if grep -q 'WorkingDirectory' "$SCRIPT" 2>/dev/null; then
    ok "AC3 — sets WorkingDirectory"
else
    fail "AC3 — missing WorkingDirectory"
fi

if grep -q 'togo-blog-content' "$SCRIPT" 2>/dev/null; then
    ok "AC3 — WorkingDirectory is togo-blog-content"
else
    fail "AC3 — missing togo-blog-content in WorkingDirectory"
fi

# --- AC4: Idempotent (recréé sans erreur) ---
echo ""
echo "--- AC4: Idempotent ---"

if grep -q 'CreateShortcut' "$SCRIPT" 2>/dev/null; then
    ok "AC4 — uses CreateShortcut (overwrites existing)"
else
    fail "AC4 — missing CreateShortcut"
fi

if grep -q 'WScript.Shell' "$SCRIPT" 2>/dev/null; then
    ok "AC4 — uses WScript.Shell COM object"
else
    fail "AC4 — missing WScript.Shell"
fi

if grep -q '\.Save()' "$SCRIPT" 2>/dev/null; then
    ok "AC4 — calls Save() on shortcut"
else
    fail "AC4 — missing Save()"
fi

# --- DoD: git hooks configuration ---
echo ""
echo "--- DoD: Git hooks configuration ---"

if grep -q 'core.hooksPath' "$SCRIPT" 2>/dev/null; then
    ok "DoD — configures core.hooksPath"
else
    fail "DoD — missing core.hooksPath configuration"
fi

if grep -q '\.githooks' "$SCRIPT" 2>/dev/null; then
    ok "DoD — hooksPath points to .githooks"
else
    fail "DoD — missing .githooks reference"
fi

if grep -q 'Description' "$SCRIPT" 2>/dev/null; then
    ok "DoD — shortcut has Description"
else
    fail "DoD — missing shortcut Description"
fi

if grep -q 'Desktop' "$SCRIPT" 2>/dev/null; then
    ok "DoD — places shortcut on Desktop"
else
    fail "DoD — missing Desktop reference"
fi

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
exit $FAIL
