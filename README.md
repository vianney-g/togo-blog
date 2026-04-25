# Le Togo en famille

Blog statique Hugo documentant l'aventure de la famille à Sokodé (Togo, 2026).

> "Le Togo que l'on a plaisir à lire."

## Structure

| Dossier | Contenu |
|---------|---------|
| `archetypes/` | Templates Hugo pour nouveaux articles |
| `layouts/` | Overrides du thème Paper (partials, shortcodes) |
| `assets/css/` | Palette CSS Asagi-Usuzumi |
| `themes/` | Thème Hugo Paper (submodule) |
| `scripts/` | Script Publier (PowerShell) + scripts d'installation |
| `.githooks/` | Pre-commit hook (pseudonymisation) |
| `.github/workflows/` | CI/CD (build Hugo + deploy GitHub Pages) |
| `schemas/` | JSON Schema front-matter |
| `docs/` | Documentation (setup, charte éditoriale) |
| `tests/` | Fixtures de test (hook, schema) |

## Repos associés

- **Ce repo** (`togo-blog`) : code, thème, CI/CD — le mainteneur seul
- **Repo content** (`togo-blog-content`) : articles Markdown + images — le mainteneur + la co-autrice

## Développement local

```bash
# Cloner avec le thème
git clone --recurse-submodules git@github.com:vianney-xyz/togo-blog.git
cd togo-blog

# Prévisualiser
hugo server -D
```
