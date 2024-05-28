---
tags:
  - windows
  - bug
title: Astuce pour réduire la température CPU en jeu sous Windows
description: Avec des jeux tels que Baldur's Gate 3, le processeur monte facilement à 90°, même avec un bon système de refroidissement. Voici une astuce parmi tant d'autres afin d'y remédier.
---

# Le contexte

Récemment, j'ai eu la chance de découvrir Baldur's Gate 3. Jeu fabuleux, le Ultra passe très bien sur mon ordinateur assez récent. Cependant, mon processeur ne peut pas en dire autant : quoi que je fasse, la température tourne toujours autour des 70-80°C.

Je sais que les i7-14700K sont réputés pour générer beaucoup de chaleur, mais quand même, à cette température là je ne sais même pas si je vais pouvoir terminer mon jeu. L'engin est bien watercoolé (*notamment grâce à ma très chère conjointe qui s'est chargée de son installation, et de Guillaume du service client LDLC que je remercie* 😄), cela ne devrait pas arriver.

Sur le subreddit de Baldur's Gate 3, je me suis rendu compte que j'étais loin, très loin d'être le seul à avoir ce genre de soucis. Mais apparemment, quelqu'un a [proposé plusieurs solutions](https://www.reddit.com/r/BaldursGate3/comments/15oof5m/fix_found_for_cpu_heat_issue/) qui ont semblé mettre tout le monde d'accord : ça marche ! Des gens sont passés de **90°C à 50°C** ! Des dizaines de remerciements en commentaires. 

Ah, petit détail, cette personne a supprimé deux semaines auparavant le contenu de son message en protestation envers Reddit. Ce que je soutiens, mais ça n'aide pas mes affaires malheureusement.

Je ne sais pas à l'heure actuelle quelles étaient les solutions proposées, mais j'en ai trouvé une qui m'a sauvé la mise : je suis passé de 70°C à 40°C en jeu. Aléluia.

# La solution

La solution qui a fonctionné pour moi, c'est l'underclock du processeur ! Littéralement le faire tourner à moindre régime. Nous allons lui dire de tourner à moindre régime, de l'ordre de 80% au lieu de 100%, ce qui aura un impact majeur sur la température du processeur, et un impact minime sur les performances. Encore plus minime en jeu.

> [!info] Le coeur du problème
> Dans certains processeurs récents d'Intel, il y a des Efficient Cores, et des Performance Cores. Suite à un problème de Windows *(mais non, qui l'eut cru)*, le contrôle de l'alimentation n'est à vrai dire effectif que sur les Efficient Cores, non sur les autres. Dans les paramètres avancés de gestion de l'alimentation, vous pouvez contrôler cette puissance maximum, mais ce n'est qu'un leurre. Il va falloir se salir un peu les mains.

# Corriger le souci

> [!hint] Merci !
> Je ne fais que relayer ici les étapes consignées dans cette [réponse sur les forums de Microsoft](https://web.archive.org/web/20240419062650/https://answers.microsoft.com/en-us/windows/forum/all/max-processor-state-setting-in-control-panel-power/d560664d-1e39-4ab6-9948-c4cb8a3f3b82). Merci beaucoup Vishnu 3333 !

Avant de commencer, **ouvrez un Terminal avec les droits administrateurs**. Tout va se dérouler dedans, puisque nous ne pouvons pas nous reposer sur l'interface Windows.

## Créer un profil de performance dédié

Exécutez la commande la commande suivante dans votre shell

```powershell
powercfg /list
```

Vous obtiendrez la liste des profils de performance de votre windows. Généralement, vous aurez Économie d'énergie, équilibré, performance... avec une petite astérisque `*` à côté du profil que vous utilisez actuellement.

Ce profil que vous utilisez, nous allons le dupliquer pour faire le notre. **Copiez l'identifiant de la ligne correspondant à votre profil en cours d'utilisation.** Utilisez-le dans la commande suivante.

```powershell
powercfg /DUPLICATESCHEME <votre long identifiant>
```

Votre profil de performance a été dupliqué. Vous pouvez le voir grâce à la même commande que précédemment, qui liste vos profils.

```powershell
powercfg /list
```

Le profil que vous avez dupliqué est listé. Vous pouvez désormais changer son nom afin de pouvoir l'identifier plus facilement. **Copiez l'identifiant du profil que vous venez de créer** (celui qui n'a pas d'astérisque à côté de lui), et renseignez-le dans la commande suivante.

```powershell
powercfg /changename <identifiant du nouveau profil> "Mon beau PC tout froid"
```

## Sous-exploiter le processeur branché sur secteur

> [!note] Note sur les personnes concernées
> Nous allons paramétrer le comportement du processeur lorsque l'ordinateur est branché sur secteur. Cela concerne donc les ordinateurs fixes, mais également les ordinateurs portables branchés sur secteur.

Munissez-vous de l'identifiant de votre nouveau profil tout juste créé, et renseignez les deux commandes suivantes.

```powershell
powercfg /setacvalueindex <votre identifiant> SUB_PROCESSOR PROCTHROTTLEMAX 90
powercfg /setacvalueindex <votre identifiant> SUB_PROCESSOR PROCTHROTTLEMAX1 80
```

Votre processeur a capé ses performances à 90% pour les Efficiency Cores, et à 80% pour ses Performance Cores. Ce qui peut-être handicapant si vous faites du montage vidéo ou de la musique, mais ici on ne se lave que très peu, on joue. Vous sentirez plus votre propre odeur que la différence de performances en jeu, qui est minime.

## Sous-exploiter le processeur fonctionnant sur batterie

> [!note] Note sur les personnes concernées
> De pair avec [[#Sous-exploiter le processeur branché sur secteur|la remarque précédente]], cette section concerne les ordinateurs portables. Si vous êtes sur ordinateur fixe, vous pouvez passer à la [[#Activer le nouveau profil|section suivante]].

Copiez à nouveau votre identifiant, et renseignez les commandes suivantes.

```powershell
powercfg /setdcvalueindex <votre identifiant> SUB_PROCESSOR PROCTHROTTLEMAX 90
powercfg /setdcvalueindex <votre identifiant> SUB_PROCESSOR PROCTHROTTLEMAX1 80
```

## Activer le nouveau profil

Votre nouveau profil est prêt. Vous pouvez désormais le sélectionner avec la commande suivante

```powershell
powercfg /setactive <votre identifiant>
```

# C'est terminé !

Votre ordinateur est désormais paré pour l'été ! N'hésitez pas à sélectionner l'ancien mode en hiver, on ne dit jamais non à un tel chauffage. *(ne le faites évidemment pas, des chaussettes coûtent bien moins cher qu'un nouveau processeur)*

Vous pouvez ajuster les valeurs 90 et 80 à votre convenance. Si vous trouvez que votre processeur chauffe toujours trop, vous pouvez réduire davantage, mais la perte de performances commencera à se faire sentir. 