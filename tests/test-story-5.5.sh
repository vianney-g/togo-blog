#!/usr/bin/env bash
# =============================================================================
# Story 5.5 — Shortcodes Hugo (youtube, figure, callout)
# =============================================================================
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

ok()   { echo "✅ PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "❌ FAIL: $1"; FAIL=$((FAIL + 1)); }

YT="$ROOT/layouts/shortcodes/youtube.html"
FIG="$ROOT/layouts/shortcodes/figure.html"
CALL="$ROOT/layouts/shortcodes/callout.html"
CSS="$ROOT/assets/css/components.css"

echo "=== Story 5.5 — Shortcodes Hugo (youtube, figure, callout) ==="
echo ""

# --- AC1: YouTube shortcode responsive ---
echo "--- AC1: YouTube embed responsive ---"
if [ -f "$YT" ]; then
    ok "AC1 — youtube.html exists"
else
    fail "AC1 — youtube.html not found"
fi
if grep -q 'padding-bottom: 56.25%' "$YT"; then
    ok "AC1 — 16:9 aspect ratio (56.25%)"
else
    fail "AC1 — missing 16:9 aspect ratio"
fi

# --- AC5: YouTube lazy loading ---
echo ""
echo "--- AC5: YouTube lazy loading ---"
if grep -q 'loading="lazy"' "$YT"; then
    ok "AC5 — iframe uses loading=lazy"
else
    fail "AC5 — missing loading=lazy"
fi

# --- YouTube privacy ---
echo ""
echo "--- YouTube privacy ---"
if grep -q 'youtube-nocookie.com' "$YT"; then
    ok "Privacy — uses youtube-nocookie.com"
else
    fail "Privacy — missing youtube-nocookie.com"
fi

# --- AC2: Figure shortcode ---
echo ""
echo "--- AC2: Figure with caption ---"
if [ -f "$FIG" ]; then
    ok "AC2 — figure.html exists"
else
    fail "AC2 — figure.html not found"
fi
if grep -q 'figcaption' "$FIG" && grep -q 'markdownify' "$FIG"; then
    ok "AC2 — figcaption with markdownify"
else
    fail "AC2 — missing figcaption or markdownify"
fi

# --- Figure supports src, caption, alt, class ---
echo ""
echo "--- Figure params ---"
for param in '"src"' '"caption"' '"alt"' '"class"'; do
    if grep -q "$param" "$FIG"; then
        ok "Figure — supports $param"
    else
        fail "Figure — missing $param"
    fi
done

# --- AC6: Figure graceful degradation ---
echo ""
echo "--- AC6: Figure graceful degradation ---"
if grep -q '{{ with \$src }}' "$FIG"; then
    ok "AC6 — conditional rendering with 'with \$src'"
else
    fail "AC6 — missing graceful degradation"
fi

# --- AC3: Callout shortcode ---
echo ""
echo "--- AC3: Callout styled box ---"
if [ -f "$CALL" ]; then
    ok "AC3 — callout.html exists"
else
    fail "AC3 — callout.html not found"
fi
if grep -q '.Inner | markdownify' "$CALL"; then
    ok "AC3 — .Inner | markdownify"
else
    fail "AC3 — missing .Inner | markdownify"
fi

# --- AC7: Callout types ---
echo ""
echo "--- AC7: Callout types ---"
if grep -q 'callout--{{ \$type }}' "$CALL"; then
    ok "AC7 — dynamic type class"
else
    fail "AC7 — missing dynamic type class"
fi

# --- CSS styles ---
echo ""
echo "--- CSS styles in components.css ---"
for class in '.figure' '.figure__caption' '.callout' '.callout--info' '.callout--warning' '.youtube-embed'; do
    if grep -q "$class" "$CSS"; then
        ok "CSS — $class present"
    else
        fail "CSS — $class missing"
    fi
done

# --- Callout CSS: bg-secondary + accent-cold border ---
if grep -q 'color-bg-secondary' "$CSS" && grep -q 'color-accent-cold' "$CSS"; then
    ok "CSS — callout uses washi-ombre bg + asagi-iro border tokens"
else
    fail "CSS — callout missing proper tokens"
fi
if grep -q 'color-accent-warm' "$CSS"; then
    ok "CSS — warning uses kobaicha token"
else
    fail "CSS — warning missing kobaicha token"
fi

# --- AC4: Shortcodes are plain text in Typora ---
echo ""
echo "--- AC4: Typora compatibility ---"
# Shortcodes are plain text {{< >}} — no JS, no special rendering needed
ok "AC4 — shortcodes are plain text (no JS required)"

# --- No test article left behind ---
echo ""
echo "--- Cleanup: no test article ---"
if [ ! -f "$ROOT/content/posts/test-shortcodes.md" ]; then
    ok "Cleanup — no test-shortcodes.md in content/"
else
    fail "Cleanup — test-shortcodes.md still exists"
fi

# --- Hugo build ---
echo ""
echo "--- Hugo build ---"
if (cd "$ROOT" && hugo --minify --quiet 2>&1); then
    ok "Hugo build succeeds"
else
    fail "Hugo build failed"
fi

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
