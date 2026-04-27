# Configuration GitHub Pages — Guide pas-a-pas

## Prerequis

- Le workflow `build-deploy.yml` est en place (Story 4.4)
- Le repo `togo-blog` est sur GitHub sous `vianney-g`

## Etapes de configuration

### 1. Activer GitHub Pages

1. Aller sur **https://github.com/vianney-g/togo-blog/settings/pages**
2. Dans **Source**, selectionner **GitHub Actions**
3. Cliquer **Save**

> Ne PAS selectionner "Deploy from a branch". Le workflow utilise `actions/deploy-pages` qui deploie via l'API Pages.

### 2. Verifier Enforce HTTPS

1. Sur la meme page Settings > Pages
2. Cocher **Enforce HTTPS** (devrait etre coche par defaut)

### 3. Declencher le premier deploiement

Le workflow se declenche automatiquement sur push main. Pour forcer :

1. Aller dans **Actions** > **Build & Deploy**
2. Cliquer **Run workflow** > **Run workflow** (branche main)

### 4. Verifier le deploiement

1. Aller dans **Settings > Environments** — `github-pages` doit apparaitre
2. Visiter **https://vianney-g.github.io/togo-blog/**
3. Verifier que le CSS et les images se chargent (pas de 404 dans la console)

## Checklist

- [ ] Settings > Pages > Source = "GitHub Actions"
- [ ] Enforce HTTPS = active
- [ ] Custom domain = vide (MVP)
- [ ] Workflow build-deploy.yml a tourne au moins 1 fois avec succes
- [ ] Environnement github-pages visible dans Settings > Environments
- [ ] URL accessible : https://vianney-g.github.io/togo-blog/
- [ ] baseURL dans config.yaml = `https://vianney-g.github.io/togo-blog/`

## Domaine personnalise (post-MVP)

Quand un domaine custom sera configure :
1. Ajouter `static/CNAME` avec le domaine
2. Configurer le DNS (CNAME vers `vianney-g.github.io`)
3. Mettre a jour `baseURL` dans `config.yaml`
4. Activer Enforce HTTPS
