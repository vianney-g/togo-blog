# Setup — Dev (Linux)

## Prérequis

- Hugo extended >= 0.120 (`hugo version`)
- Git >= 2.x

## Installation rapide

```bash
# 1. Cloner les repos
git clone git@github.com:vianney-g/togo-blog.git
git clone git@github.com:vianney-g/togo-blog-content.git

# 2. Initialiser le submodule thème
cd togo-blog
git submodule update --init --recursive

# 3. Configurer les hooks (repo content)
cd ../togo-blog-content
git config core.hooksPath .githooks
chmod +x .githooks/pre-commit

# 4. Symlink content pour dev local
cd ../togo-blog
ln -sf ../togo-blog-content/content content
ln -sf ../togo-blog-content/static static

# 5. Tester
hugo server -D
```

## Alias utiles

```bash
alias blog='cd ~/togo-blog && hugo server -D'
alias blogc='cd ~/togo-blog-content'
alias blogpush='cd ~/togo-blog-content && git add . && git commit && git push'
```

## Workflow quotidien

1. `blogc` → écrire dans `content/posts/`
2. `git add . && git commit -m "article: titre"` (hook pre-commit s'exécute)
3. `git push`

## Rebuild complet

```bash
cd ~/togo-blog && hugo --minify --gc
```

## Dépannage

- **Submodule vide** : `git submodule update --init --recursive`
- **Hook non exécuté** : `git config core.hooksPath .githooks`
- **Build échoue** : vérifier `hugo version` (>= 0.120 extended)
- **Symlinks cassés** : recréer avec `ln -sf`
