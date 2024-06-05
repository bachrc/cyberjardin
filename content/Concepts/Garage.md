---
tags:
  - dev
  - ops
---
# Description
Garage est un logiciel open-source de stockage d'objet, distribué et compatible avec S3. Il est conçu pour l'auto-hébergement, et permet de la redondance avec d'autres serveurs.

# Démarrage Rapide
Avant toute chose, nous allons utiliser [le guide Quick Start](https://garagehq.deuxfleurs.fr/documentation/quick-start/) de [[Garage]] afin de configurer rapidement notre serveur.

Rendez-vous dans le dossier que vous souhaitez, dans notre exemple ce sera `/volume1/garage`, et créez le dossier `data`, où garage écrira ses données

```sh title="/volume1/garage"
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

Votre fichier de configuration est


# Liens utiles

| Type          | Lien                                                      |
| ------------- | --------------------------------------------------------- |
| Site internet | https://garagehq.deuxfleurs.fr/                           |
| Documentation | https://garagehq.deuxfleurs.fr/documentation/quick-start/ |
| Code source   | https://git.deuxfleurs.fr/Deuxfleurs/garage               |
