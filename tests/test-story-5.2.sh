#!/usr/bin/env bash
# =============================================================================
# Story 5.2 — Typographie auto-hébergée (EB Garamond + Inter)
# =============================================================================
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

ok()   { echo "✅ PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "❌ FAIL: $1"; FAIL=$((FAIL + 1)); }

TYPO="$ROOT/assets/css/typography.css"
FONTS_DIR="$ROOT/static/fonts"

echo "=== Story 5.2 — Typographie auto-hébergée Tests ==="
echo ""

# --- AC1: EB Garamond for body text and headings ---
echo "--- AC1: EB Garamond for body + headings ---"
if [ -f "$TYPO" ]; then
    if grep -q "font-family:.*'EB Garamond'" "$TYPO" &&
       grep -q "font-family: var(--font-serif)" "$TYPO"; then
        ok "AC1 — EB Garamond used for body and headings"
    else
        fail "AC1 — EB Garamond not applied to body/headings"
    fi
else
    fail "AC1 — typography.css does not exist"
fi

# --- AC2: Inter for metadata, dates, navigation ---
echo "--- AC2: Inter for meta/nav ---"
if [ -f "$TYPO" ]; then
    if grep -q "font-family:.*'Inter'" "$TYPO" &&
       grep -q "font-family: var(--font-sans)" "$TYPO" &&
       grep -q 'nav,' "$TYPO" &&
       grep -q 'footer' "$TYPO"; then
        ok "AC2 — Inter used for nav, meta, dates, footer"
    else
        fail "AC2 — Inter not applied to nav/meta/footer"
    fi
else
    fail "AC2 — typography.css does not exist"
fi

# --- AC3: WOFF2 files self-hosted in static/fonts/ ---
echo "--- AC3: WOFF2 self-hosted ---"
if [ -d "$FONTS_DIR" ]; then
    WOFF2_COUNT=$(find "$FONTS_DIR" -name '*.woff2' | wc -l)
    if [ "$WOFF2_COUNT" -eq 5 ]; then
        AC3_OK=true
        for f in eb-garamond-v27-latin-regular.woff2 \
                 eb-garamond-v27-latin-italic.woff2 \
                 eb-garamond-v27-latin-500.woff2 \
                 inter-v18-latin-regular.woff2 \
                 inter-v18-latin-500.woff2; do
            if [ ! -f "$FONTS_DIR/$f" ]; then
                fail "AC3 — missing font file: $f"
                AC3_OK=false
            fi
        done
        $AC3_OK && ok "AC3 — all 5 WOFF2 files present in static/fonts/"
    else
        fail "AC3 — expected 5 WOFF2 files, found $WOFF2_COUNT"
    fi
else
    fail "AC3 — static/fonts/ directory does not exist"
fi

# --- AC4: Type scale Perfect Fourth (ratio 1.333) ---
echo "--- AC4: Type scale Perfect Fourth ---"
if [ -f "$TYPO" ]; then
    AC4_OK=true
    for var in text-base text-h1 text-h2 text-h3 text-h4 text-h5 text-h6; do
        if ! grep -q "\-\-${var}:" "$TYPO"; then
            fail "AC4 — --${var} missing"
            AC4_OK=false
        fi
    done
    # Check ratio comment or values
    if ! grep -q '1\.333' "$TYPO"; then
        fail "AC4 — Perfect Fourth ratio 1.333 not referenced"
        AC4_OK=false
    fi
    $AC4_OK && ok "AC4 — type scale Perfect Fourth defined"
else
    fail "AC4 — typography.css does not exist"
fi

# --- AC5: Body text minimum 18px (1.125rem) ---
echo "--- AC5: Body text ≥ 18px ---"
if [ -f "$TYPO" ]; then
    if grep -q '\-\-text-base:.*1\.125rem' "$TYPO"; then
        ok "AC5 — body text base is 1.125rem (18px)"
    else
        fail "AC5 — body text base is not 1.125rem"
    fi
else
    fail "AC5 — typography.css does not exist"
fi

# --- AC6: Line-height 1.7 for body ---
echo "--- AC6: Line-height 1.7 ---"
if [ -f "$TYPO" ]; then
    if grep -q 'line-height:.*1\.7' "$TYPO"; then
        ok "AC6 — line-height 1.7 on body"
    else
        fail "AC6 — line-height 1.7 not found"
    fi
else
    fail "AC6 — typography.css does not exist"
fi

# --- AC7: Column width max-width ~42rem ---
echo "--- AC7: Column width ~42rem ---"
if [ -f "$TYPO" ]; then
    if grep -q 'max-width:.*var(--content-max-width)' "$TYPO"; then
        ok "AC7 — column max-width uses --content-max-width (42rem)"
    else
        fail "AC7 — max-width not using --content-max-width"
    fi
else
    fail "AC7 — typography.css does not exist"
fi

# --- AC8: font-display: swap on all @font-face ---
echo "--- AC8: font-display: swap ---"
if [ -f "$TYPO" ]; then
    FONTFACE_COUNT=$(grep -c '^@font-face' "$TYPO" || true)
    SWAP_COUNT=$(grep -c 'font-display: swap' "$TYPO" || true)
    if [ "$FONTFACE_COUNT" -eq 5 ] && [ "$SWAP_COUNT" -eq 5 ]; then
        ok "AC8 — font-display: swap on all 5 @font-face"
    else
        fail "AC8 — @font-face=$FONTFACE_COUNT, swap=$SWAP_COUNT (expected 5 each)"
    fi
else
    fail "AC8 — typography.css does not exist"
fi

# --- AC9: Fallback Georgia/system-ui ---
echo "--- AC9: Fallback fonts ---"
if [ -f "$TYPO" ]; then
    if grep -q 'Georgia' "$TYPO" && grep -q 'system-ui' "$TYPO"; then
        ok "AC9 — fallback Georgia and system-ui present"
    else
        fail "AC9 — fallback fonts missing"
    fi
else
    fail "AC9 — typography.css does not exist"
fi

# --- DoD: Headings reduced on mobile (<640px) ---
echo "--- DoD: Mobile heading reduction ---"
if [ -f "$TYPO" ]; then
    if grep -q '639px' "$TYPO" || grep -q '640px' "$TYPO"; then
        ok "DoD — mobile heading reduction media query present"
    else
        fail "DoD — mobile heading reduction missing"
    fi
else
    fail "DoD — typography.css does not exist"
fi

# --- DoD: No Google Fonts or external CDN ---
echo "--- DoD: No external font requests ---"
CDN_HITS=$(grep -rn 'fonts.googleapis\|fonts.gstatic\|cdn\.' "$ROOT/assets/css/" "$ROOT/layouts/" "$ROOT/config.yaml" 2>/dev/null || true)
if [ -z "$CDN_HITS" ]; then
    ok "DoD — no Google Fonts or CDN references"
else
    fail "DoD — external font references found: $CDN_HITS"
fi

# --- DoD: No hardcoded hex colors in typography.css ---
echo "--- DoD: No hex colors in typography.css ---"
if [ -f "$TYPO" ]; then
    HEX_HITS=$(grep -n '#[0-9A-Fa-f]\{3,8\}' "$TYPO" || true)
    if [ -z "$HEX_HITS" ]; then
        ok "DoD — no hardcoded hex colors in typography.css"
    else
        fail "DoD — hex colors found in typography.css: $HEX_HITS"
    fi
else
    fail "DoD — typography.css does not exist"
fi

# --- DoD: Hugo build succeeds ---
echo "--- DoD: Hugo build ---"
BUILD_OUTPUT=$(cd "$ROOT" && hugo --minify --gc 2>&1)
BUILD_RC=$?
if [ $BUILD_RC -eq 0 ]; then
    ok "DoD — hugo --minify --gc builds without error"
else
    fail "DoD — hugo build failed: $BUILD_OUTPUT"
fi

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
[ $FAIL -eq 0 ] && exit 0 || exit 1
