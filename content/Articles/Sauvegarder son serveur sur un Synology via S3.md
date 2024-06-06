---
tags:
  - tutoriel
  - ops
date: 2024-06-05
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

J'ai vu quelques personnes avoir des soucis similaires avec le Raspberry Pi, mais aucune solution. C'aurait été une très bonne solution, et même si ce n'est pas la plus optimale, si vous arrivez à la faire fonctionner vous pouvez directement sauter à [[#Mettre en place la sauvegarde du serveur|la mise en place de la sauvegarde sur le serveur]] en spécifiant votre dossier réseau comme destination !

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

### Téléchargement de Garage
Synology ne nous facilite pas la tâche, et ne nous permet pas d'utiliser un gestionnaire de paquet pour installer [[Garage]]. Ce n'est pas grave, il est disponible sous forme de binaire, que nous allons télécharger vers un dossier `~/.local/bin`, que nous ajouterons au `$PATH` afin de l'utiliser partout.

![[Garage#Téléchargement]]


### Mise à disposition de l'exécutable
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

C'est tout bon ! Les binaires disponibles dans ce dossier sont désormais accessibles depuis n'importe quel endroit du serveur.
## Démarrer Garage
![[Garage#Démarrage Rapide]]

Vous avez maintenant un bucket compatible S3 sur votre Synology, et un couple de clés prêt à l'emploi afin d'y déverser vos données de sauvegarde !

## Astuces facultatives

### Lancer Garage en tâche de fond avec [[Zellij]]
Actuellement, si vous lancez `garage server`, il sera actif dans votre terminal. Sitôt que vous fermerez votre terminal, [[Garage]] va se couper. Et non, laisser votre terminal constamment ouvert n'est pas une solution. 

Une solution simple, rapide et bête comme chou serait d'utiliser [[Zellij]], un espace de travail dans le terminal qui vous permet d'avoir des onglets, des tuiles ré-organisables à souhait, et qui reste en tâche de fond. Vous pouvez suivre [[Zellij#Installation|ces instructions]] afin de l'installer sur votre Synology si vous le souhaitez.

### Centraliser les commandes utiles avec [[Just]]
Afin de mettre en place [[Garage]], vous avez utilisé beaucoup de commandes afin d'interagir avec votre application. Dans deux semaines, quand vous reviendrez dessus, vous souviendrez-vous de la commande pour rattacher une clé à un bucket ? Si vous venez de me répondre "Oui", vous mentez mal. 

![[Just#Description]]

Si cela vous intéresse, vous pouvez retrouver [[Just#Installation|les instructions d'installation ici]], et retrouver le fichier `Justfile` qui consigne les commandes importantes pour interagir avec [[Garage]] en vous rendant [[Garage#Fichier justfile|sur cette page]]. 

# Mettre en place la sauvegarde du serveur
Nous ne devrions plus toucher à notre Synology pour le moment. Maintenant, il va s'agir de sauvegarder de manière récurrente le contenu de notre serveur.

Autorestic est un logiciel de sauvegarde s'appuyant sur restic. Sa valeur ajoutée, c'est de définir dans un fichier YAML le dossier source à sauvegarder, la destination de la sauvegarde, mais également la fréquence de ces dernières.

>[!info] Pour la suite du tutoriel
>Nous partirons du principe que vous savez comment vous connecter à votre serveur (j'espère), et que le dossier que vous souhaitez sauvegarder se trouve au chemin suivant : `/home/michelle/services`

### Téléchargement d'Autorestic
Sur votre serveur, je vous invite à suivre la [documentation officielle d'autorestic](https://autorestic.vercel.app/installation), et d'utiliser la manière qui convient le plus à votre serveur (la suite de cet article partira du principe que vous n'utilisez pas autorestic via leur image Docker)

### Configuration d'Autorestic
La configuration d'autorestic se situe dans deux fichiers distincts :
- `.autorestic.yml` : le fichier de configuration
- `.autorestic.env` : les variables d'environnement fournies à autorestic, contenant les mots de passe et clés secrètes 
Il est possible de mettre vos clés secrètes directement dans le fichier YAML, mais si vous souhaitez versioner vos fichiers de configuration, c'est très recommandé de séparer les deux, et surtout de ne jamais "commit" votre fichier `.autorestic.env`.

Ces deux fichiers doivent se situer dans le même dossier.

Voici le contenu du fichier `.autorestic.yml` :
```yml title=".autorestic.yml"
version: 2

locations:
  services:
    from: /home/michelle/services
    to: synology
    cron: '0 3 * * *'

backends:
  synology:
    type: s3
    path: 'http://<ip_de_votre_nas>:3900/backup-bucket'
```

Le contenu du fichier est très simple : nous sauvegardons tous les jours à 3 heures du matin le dossier `/home/michelle/services` vers la destination `synology`. `synology`, comme type de destination, c'est un type `s3`, et voici son URL, contenant le bucket de destination.

Il ne nous reste plus qu'à consigner les valeurs secrètes dans le fichier `.autorestic.env`. Vous y renseignerez également votre clé de chiffrement pour ne pas stocker votre sauvegarde en clair sur votre bucket Synology. Malinx le lynx.

```env title=".autorestic.env"
AUTORESTIC_SYNOLOGY_RESTIC_PASSWORD=<mot_de_passe_a_ne_pas_oublier>
AUTORESTIC_SYNOLOGY_AWS_ACCESS_KEY_ID=<votre_access_key>
AUTORESTIC_SYNOLOGY_AWS_SECRET_ACCESS_KEY=<votre_secret_key>
```

Il ne vous reste plus qu'à voir si la config est correcte.

```sh
autorestic -c <chemin_vers_votre_config>/.autorestic.yml check
```

Tout est au vert ? Si non toutes mes condoléances, vous pouvez me contacter si vous avez des questions, mais si tout est bon, vous pouvez lancer votre premier backup !

```sh
autorestic -c <chemin_vers_votre_config>/.autorestic.yml backup
```

Et pof, tout le contenu de votre dossier se fait sauvegarder comme par magie.

Et vous savez ce qui est encore **plus** génial ? 

La prochaine fois que vous lancerez une sauvegarde, restic ne sauvegardera pas l'intégralité de votre dossier une deuxième fois, mais **uniquement la différence**. Ce qui est un gain de place monstrueux.

## Sauvegarde périodique
Dans notre fichier de configuration, nous avons spécifié à un moment donné que nous souhaitions une sauvegarde tous les jours à 3 heures du matin. Et là, on en a pas encore vu la couleur. J'y viens.

Autorestic dispose d'une commande `cron`, qui s'assure que la sauvegarde n'est pas effectuée plus souvent que consigné. Si vous exécutez la commande suivante :

```sh

# Si vous n'avez pas exécuté la sauvegarde après 3 heures du matin aujourd'hui, la commande suivante exécute une sauvegarde
autorestic -c <chemin_vers_votre_config>/.autorestic.yml cron

# Re-exécutez cette même commande, et elle ne s'exécutera pas
autorestic -c <chemin_vers_votre_config>/.autorestic.yml cron
```

Vous pouvez exécuter la commande `cron` toutes les minutes si vous le souhaitez, tant que votre condition `cron` définie dans votre `.autorestic.yml` n'est pas valide, la sauvegarde ne s'exécutera pas.

L'idée ? Créer une `crontab` qui exécute la commande toutes les heures. Ou toutes les 5 minutes. C'est vous qui voyez.

Obtenez le chemin absolu vers le binaire d'autorestic

```sh
whereis autorestic
```

Créez donc une nouvelle règle cron avec la commande `crontab`

```sh
crontab -e
```

Et renseignez cette ligne, qui s'exécute toutes les heures.

```
  * 0  *   *   *     <dossier_contenant_le_binaire>/autorestic -c <dossier_contenant_votre_conf>/.autorestic.yml --ci cron
```

# C'est terminé !

Et voilà ! Votre serveur sera désormais périodiquement sauvegardé vers votre Synology ! Vous avez également un bucket S3 que vous pourrez réutiliser afin d'être la destination de sauvegarde de toutes vos applications compatibles ! 

Si vous avez la moindre question, vous pouvez me contacter via les moyens consignés sur mon site internet : https://bachrc.net
