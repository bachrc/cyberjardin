---
title: "Librairie Rust : Postgres embedded"
description: Une librairie qui permet d'intégrer Postgres à son application Rust
tags:
  - rust
  - postgresql
---
Je suis tombé sur une très bonne surprise aujourd'hui, il s'agit de postgres-embedded [(lien vers le dépôt Github)](https://github.com/theseus-rs/postgresql-embedded)

Quand l'on package une application Rust qui a besoin d'une base de données, SQLite n'est pas toujours la meilleure solution (même si SQLite est bien plus performant que certaines personnes laisseraient entendre). Postgresql étant super efficace et polyvalente, l'intégration avec Rust est très fluide et pratique, notamment grâce à des librairies comme [sqlx](https://github.com/launchbadge/sqlx).

Le souci, c'est pour le packaging de l'application. D'un côté votre appli Rust, de l'autre Postgres... au bout d'un moment ça devient lourd pour les utilisateurs si les étapes d'installation ça devient :
- Clone mon répo Git !
- Installe Docker !
- Un petit `docker compose up -d` est le tour est joué !
Non franchement j'en ai assez d'avoir 5 conteneurs de postgres en parallèle car j'ai 5 applications qui les utilisent. Vous me direz qu'on peut mutualiser les postgres, et vous aurez raison ! Mais **c'est chiant**. Et ça commence à faire beaucoup de désespoir pour [le pauvre utilisateur qui ne trouve pas le `.exe` sur Github.](https://www.reddit.com/r/github/comments/1at9br4/i_am_new_to_github_and_i_have_lots_to_say/)

Embarquer un postgres à bord, ça enlève beaucoup de complexité pour le packaging de l'application ! La très bonne librairie [pg_embed](https://docs.rs/pg-embed/latest/pg_embed/) proposait quelque chose de similaire, mais elle télécharge le binaire de Postgres dans un dossier sur l'ordinateur. Postgres-embed, lui, vous propose d'embarquer directement le binaire de Postgres dans votre binaire Rust ! Ce qui permet d'utiliser toute la puissance de Postgres, sans pour autant complexifier l'installation de votre appli.