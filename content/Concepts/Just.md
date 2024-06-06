# Description
Just est un gestionnaire de commandes. Il aide à centraliser et réutiliser les différentes commandes propres au cycle de vie d'un projet. Le concept est similaire à `make` et ses `Makefile`, mais se veut plus moderne et plus accessible. En y consignant vos commandes importantes, vous n'aurez plus à dégainer en urgence un article sur le net ou d'appuyer une centaine de fois sur la flèche du haut pour parcourir tout votre `bash_history`. 

Les commandes sont généralement consignées dans un fichier nommé `justfile`, qui est un fichier texte se rapprochant du `Makefile`
![[Pasted image 20240605161729.png|Capture d'écran de l'utilisation de Just]]
# Installation
Vous pouvez obtenir l'URL de la dernière release via le lien suivant : https://github.com/casey/just/releases/latest

Copiez l'URL du `.tar.gz` convenant à votre OS et architecture, et utilisez la dans les prochaines commandes.

```sh
# Création du dossier de destination s'il n'existe pas déjà
mkdir -p ~/.local/bin

# Création d'un dossier temporaire pour ne rien salire
mkdir -p ~/tmp/{just,archive}
cd ~/tmp/archive

# Téléchargement de la dernière version de Zellij et extraction vers le bon dossier
wget <url_de_votre_tar_gz>
tar -xvf just*.tar.gz -C ~/tmp/just
cp ~/tmp/just/just ~/.local/bin/just

# Et on nettoie
rm -rf ~/tmp
```

# Liens utiles

| Type          | Lien                          |
| ------------- | ----------------------------- |
| Site internet | https://just.systems/         |
| Documentation | https://just.systems/man/en/  |
| Dépôt Github  | https://github.com/casey/just |
