---
tags:
  - dev
  - ops
---
# Description
Zellij est un multiplexeur de terminal écrit en Rust, assimilable à `screen` ou `tmux`, mais se démarque dans son ergonomie, plus accessible que ses pairs.

Zellij nous permet de créer des **sessions**. Chaque session permet de séparer diverses opérations et buts. Lorsque l'on démarre Zellij, nous nous attachons à une seule session.

Dans une session Zellij, il est possible de créer de multiples **onglets** (tabs), et dans chaque onglet, d'organiser plusieurs **tuiles** (pane). Dans un onglet par exemple, il est possible d'agencer plusieurs tuiles côte à côte, afin d'avoir plusieurs terminaux sous les yeux.

Il est possible de s'y déplacer totalement au clavier, mais également d'interagir avec avec la souris.

Après utilisation, il est possible de se détacher d'une session, afin de quitter Zellij tout en gardant la session active en tâche de fond, même après déconnexion du serveur.

![[Pasted image 20240605140414.png|Exemple d'interface Zellij]]

# Examples de commandes
## Raccourcis clavier

| Raccourci  | Effet                                                           |
| ---------- | --------------------------------------------------------------- |
| `Ctrl-P N` | Création d'une nouvelle tuile                                   |
| `Ctrl-T N` | Création d'un nouvel onglet                                     |
| `Alt-➡️`   | Se déplacer vers la tuile de droite                             |
| `Ctrl-O D` | Se détacher de la session (qui restera active en tâche de fond) |
# Installation
Vous pouvez obtenir l'URL de la dernière release via le lien suivant : https://github.com/zellij-org/zellij/releases/latest

Copiez l'URL du `.tar.gz` convenant à votre OS et architecture, et utilisez la dans les prochaines commandes.

```sh
# Création du dossier de destination s'il n'existe pas déjà
mkdir -p ~/.local/bin

# Création d'un dossier temporaire pour ne rien salire
mkdir -p ~/tmp/{zellij,archive}
cd ~/tmp/archive

# Téléchargement de la dernière version de Zellij et extraction vers le bon dossier
wget <url_de_votre_tar_gz>
tar -xvf zellij*.tar.gz -C ~/tmp/zellij
cp ~/tmp/zellij/zellij ~/.local/bin/zellij

# Et on nettoie
rm -rf ~/tmp
```
# Astuces
## Démarrage auto lors d'une connexion SSH
Afin de démarrer Zellij automatiquement, et le faire se rattacher à la dernière session active, éditez le fichier `~/.profile` du serveur en question, et rajoutez les lignes suivantes à la fin du fichier :

```sh title="~/.profile"
if [[ -z "$ZELLIJ" ]]; then
    zellij attach -c

    # La ligne suivante permet de couper la connexion SSH dès que vous vous détachez de la session
    exit
fi
```


# Liens utiles
Site internet du projet : https://zellij.dev
Documentation : https://zellij.dev/documentation/introduction
Dépôt Github : https://github.com/zellij-org/zellij