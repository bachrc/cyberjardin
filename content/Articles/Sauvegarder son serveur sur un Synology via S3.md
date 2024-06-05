---
draft: true
---
# Qu'allons-nous faire aujourd'hui
## Le contexte du souci
J'ai un petit Raspberry Pi chez moi que j'apprécie beaucoup. Il consomme peu, et il est très performant pour peu que l'on se soucie d'utiliser des technologies peu consommatrices. J'y héberge quelques outils : Un Vaultwarden, un Authelia, un Gotosocial, un Paperless... Et il ne bronche absolument pas. J'ai tout à la maison, c'est très chouette.

## Un des dangers du self-host: la sauvegarde
Le revers de la médaille quand on héberge soi-même, c'est la sécurité des données. C'est attirant d'avoir tout sur son petit PC, mais le jour où votre Micro-SD saute, vous n'aurez plus que vos yeux pour pleurer. 

> "Zut, j'aurais du sauvegarder ^^ pardon maman la micro-sd a lâché y'a plus de gestionnaire de mot de passe (....) oui tu peux plus accéder à ta banque ni à Ameli, oups xD"
> 
> _Vous, décevant à nouveau vos parents, deux ans après avoir poussé l'utilisation d'un gestionnaire de mots de passe_

La réflexion sur le système de sauvegarde des données doit se faire dès le départ. Mais comment faire ? 

Pour ma part, j'ai un Synology depuis 5 ans chez moi, mais je ne l'utilise que pour stocker des photos et des fichiers. Il ne sert qu'au stockage, car la sécurité des données, c'est vraiment **la dernière chose avec laquelle vous souhaitez bidouiller. Vraiment.** Un petit serveur pour les applications, et autre chose qui ne se charge que des données.

## Exploration des possibilités d'interface avec un NAS Synology
Contrairement à ce qu'on pourrait penser, ce n'est pas si simple, même via un réseau local, de se connecter au Synology pour y envoyer des données ! C'est même foutrement chiant. Mais voici les possibilités sur lesquelles je me suis cassé les dents. (ne regardez pas le titre de l'article, vous vous divulgâcherez la suite)

### Via L'API de Synology DSM
Très rapidement : très mal documenté, peu de librairies proposées, et l'utilisation de Synology Drive ne convient pas à de la sauvegarde de données.

### Outil de sauvegarde via Docker
Synology dispose d'un paquet officiel appelé `Container Manager`, il permet de lancer des conteneurs dans une interface qui est assez chouette à utiliser. On peut y spécifier des conteneurs à lancer, des fichiers docker compose sur lesquels se baser... 

Sauf qu'il y a plusieurs problèmes avec cette approche :
- La solution de sauvegarde va beaucoup interagir avec le système de fichiers, et la sur-couche de Docker peut beaucoup altérer les performances
- La configuration du conteneur afin de le lier aux dossiers à sauvegarder de l'hôte peut être très compliquée, voire impossible

Cela fait trop de déconvenues. On veut quelque chose de natif.

### Monter un dossier virtuel en réseau local avec SMB/NFS
Ca me semble être la solution la plus simple à vrai dire. Dans l'idée, sur notre petit serveur, nous n'aurions qu'à créer un dossier virtuel qui accèderait directement à un dossier du Synology ! On crée un utilisateur spécifique sur le Synology, on configure tout et basta. Que l'interface soit avec SMB (protocole de dossiers partagés de Windows) ou via NFS, Synology les prends en compte. 

Sauf que chez moi, bah ça marche pas.

Cela a été ma solution pendant longtemps, mais j'ai toujours eu des soucis avec elle. Via NFS ou SMB, au bout de quelques jours... l'interface réseau de mon Raspberry Pi crashe. Impossible pour moi de le recontacter. Le redémarrer débloque les choses, mais au bout de quelques jours : rebelote. Et aucun log. Et pourtant ma config `fstab` est très très simple !

J'ai vu quelques personnes avoir des soucis similaires avec le Raspberry Pi, mais aucune solution. C'aurait été une très bonne solution, et même si ce n'est pas la plus optimale, si vous arrivez à la faire fonctionner vous pouvez directement sauter à [[Sauvegarder son serveur sur un Synology via S3#Mettre en place la sauvegarde du serveur|la mise en place de la sauvegarde sur le serveur]] en spécifiant votre dossier réseau comme destination !

Dans notre cas, nous allons nous pencher vers une autre solution, plus adaptée à notre cas d'usage.

### Une interface S3 sur Synology
S3 est un service de stockage de fichiers dont le protocole a inspiré beaucoup d'alternatives. Aujourd'hui beaucoup de services utilisent le protocole de S3 mais avec d'autres solutions, comme Minio ou Garage. Beaucoup d'applications sont compatible avec S3 comme backend de stockage de fichiers, et beaucoup de solutions de sauvegarde également, ça se présente comme être une solution parfaite ! Je voudrais donc sauvegarder mon petit serveur sur mon Synology via S3.

Synology propose actuellement un service appelé [C2 Object Storage](https://c2.synology.com/en-global/object-storage/overview), qui permet d'utiliser une interface S3 sur son NAS. Cependant, cette dernière est payante, et n'est disponible que pour les professionnels. Nul. On va faire autrement.

Synology propose également un gestionnaire de paquets, avec la possibilité d'ajouter des dépôts communautaires comme celui de la [SynoCommunity](https://synocommunity.com/). Pas de chance, aucune solution n'y est disponible pour ajouter une interface S3.

Pas possible d'activer l'interface S3 via Synology, pas possible d'installer un serveur compatible S3 via le gestionnaire de paquets... la seule solution, ~~la manifestation~~ c'est d'en déployer un nous même.

# La solution
On peut se connecter en SSH à notre serveur Synology. Et là où il y a un shell, il y a de l'espoir : nous allons mettre en place nous même sur le serveur Synology un serveur compatible S3, et ensuite sauvegarder notre serveur vers le Synology via S3.

Deux étapes afin d'y parvenir :
- Mise en place de [[Garage]] sur notre Synology, afin de rendre la sauvegarde possible
- Mise en place de `restic`, via [[Autorestic]], afin de faire des sauvegardes incrémentales de notre serveur.

# Ajouter un serveur S3 sur notre Synology

Afin d'avoir une expérience de maintenance plus sympa sur notre NAS, nous allons utiliser d'autres outils :
- Un multiplexeur de terminal : [[Zellij]].
	- Il va nous permettre de lancer en tâche de fond notre serveur garage et d'observer plus facilement nos logs
	- Vous pouvez également télécharger et utiliser le très connu `tmux` qui fonctionne sur les mêmes principes
	- Si vous voulez aller plus loin, je vous invite à créer votre propre service qui se charge de lancer garage en tâche de fond. Ce qui permettra à Garage de se lancer même au démarrage du NAS. Si cela m'est demandé, je peux mettre à jour l'article
- Un gestionnaire de commandes : `just`
	- `just` est un outil se rapprochant de `make`, mais se voulant plus accessible et plus lisible.
	- Il va nous permettre de consigner des commandes utiles et récurrentes, et de ne pas avoir à chercher des heures dans l'historique de notre bash parce qu'on a oublié comment on crée un bucket

Sauf que Synology ne possède pas de gestionnaire de paquets accessible depuis le shell. Nous allons télécharger tous ces binaires nous même et les utiliser. En avant.

> [!note] Note importante pour la suite
> Cet article vous propose **une** manière de procéder, et non **la** manière de procéder. Vous n'êtes pas obligé•e d'utiliser tous les outils listés, vous pouvez utiliser d'autres solutions afin de sécuriser votre ~~habitat~~ serveur. 
> 

## Création d'un dossier partagé
Tout d'abord, je vous invite à créer, via l'interface de votre Synology, un dossier partagé qui sera dédié au stockage géré par Garage. 

Libre à vous de choisir les facteurs qui vous sont importants, comme la réplication du volume (la réplication est fortement recommandée), vous pouvez également créer un utilisateur Synology qui n'a comme droit que la lecture et écriture sur ce dossier partagé (également fortement recommandé)

Par la suite, nous partirons du principe que votre utilisateur s'appelle `michelle`, que votre dossier partagé s'appelle `garage`, et que vous l'avez situé sur le premier volume de votre Synology `volume1`. Le chemin dans le système de fichiers jusqu'à la racine de votre dossier partagé sera donc `/volume1/garage`. 

La version utilisée de Synology DSM est la dernière à ce jour, soit `DSM 7.2-64570`.

## Configuration de notre shell sur le NAS
### Activation du SSH
Dans votre interface Synology, rendez-vous sur le panel suivant :

`Panneau de configuration => Terminal & SNMP`

Vous pouvez cocher `Activer le service SSH`, et appliquer vos changements.
![[Pasted image 20240605125147.png|Capture d'écran de l'interface utilisateur de Terminal & SNMP, la case Activer le service SSH est cochée]]

### Découverte de l'IP de votre serveur
Rendez-vous dans l'interface suivante :

`Panneau de configuration => Réseau => Interface réseau`

Et récupérez votre adresse IP de cette manière. Nous allons l'utiliser afin de nous connecter au serveur.

### Connexion en SSH au Synology
Tout est prêt, rentrez la commande suivante dans un terminal de votre choix:

```sh title="Terminal de votre ordinateur"
ssh michelle@<votre-adresse-ip>

# Le mot de passe de votre utilisateur Synology vous est ensuite demandé
```

Vous êtes désormais connecté•e sur votre serveur, il est maintenant l'heure de télécharger les outils nécessaires.

### Téléchargement des outils nécessaires
Comme spécifié plus haut, nous allons télécharger et utiliser `garage`, `zellij` et `just`. Ces outils sont disponibles sous forme de binaires, que nous allons télécharger et extraire vers un dossier `~/.local/bin`, que nous ajouterons au `$PATH` afin de l'utiliser partout.

```bash title="Shell sur votre Synology via SSH"
# Créons le dossier de destination 
mkdir -p ~/.local/bin

# Créons des dossiers temporaires de téléchargement
mkdir -p ~/tmp/{zellij,just,archives}

# Dirigeons nous dans un dossier temporaire pour télécharger tranquillement nos archives
cd ~/tmp/archives

# Téléchargement de la dernière version de Zellij et extraction vers le bon dossier
wget https://github.com/zellij-org/zellij/releases/latest/download/zellij-x86_64-unknown-linux-musl.tar.gz
tar -xvf zellij*.tar.gz -C ~/tmp/zellij
cp ~/tmp/zellij/zellij ~/.local/bin/zellij

# Téléchargement de la version 1.27.0 de Just
wget https://github.com/casey/just/releases/download/1.27.0/just-1.27.0-x86_64-unknown-linux-musl.tar.gz

tar -xvf just*.tar.gz -C ~/tmp/just
cp ~/tmp/just/just ~/.local/bin/just

# Téléchargement de la version 1.0.0 de garage
wget https://garagehq.deuxfleurs.fr/_releases/v1.0.0/x86_64-unknown-linux-musl/garage -O ~/.local/bin

# Nettoyons tout notre bazar
cd ~
rm -rf ~/tmp
```

A ce niveau là, notre dossier `~/.local/bin` contient trois binaires : `zellij`, `just` et `garage`. 

### Mise à disposition des binaires
Afin de pouvoir y accéder depuis n'importe quel dossier dans le NAS, nous devons ajouter le chemin `~/.local/bin` dans la variable d'environnement `$PATH` de notre shell. Nous allons éditer le fichier `~/.profile` afin de le rajouter avec `vi` :

```bash
vi ~/.profile
```

> [!warn] 
> Pour cela, on va utiliser un logiciel que beaucoup redoutent : `vi`. C'est un éditeur de texte dans un terminal qui est intimidant à aborder, où il existe [beaucoup de tutoriels](https://www.linuxtricks.fr/wiki/guide-de-sur-vi-utilisation-de-vi) afin de se familiariser avec. 
> Très résumé : appuyez sur `i` pour rentrer en mode "Insertion", entrez ce que vous avez à entrer. Une fois que vous avez fini, appuyez sur "Echap" pour sortir du mode "Insertion", et rentrez les caractères suivants : `:wq` pour sauvegarder votre fichier, et quitter `vi`. 
> (oui c'est périlleux mais c'est le seul éditeur de texte dispo sur Synology..)

Ajoutez la ligne suivante à la fin de votre fichier `.profile` 

```sh title="~/.profile"
export PATH="$PATH:$HOME/.local/bin"
```

A partir de là, vous pouvez faire la commande suivante pour charger vos modifications dans votre shell actuel :

```sh
source ~/.profile
```

C'est tout bon ! Nos outils sont désormais accessibles n'importe où dans notre serveur.

### Configuration de Zellij
Comme spécifié auparavant, l'utilisation d'un multiplexeur est facultative. Surtout [[Zellij]] que j'utilise ici pour sa simplicité et son ergonomie, et ici comme solution de facilité afin de le faire tourner en tâche de fond même après ma déconnexion. 

Vous pouvez désormais lancer Zellij en utilisant la commande suivante :
```sh
zellij
```
Et d'un coup boum, une étrange interface en terminal apparait.

![[Zellij#Description]]

Vous pouvez désormais agencer votre terminal comme vous le souhaitez. Et si vous souhaitez faire en sorte que [[Zellij]] se lance automatiquement lors de votre connexion SSH sur le NAS, [[Zellij#Démarrage auto lors d'une connexion SSH|j'ai consigné ici comment le paramétrer]].

## Démarrer Garage
### Configuration du logiciel
![[Garage#Démarrage Rapide]]]


```
- Se connecter à Synology en SSH avec vos identifiants
- Télécharger les utilitaires nécessaires, étant donné que les gestionnaires de paquets ne sont pas disponibles
	- Télécharger les binaires de zellij, just et garage dans `~/.local/bin`
	- Mettre ce chemin dans le path via le `.profile`
- Créer un dossier partagé via l'interface, avec les paramètres de réplication que vous souhaitez
- Aller dans le dossier partagé (ex: `/volume1/garage`) et y créer
	- Un dossier vide data
	- Un dossier vide conf
	- Un fichier texte nommé `justfile`
- Suivre les instructions du quickstart de garage : https://garagehq.deuxfleurs.fr/documentation/quick-start/
- Création du justfile pour ne pas oublier les commandes
- Y joindre les commandes pour créer les clés etc. 
```

# Mettre en place la sauvegarde du serveur
```
- Sur le serveur, y installer autorestic
- Remplir le YAML
- Faire un `.autorestic.env` qui contient les données sensibles
- Faire un autorestic check voir si c'est ok
- Faire un autorestic backup pour s'assurer que tout est ok
- Mettre en place la cron qui va taper sur `autorestic cron` pour lancer le backup
```
# La voie est sécurisée !
```
- Le serveur sera backup tout seul comme un grand
- La prochaine fois, je montrerai comment j'organise mon raspi à base de `compose.yaml` imbriqués
```