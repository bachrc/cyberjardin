---
tags:
  - dev
  - ops
---
# Description
Garage est un logiciel open-source de stockage d'objet, distribué et compatible avec S3. Il est conçu pour l'auto-hébergement, et permet de la redondance avec d'autres serveurs.

# Téléchargement
Rendez-vous sur la [page officielle des téléchargements de Garage](https://garagehq.deuxfleurs.fr/download/), et copiez l'URL de téléchargement du binaire correspondant à votre architecture.

Copiez l'URL de la release convenant à votre OS et architecture, et utilisez la dans les prochaines commandes.

```sh
# Création du dossier de destination s'il n'existe pas déjà
mkdir -p ~/.local/bin

# Téléchargement du binaire en y renseignant l'URL précédemment récoltée
wget <votre_url> -O ~/.local/bin
```
# Démarrage Rapide

## Configuration initiale
Avant toute chose, nous allons utiliser [le guide Quick Start](https://garagehq.deuxfleurs.fr/documentation/quick-start/) de [[Garage]] afin de configurer rapidement notre serveur.

Rendez-vous dans le dossier que vous souhaitez, dans notre exemple ce sera `/volume1/garage`, et créez le dossier `data`, où garage écrira ses données

```sh title="/volume1/garage" hideLineNumbers
mkdir /volume1/garage/data
```

et créez votre fichier de configuration de la sorte. Copiez-collez la commande suivante dans votre shell (même s'il y a plusieurs lignes oui), et appuyez sur Entrée.

```sh title="/volume1/garage
cat > garage.toml <<EOF
metadata_dir = "/volume1/garage/data/meta"
data_dir = "/volume1/garage/data/data"
db_engine = "lmdb"

replication_factor = 1
compression_level = 2

rpc_bind_addr = "[::]:3901"
rpc_public_addr = "127.0.0.1:3901"
rpc_secret = "$(openssl rand -hex 32)"

[s3_api]
s3_region = "garage"
api_bind_addr = "[::]:3900"
root_domain = ".s3.garage.localhost"

[s3_web]
bind_addr = "[::]:3902"
root_domain = ".web.garage.localhost"
index = "index.html"

[k2v_api]
api_bind_addr = "[::]:3904"

[admin]
api_bind_addr = "[::]:3903"
admin_token = "$(openssl rand -base64 32)"
metrics_token = "$(openssl rand -base64 32)"
EOF
```

Votre fichier de configuration est généré ! Vous pouvez désormais exécuter le logiciel, en spécifiant l'emplacement du fichier de configuration de la sorte :

```sh
garage -c /volume1/garage/garage.toml server
```

> [!tip] Petite astuce
> Lancer cette commande lancera l'application dans le shell actif. Si vous n'utilisez pas de multiplexeur comme [[Zellij]] ou tmux, votre outil s'arrêtera en même temps que votre shell !

## Consulter l'état de Garage
Vous pouvez consulter l'état de Garage via la commande suivante :

```sh
garage -c /volume1/garage/garage.toml status
```

Et quelque chose de similaire devrait apparaître

```
==== HEALTHY NODES ====
ID                 Hostname  Address         Tag                   Zone  Capacity
563e1ac825ee3323   linuxbox  127.0.0.1:3901  NO ROLE ASSIGNED
```

Notez bien l'identifiant de votre noeud, nous allons l'utiliser pour mettre en place le serveur.

## Création du cluster
Garage est également conçu afin de pouvoir être utilisé en redondance, fournissant une couche de sécurité supplémentaire pour vos données. Dans notre cas, nous allons créer un cluster d'un seul noeud.

```sh
garage -c /volume1/garage/garage.toml layout assign -z dc1 -c 1G <id_noeud>

# Appliquez les modifications
garage -c /volume1/garage/garage.toml layout apply
```

Votre outil est désormais prêt à être utilisé.

## Création d'un bucket et de clés d'accès
Afin de pouvoir commencer à stocker des données dans notre outil, il faut créer un "bucket". Littéralement un "endroit où déverser nos objets".

```sh
garage -c /volume1/garage/garage.toml bucket create backup-bucket
```

Votre bucket est créé sous le nom `backup-bucket` ! Maintenant, créons des clés d'accès à ce dernier.

Afin de se connecter à un bucket S3, nous allons générer une clé d'accès. La clé d'accès se décompose en deux parties : 
- L'`Access Key`, qui identifie votre clé
- La `Secret Key`, similaire à un mot de passe

Créons donc ce couple d'identifiants

```sh
garage -c /volume1/garage/garage.toml key create backup-bucket-michelle
```

Vous devriez obtenir un résultat comme celui-ci :

```
Key name: backup-bucket-michelle
Key ID: GK3515373e4c851ebaad366558
Secret key: 7d37d093435a41f2aab8f13c19ba067d9776c90215f56614adad6ece597dbb34
```

Ici, `Key ID` correspond à votre `Access Key`, et `Secret Key` à... elle-même.

Nous avons créé une clé, mais elle n'est liée à rien. Donnons-lui tous les droits sur notre bucket fraîchement créé :

```sh
garage bucket allow \
  --read \
  --write \
  --owner \
  backup-bucket \
  --key backup-bucket-michelle
```

Vous avez désormais un bucket prêt à l'emploi, ainsi qu'un couple de clés pour y accéder.


# Fichier justfile
L'extrait suivant est un fichier `justfile`, pour utilisation avec [[Just]]

```justfile title="justfile"
garage-base := "garage -c ./garage.toml"

[private]
default:
    just --list

# starts the garage server
start:
    {{garage-base}} server

# shows the garage status
status:
    {{garage-base}} status

bucket-list:
    {{garage-base}} bucket list

key-list:
    {{garage-base}} key list

@create-bucket bucket-name:
    {{garage-base}} bucket create {{bucket-name}}

@create-owner-key bucket-name username:
    {{garage-base}} key create "{{bucket-name}}-{{username}}"
    {{garage-base}} bucket allow --read --write --owner {{bucket-name}} --key "{{bucket-name}}-{{username}}"
```


# Liens utiles

| Type          | Lien                                                      |
| ------------- | --------------------------------------------------------- |
| Site internet | https://garagehq.deuxfleurs.fr/                           |
| Documentation | https://garagehq.deuxfleurs.fr/documentation/quick-start/ |
| Code source   | https://git.deuxfleurs.fr/Deuxfleurs/garage               |
