# CLAUDE.md

Ce fichier fournit des indications à Claude Code (claude.ai/code) pour travailler dans ce dépôt.

## Langue

Ce projet se pense et se discute **en français**. Réponds en français dans ce repo, y compris pour les messages de commit, les commentaires ajoutés et les échanges avec l'utilisateur — sauf demande explicite contraire.

## Le projet

« Too Good Togo ! » — un blog statique Hugo (en français) qui documente le séjour d'une famille à Sokodé, au Togo. Ce dépôt (`togo-blog`) ne contient que le code, le thème et la CI/CD. Le contenu (articles Markdown + images) vit dans un **dépôt séparé**, `togo-blog-content`, et est fusionné au moment du build — il ne fait pas partie de l'historique git de ce dépôt.

## Architecture à deux dépôts

- `togo-blog` (ce dépôt) : le site Hugo — layouts, CSS, config, JSON Schema, workflows CI, scripts de publication/notification.
- `togo-blog-content` (dépôt séparé, absent d'ici) : `content/` (articles) et `static/` (images), plus sa propre copie du hook `.githooks/pre-commit` de filtrage des prénoms (c'est là-bas que ce hook compte vraiment, puisque les prénoms réels pourraient apparaître dans les brouillons d'articles). En local, ce dépôt est cloné dans `../togo-blog-content` (soit `/home/vianney/Work/togo-blog-content`), à côté de ce répertoire.
- En dev local, les deux dépôts sont reliés — voir « Développement local » ci-dessous. En CI, `.github/workflows/build-deploy.yml` checkout les deux dépôts et copie `content-repo/content` et `content-repo/static` dans l'arborescence de ce dépôt avant de builder.
- Le thème (`themes/hugo-paper`, un fork sur `vianney-g/hugo-paper`) est un **submodule git** — cloner/puller avec `--recurse-submodules` ou lancer `git submodule update --init --recursive`, sinon le dossier du thème est vide et le build échoue.

## Développement local

```bash
# Une fois : cloner le dépôt content en dossier voisin, puis depuis togo-blog/ :
git submodule update --init --recursive   # récupère le thème hugo-paper

make serve     # synchronise le contenu depuis ../togo-blog-content, puis `hugo server -D`
make build     # synchronise le contenu, puis `hugo --minify --gc` (build production)
make clean     # supprime public/, resources/, et le contenu/static synchronisés
```

`make sync` copie `../togo-blog-content/{content,static}/*` dans `content/` et `static/` de ce dépôt — il suppose que `togo-blog-content` est cloné en dossier voisin (`../togo-blog-content`), pas en submodule. Lancer `hugo server` directement sans passer par `make sync` servira un contenu périmé ou absent.

## Tests

Les tests sont des scripts bash autonomes dans `tests/`, chacun indépendant et lancé directement — il n'y a pas de runner ni de cible npm/make qui les regroupe :

```bash
bash tests/test-schema.sh          # valide les fixtures contre schemas/frontmatter.schema.json (nécessite check-jsonschema)
bash tests/test-hooks.sh           # teste le hook pre-commit de filtrage des prénoms sur tests/fixtures/hooks/*
bash tests/test-story-*.sh         # tests d'acceptation par story (numérotées comme dans le PRD, ex: 5.3, 7.2)
```

La plupart des tests de story sont des vérifications d'acceptation liées à une story d'implémentation précise, pas des tests unitaires d'une lib partagée — lire le script individuel pour savoir ce qu'il vérifie avant de supposer qu'un changement est couvert.

`scripts/validate-frontmatter.sh [dossier-content] [schema]` fait la même validation de schema mais sur du contenu réel plutôt que sur les fixtures (nécessite `check-jsonschema`, ex : `pipx install check-jsonschema`).

## Modèle de contenu & validation

- Les articles sont des fichiers Markdown avec un front matter YAML validé contre `schemas/frontmatter.schema.json` (`additionalProperties: false` — toute clé de front matter inconnue fait échouer la validation). Requis : `title`, `date`, `author`, `draft`. Optionnel : `description`, `tags`, `authors` (taxonomie Hugo, doit correspondre à un slug sous `content/auteurs/`), `instagram_image` (chemin respectant `^img/.*\.(jpg|jpeg|png|webp)$`, déclenche un post Instagram automatique).
- Les nouveaux articles se créent depuis `archetypes/default.md` (`hugo new posts/...`), qui pré-remplit le front matter requis et des rappels en commentaires.
- Les permaliens suivent le format `/:year/:month/:slug/` (voir `config.yaml`) ; `scripts/extract-metadata.sh` dérive le slug depuis la convention de nommage `YYYY-MM-DD-slug.md` et reconstruit cette URL pour les notifications.

## Protection des prénoms réels (critique pour la vie privée)

Les prénoms réels de la famille (`Vianney|Tiphaine|Jeanne|Jos[eé]phine|Mayeul|Marthe`, dans `.githooks/pre-commit` et `scripts/scan-names-ci.sh`) ne doivent **jamais** apparaître dans du texte commité — les articles utilisent des pseudonymes à la place (voir `docs/EDITORIAL-GUIDELINES.md` — « Monsieur », « Madame », « Plume »). Cela est vérifié à deux niveaux, avec la même regex, tous deux définis dans ce dépôt (mais c'est le hook pre-commit qui compte vraiment au quotidien, dans le dépôt `togo-blog-content`, où il est installé via `git config core.hooksPath .githooks`) :
1. **Hook pre-commit local** (`.githooks/pre-commit`) — scanne les fichiers staged `*.md|*.yaml|*.yml|*.toml|*.txt|*.json`, bloque le commit.
2. **Filet de sécurité CI** (`scripts/scan-names-ci.sh`) — scanne tout l'arbre, pas seulement les fichiers staged.

En cas de modification de l'un ou l'autre script, garder la regex des prénoms interdits et la logique d'exclusion (noms d'utilisateur/URLs GitHub comme `vianney-g`, le dossier de planning `_bmad-output/`) synchronisées entre les deux, et mettre à jour les fixtures de `tests/test-hooks.sh` (`tests/fixtures/hooks/`) en conséquence.

## Chaîne publication → notification

Publier un article dans `togo-blog-content` déclenche un enchaînement (voir `docs/` et les commentaires des scripts qui font référence à « Architecture auto-notification ») :
1. `scripts/detect-new-articles.sh` — compare le commit entrant à `HEAD~1` dans le dépôt content pour trouver les articles nouvellement ajoutés avec `draft: false`, ou passés de `draft: true` à `draft: false`.
2. `scripts/extract-metadata.sh <fichier>` — extrait le front matter de cet article dans des variables shell (`TITLE`, `DESCRIPTION`, `DATE`, `SLUG`, `URL`, `INSTAGRAM_IMAGE`) via `eval "$(...)"`.
3. `scripts/notify-email.sh <title> <description> <url>` — poste un brouillon d'email vers l'API Buttondown (variable d'environnement `BUTTONDOWN_API_KEY` requise). Un code de sortie non nul (clé absente ou réponse API non-2xx) est censé être toléré via `continue-on-error: true` dans le job CI appelant.
4. `.github/workflows/build-deploy.yml` est ce qui build et déploie réellement le site Hugo sur GitHub Pages, déclenché par `repository_dispatch` (`content-updated`, envoyé depuis le dépôt content), un push sur `main` ici, ou un `workflow_dispatch` manuel.

## Structure front-end / thème

- `layouts/` ne contient que des **surcharges** du thème `hugo-paper` (partials, shortcodes, quelques templates de page complets comme `newsletter.html`, `archives.html`, `about.html`) — l'essentiel du comportement du thème vit dans le submodule, pas ici.
- Le CSS est un système de design fait main, « Asagi-Usuzumi » (palette inspirée de l'encre japonaise), pas du Tailwind, empilé indépendamment du pipeline CSS propre au thème :
  - `layouts/partials/head-css.html` concatène `assets/css/{tokens,typography,base,layout,components,dark,print}.css` en un seul `main.css` fingerprinté/minifié en production.
  - `assets/css/tokens.css` est la source unique de vérité pour les couleurs/espacements — ne pas coder de couleurs ou d'espacements en dur ailleurs.
- Le formulaire d'inscription à la newsletter (`layouts/_default/newsletter.html`) poste directement vers un endpoint embed Buttondown côté client ; ça n'a rien à voir avec la notification de publication côté serveur `notify-email.sh`.
