# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

**Too Good Togo !** — a Hugo static blog documenting a family's year in Sokodé, Togo (2026). French-language. Theme: `hugo-paper` (git submodule). Deployed to GitHub Pages at https://toogoodtogo.blog/.

## Two-repo split (important)

This repo (`togo-blog`) holds **code only**: theme, layouts, config, CI/CD, scripts, schema, tests. The editorial content (article Markdown + images) lives in a **separate private repo** `togo-blog-content` (expected at `../togo-blog-content` locally).

- `content/` and `static/` here are populated by *copying* from the content repo — they are mostly `.gitkeep` placeholders in git. The `Makefile` `sync` target copies `../togo-blog-content/content/*` and `static/*` in.
- In CI, the content repo is checked out separately (using `CONTENT_READ_PAT`) and merged before the Hugo build.
- Deploys are triggered by a `repository_dispatch` (`content-updated`) fired from the content repo's own workflow, plus pushes to `main` (theme/config changes).

So: editing an article is a content-repo task; editing layout/theme/build is a this-repo task.

## Commands

```bash
make serve        # sync content from ../togo-blog-content, then `hugo server -D`
make build        # sync + `hugo --minify --gc` (production build into public/)
make sync         # copy content + static from the content repo
make clean        # wipe public/, resources/, and synced content/static

hugo server -D    # preview directly (drafts included) without syncing

# Tests — each is a standalone bash script, run individually:
bash tests/test-hooks.sh              # pre-commit + CI name-scan behavior
bash tests/test-schema.sh             # frontmatter JSON schema validation
bash tests/test-story-<N>.sh          # per-story acceptance tests

# Validation scripts (used by hooks/CI, runnable manually):
bash scripts/validate-frontmatter.sh [dir] [schema]   # needs `check-jsonschema` (pipx install check-jsonschema)
bash scripts/scan-names-ci.sh [dir]                   # scan all text files for real first names
```

Hugo version pinned in CI: **0.120.4 extended**. There is no `package.json` / Node toolchain.

## Pseudonymization — the load-bearing safety system

The family's 6 real first names **must never appear** anywhere in committed text (this very file included — do not list them here, the hook scans `.md` too). This is enforced at two layers that share an identical `FORBIDDEN` regex:

- `.githooks/pre-commit` — scans staged `.md/.yaml/.yml/.toml/.txt/.json`, blocks the commit (git is configured with `core.hooksPath=.githooks`).
- `scripts/scan-names-ci.sh` — scans the *entire* repo in CI as a second net.

The canonical name list is the `FORBIDDEN=` line in those two scripts. **If you change it, update it in BOTH files.** The hook excludes `_bmad-output/` (internal planning docs that legitimately contain names) and ignores GitHub refs / the `vianney-g` username. Authors are referred to by pen names (`monsieur`, `madame`, `plume`) — see `content/auteurs/`.

## Frontmatter contract

Articles are validated against `schemas/frontmatter.schema.json` (JSON Schema draft-07, `additionalProperties: false`). Required: `title` (≤120 chars), `date` (YYYY-MM-DD), `author` (pen name), `draft` (bool). Optional: `description` (≤200), `tags[]`, `authors[]` (Hugo taxonomy slug matching `content/auteurs/`), `instagram_image` (must match `^img/.*\.(jpg|jpeg|png|webp)$`). New articles start from `archetypes/default.md`. Adding a frontmatter field means editing the schema *and* the archetype.

## Auto-notification pipeline (CI, on publish)

When an article goes live, the content-repo workflow detects it and emails subscribers:

1. `scripts/detect-new-articles.sh` — finds newly-added `draft: false` posts, or posts flipped `draft: true → false`, by diffing `HEAD~1`.
2. `scripts/extract-metadata.sh <file>` — parses frontmatter into shell vars (`TITLE`, `DESCRIPTION`, `URL`, `INSTAGRAM_IMAGE`, …) via `eval "$(...)"`.
3. `scripts/notify-email.sh <title> <desc> <url>` — posts to the Buttondown API (`BUTTONDOWN_API_KEY`); CI runs it `continue-on-error`.

## Layout / theme overrides

`layouts/` overrides the Paper submodule theme — never edit files inside `themes/hugo-paper/` (it's a submodule). Custom partials live in `layouts/partials/` (e.g. French date formatting `date-fr.html`, `month-year-fr.html`), shortcodes in `layouts/shortcodes/` (`callout`, `figure`, `youtube`), and `_default/_markup/render-image.html` hooks image rendering. Styling is CSS-token based (`assets/css`, `--color-*` tokens) — the Asagi-Usuzumi palette; config does **not** set theme colors.

## Publishing for non-technical authors

`scripts/publier.ps1` is a Windows PowerShell GUI (double-click → commit/push the content repo). Author setup is documented in `docs/SETUP-*.md`. `docs/EDITORIAL-GUIDELINES.md` holds the editorial charter.

## Notes

- Config is `config.yaml` (not the default `hugo.toml`). Permalinks: `/:year/:month/:slug/`. French typographer quotes (`«&nbsp;…&nbsp;»`) are enabled; `goldmark.renderer.unsafe: false` (no raw HTML in Markdown).
- `_bmad/` and `_bmad-output/` are BMAD planning/story artifacts — not site content. The `test-story-*.sh` names map to those stories.
