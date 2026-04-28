# Installation — Guide pour l'autrice

## Ce dont tu as besoin

- Un PC Windows 10 ou 11
- Une connexion Internet (pour l'installation uniquement)

## Étape 1 : Installer Git

Git est un logiciel qui permet de sauvegarder et envoyer tes fichiers automatiquement.

1. Va sur [git-scm.com](https://git-scm.com)
2. Clique sur **"Download for Windows"**
3. Ouvre le fichier téléchargé
4. Clique **Suivant** à chaque écran, puis **Installer**
5. Clique **Terminer**

> *Illustration : page de téléchargement Git for Windows avec le bouton Download entouré*

## Étape 2 : Récupérer le dossier du blog

Cloner, c'est copier le dossier du blog depuis Internet vers ton ordinateur.

1. Ouvre le menu Démarrer et cherche **"Git Bash"**
2. Clique dessus — une fenêtre noire s'ouvre
3. Tape cette commande exactement (tu peux la copier-coller) :

```
git clone https://github.com/vianney-g/togo-blog-content.git
```

4. Attends que ça finisse (quelques secondes)
5. Ferme la fenêtre

> *Illustration : fenêtre Git Bash avec la commande git clone et le résultat*

## Étape 3 : Récupérer les scripts du blog

1. Dans la même fenêtre Git Bash (ou rouvre-la), tape :

```
git clone https://github.com/vianney-g/togo-blog.git
```

2. Attends que ça finisse, puis ferme la fenêtre

> *Illustration : fenêtre Git Bash avec le deuxième clone*

## Étape 4 : Installer le raccourci Publier

1. Ouvre le menu Démarrer et cherche **"PowerShell"**
2. Clique dessus — une fenêtre bleue s'ouvre
3. Tape cette commande :

```
powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\togo-blog\scripts\install-hooks.ps1"
```

4. Un raccourci **"📝 Publier"** apparaît sur ton bureau !
5. Ferme la fenêtre bleue

Le script install-hooks configure aussi le hook de vérification (un contrôle automatique qui protège la vie privée des enfants).

> *Illustration : le raccourci 📝 Publier visible sur le bureau Windows*

## Étape 5 : Configurer Typora (éditeur de texte)

1. Ouvre **Typora** (si tu ne l'as pas, télécharge-le sur [typora.io](https://typora.io))
2. Va dans **Fichier → Préférences**
3. Dans la section **Images**, choisis **"Copier dans le dossier ./static/img/"**
4. Ferme les préférences

> *Illustration : préférences Typora avec le réglage images*

## Étape 6 : Premier test — publier un article

1. Ouvre le dossier `C:\Users\<ton-nom>\togo-blog-content\content\posts\`
2. Copie un fichier existant et renomme-le
3. Ouvre-le avec Typora, modifie le titre et écris quelques lignes
4. Sauvegarde (Ctrl+S)
5. Double-clic sur **"📝 Publier"** sur ton bureau
6. La fenêtre de publication s'ouvre — clique sur **Publier**
7. Tu devrais voir : **"✅ Article publié !"**

> *Illustration : fenêtre de publication avec le message de succès*

## Dépannage

### "❌ Prénom réel détecté"

→ Tu as écrit un vrai prénom d'enfant dans l'article. Remplace-le par son pseudonyme, sauvegarde, et réessaie.

### "⚠️ Le push a échoué"

→ Pas de connexion Internet ? Pas grave ! L'article est sauvegardé sur ton ordinateur. Réessaie plus tard en double-cliquant à nouveau sur 📝 Publier.

### "Le raccourci ne marche plus"

→ Relance l'étape 4 (la commande PowerShell). Le raccourci sera recréé.

### "Je ne trouve plus mes articles"

→ Ils sont dans le dossier : `C:\Users\<ton-nom>\togo-blog-content\content\posts\`

### "Aucune modification détectée"

→ Tu n'as pas sauvegardé ton article dans Typora. Fais Ctrl+S puis réessaie.

### "Git Bash ne s'ouvre pas"

→ Git n'est pas installé. Reprends l'étape 1.
