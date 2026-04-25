# Makefile — raccourcis développement local

.PHONY: serve build clean sync

# Synchroniser le contenu depuis le repo content
sync:
	cp -r ../togo-blog-content/content/* content/ 2>/dev/null || true
	cp -r ../togo-blog-content/static/* static/ 2>/dev/null || true

# Serveur de dev avec contenu synchronisé
serve: sync
	hugo server -D

# Build production
build: sync
	hugo --minify --gc

# Nettoyer les artefacts
clean:
	rm -rf public/ resources/
	find content/ -mindepth 1 -not -path 'content/.gitkeep' -depth -delete 2>/dev/null || true
	find static/img/ -mindepth 1 -depth -delete 2>/dev/null || true
