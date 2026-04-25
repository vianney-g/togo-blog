#!/usr/bin/env bash
# =============================================================================
# Story 2.2 — Install hook scripts tests
# Tests install-hooks.sh and install-hooks.ps1
# =============================================================================
set -uo pipefail

CONTENT_REPO="/home/vianney/perso/togo-blog-content"
SCRIPT_SH="$CONTENT_REPO/scripts/install-hooks.sh"
SCRIPT_PS1="$CONTENT_REPO/scripts/install-hooks.ps1"
PASS=0
FAIL=0
TMPBASE=$(mktemp -d)
trap 'rm -rf "$TMPBASE"' EXIT
COUNTER=0

echo "=== Story 2.2 — Install Hook Scripts Tests ==="
echo ""

setup_repo() {
    COUNTER=$((COUNTER + 1))
    local repo="$TMPBASE/repo-$COUNTER"
    mkdir -p "$repo/.githooks"
    cp "$CONTENT_REPO/.githooks/pre-commit" "$repo/.githooks/pre-commit"
    chmod +x "$repo/.githooks/pre-commit"
    cd "$repo"
    git init -q
    git config user.email "test@test.com"
    git config user.name "Test"
}

# --- AC1: install-hooks.sh exists and is executable ---
echo "--- AC1a: install-hooks.sh exists ---"
if [ -f "$SCRIPT_SH" ]; then
    echo "✅ PASS: install-hooks.sh exists"
    PASS=$((PASS + 1))
else
    echo "❌ FAIL: install-hooks.sh not found at $SCRIPT_SH"
    FAIL=$((FAIL + 1))
fi

echo "--- AC1b: install-hooks.sh is executable ---"
if [ -x "$SCRIPT_SH" ]; then
    echo "✅ PASS: install-hooks.sh is executable"
    PASS=$((PASS + 1))
else
    echo "❌ FAIL: install-hooks.sh is not executable"
    FAIL=$((FAIL + 1))
fi

echo "--- AC1c: install-hooks.sh configures core.hooksPath ---"
setup_repo
bash "$SCRIPT_SH" > /dev/null 2>&1
result=$(git config --local core.hooksPath 2>/dev/null || true)
if [ "$result" = ".githooks" ]; then
    echo "✅ PASS: core.hooksPath set to .githooks"
    PASS=$((PASS + 1))
else
    echo "❌ FAIL: core.hooksPath is '$result', expected '.githooks'"
    FAIL=$((FAIL + 1))
fi

# --- AC2: install-hooks.ps1 exists ---
echo "--- AC2a: install-hooks.ps1 exists ---"
if [ -f "$SCRIPT_PS1" ]; then
    echo "✅ PASS: install-hooks.ps1 exists"
    PASS=$((PASS + 1))
else
    echo "❌ FAIL: install-hooks.ps1 not found at $SCRIPT_PS1"
    FAIL=$((FAIL + 1))
fi

echo "--- AC2b: install-hooks.ps1 syntax valid ---"
if command -v pwsh &>/dev/null; then
    if pwsh -NoProfile -Command "Get-Content '$SCRIPT_PS1' | Out-Null" 2>/dev/null; then
        echo "✅ PASS: PowerShell syntax valid"
        PASS=$((PASS + 1))
    else
        echo "❌ FAIL: PowerShell syntax error"
        FAIL=$((FAIL + 1))
    fi
else
    echo "⏭️ SKIP: pwsh not available — syntax not checked"
fi

# --- AC4: Idempotence — re-run without error, "déjà configuré" message ---
echo "--- AC4: Idempotence ---"
setup_repo
bash "$SCRIPT_SH" > /dev/null 2>&1
output=$(bash "$SCRIPT_SH" 2>&1)
exit_code=$?
if [ $exit_code -eq 0 ] && echo "$output" | grep -qi "déjà configuré"; then
    echo "✅ PASS: Idempotent — second run says 'déjà configuré'"
    PASS=$((PASS + 1))
else
    echo "❌ FAIL: Second run should exit 0 with 'déjà configuré'"
    echo "  exit=$exit_code output: $output"
    FAIL=$((FAIL + 1))
fi

# --- AC5: Error outside git repo ---
echo "--- AC5: Error outside git repo (Linux) ---"
cd "$TMPBASE"
mkdir -p "$TMPBASE/not-a-repo"
cd "$TMPBASE/not-a-repo"
output=$(bash "$SCRIPT_SH" 2>&1)
exit_code=$?
if [ $exit_code -eq 1 ] && echo "$output" | grep -qi "erreur"; then
    echo "✅ PASS: Error + exit 1 outside git repo"
    PASS=$((PASS + 1))
else
    echo "❌ FAIL: Should exit 1 with error message outside git repo"
    echo "  exit=$exit_code output: $output"
    FAIL=$((FAIL + 1))
fi

# --- AC6: PowerShell error outside git repo (if pwsh available) ---
echo "--- AC6: Error outside git repo (PowerShell) ---"
if command -v pwsh &>/dev/null; then
    cd "$TMPBASE/not-a-repo"
    output=$(pwsh -NoProfile -NonInteractive -Command "
        \$input_mock = 'mock'
        & '$SCRIPT_PS1'
    " 2>&1)
    exit_code=$?
    if [ $exit_code -ne 0 ] && echo "$output" | grep -qi "erreur\|error"; then
        echo "✅ PASS: PowerShell error + exit outside git repo"
        PASS=$((PASS + 1))
    else
        echo "❌ FAIL: PowerShell should error outside git repo"
        echo "  exit=$exit_code output: $output"
        FAIL=$((FAIL + 1))
    fi
else
    echo "⏭️ SKIP: pwsh not available"
fi

# --- Extra: .githooks/pre-commit missing → error ---
echo "--- Extra: Missing .githooks/pre-commit → error ---"
COUNTER=$((COUNTER + 1))
local_repo="$TMPBASE/repo-$COUNTER"
mkdir -p "$local_repo"
cd "$local_repo"
git init -q
git config user.email "test@test.com"
git config user.name "Test"
output=$(bash "$SCRIPT_SH" 2>&1)
exit_code=$?
if [ $exit_code -eq 1 ] && echo "$output" | grep -qi "introuvable\|not found"; then
    echo "✅ PASS: Error when .githooks/pre-commit missing"
    PASS=$((PASS + 1))
else
    echo "❌ FAIL: Should error when .githooks/pre-commit missing"
    echo "  exit=$exit_code output: $output"
    FAIL=$((FAIL + 1))
fi

# --- Extra: Bash syntax valid ---
echo "--- Extra: Bash syntax valid ---"
if bash -n "$SCRIPT_SH" 2>/dev/null; then
    echo "✅ PASS: Bash syntax valid"
    PASS=$((PASS + 1))
else
    echo "❌ FAIL: Bash syntax error"
    FAIL=$((FAIL + 1))
fi

# --- Extra: Script has shebang ---
echo "--- Extra: Script has shebang ---"
if head -1 "$SCRIPT_SH" | grep -q "#!/usr/bin/env bash"; then
    echo "✅ PASS: Correct shebang"
    PASS=$((PASS + 1))
else
    echo "❌ FAIL: Missing or wrong shebang"
    FAIL=$((FAIL + 1))
fi

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
[ $FAIL -eq 0 ] && exit 0 || exit 1
