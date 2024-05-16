---
title: Apprenons Rust en TDD, et Archi Hexagonale (Partie 1)
description: Le premier de la trilogie
tags: dev,rust
published: true
publication_date: 2022-10-16T17:57:14+02:00
pouet_url: https://mamot.fr/@pacha/109395508398437096
---

## Introduction

S'il s'agit d'un langage prometteur sur le papier, on peut se demander si Rust est utilisable dans le but de façonner un logiciel. Comment peut-on s'en servir ? Quels sont les apports de ce langage en termes d'outils permettant la création d'un logiciel lisible, propre et testé? Ce sont les questions qui vous traversent peut-être l’esprit, et sur lesquelles nous allons nous pencher dans cette série d'articles.

Dans cet article, nous voulons voir ce que Rust peut apporter lors du développement logiciel, et comprendre pourquoi ce langage suscite tant d'intérêt.

Pour le savoir, il faut d'abord présenter de façon succincte ce qu'est Rust. Pour cela, imaginez ce langage comme un marchand vendant son tapis à un client. Pour faire simple, Rust est un langage compilé et cross-platform. Terriblement rapide et économe en mémoire, il rivalise sans problème aucun avec le C et C++. Mieux encore, sa gestion de la mémoire constitue son point fort : le cycle de vie de cette dernière est défini à la compilation, ce qui signifie qu'il n'y a aucun garbage collector, un avantage rendu possible grâce à une architecture du langage adaptée, et intelligente.

Si le caractère pertinent de ces nouveaux concepts n'est plus à prouver, ils ont cependant pour défaut de complexifier l'apprentissage du langage. Très abrupte, la courbe d'apprentissage décourage ainsi les nouveaux venus. Heureusement, le compilateur est dur, mais bienveillant, dispensant des messages d'erreurs très utiles.

Pléthore d'articles traitent de Rust en détails, le langage étant extrêmement complexe. Cependant, nous n'allons ici que découvrir l'outil, afin de jauger sa capacité à nous aider dans notre projet. Ce dernier ne sera pas un simple Hello World, car, vous en conviendrez : nous sommes plus originaux que ça. Nous souhaitons un _service de bienveillance_.

Est il possible d'envisager un développement _propre_ de ce logiciel ? Regardons ensemble.

## Installation et bases de Rust

Pour installer Rust, vous pouvez suivre les instructions d'installation disponibles sur le site officiel ci-dessous.

[https://doc.rust-lang.org/book/ch01-01-installation.html](https://doc.rust-lang.org/book/ch01-01-installation.html)

Notre nouveau meilleur ami, c'est désormais `rustc` ! Il s'agit du compilateur de rust.

> [!info]
> Pour toutes les commandes de cet article, nous assumerons que vous serez sur MacOS, ou une distribution Linux. Veuillez adapter vos commandes pour Windows ! (les commandes comme `cd` ou `mkdir`, par exemple.

Pour débuter la création de notre service de bienveillance, nous allons créer un fichier **main.rs** :

```rust
fn main() {
	println!("Coucou ! N'oublie pas de boire de l'eau.");
}
```

De retour dans votre terminal vous pouvez compiler votre grain de bienveillance :

```bash
$ rustc ./main.rs
$ ./main
Coucou ! N'oublie pas de boire de l'eau.
```

Ceci dit, si rustc est incroyable, nous n'allons pas l'utiliser directement. Nous allons passer par un intermédiaire qui va grandement nous faciliter la tâche : cargo.

### Création d'un projet en Rust

Cargo, c'est l'utilitaire de build, ainsi que le gestionnaire de paquets de Rust. Il est très puissant et va nous permettre de gérer des projets complexes.

Nous allons devoir faire des adieux déchirants à notre grain de bienveillance...

```bash
rm ./main.rs
```

...Pour mieux léguer la création de notre projet Rust à Cargo, à l'aide de la commande suivante :

```bash
$ cargo new bienveillance-core --lib
Created library `bienveillance-core` package

$ cd bienveillance-core
```

Un `--lib` a été spécifié, qui ne va pas générer un exécutable mais une librairie. Notre service de bienveillance n'a pas encore pour but d'être exécuté. Nous n'avons qu'une logique métier. L'exécution est inutile lorsqu'il est possible de tester.

Ainsi nous pouvons voir que des fichiers ont été créés :

```
bienveillance-core
├── Cargo.toml
└── src
└── lib.rs
```

Si nous jetons un oeil au `Cargo.toml` voyons ce qu'il renferme :

```bash
[package]
name = "bienveillance-core"
version = "0.1.0"
authors = ["bachrc <bachrc@dessert.coffee>"]
edition = "2018"
# See more keys and their definitions at https://doc.rust-lang.org/cargo/reference/manifest.html

[dependencies]
```

Notre nouveau service de bienveillance est désormais initialisé. `Cargo.toml` va être le fichier renfermant les informations nécessaires à notre build. C’est le fichier qui sera utilisé par cargo pour effectuer ses opérations.

Voyons voir ce que contient notre lib.rs:

```rust

#[cfg(test)]
mod tests {
	#[test]
	fn it_works() {
		assert_eq!(2 + 2, 4);
	}
}
```

C'est un modèle de test par défaut, qui s'assure que.... 2 et 2 font 4.

Nous pouvons tout simplement lancer les tests afin de nous en assurer :

```bash
cargo test
```

Le test passe ! Vous pouvez respirer, l'entropie de notre monde est préservée. Vous pouvez enlever le contenu de ce fichier.

> [!info]
> Voir le code de <a href="https://github.com/bachrc/bienveillance-land/tree/a5129fcc14b8953122d6c03b3242376c0e4d0919">cette étape</a>

### Quelle application désirons-nous ?

Imaginons nos besoins. Par exemple, “développer de la gentillesse à notre égard”. Recevoir de la chaleur de la part de mon programme sera alors notre besoin. Mais...pour le moment, il devra simplement nous dire bonjour.

Le fichier `lib.rs` est important ici car il va préciser que notre paquet est une librairie. Mais nous allons enlever les tests dedans, ils n'ont rien à faire ici.

À côté de notre dossier `src`, nous allons créer un dossier `tests`, dans lequel nous allons inscrire notre premier besoin. Quelqu'un pour nous dire bonjour.

## Première fonctionnalité : je veux recevoir un bonjour !

Créons dans le dossier `tests`, un fichier `welcoming_test.rs` :

`tests/welcoming_test.rs`

```rust
use bienveillance_core::welcomer::Welcomer;

#[test]
fn should_welcome_anyone() {
	let welcome_message: String = Welcomer::compute_welcome_message();
	assert_eq!(welcome_message, "Bonjour !")
}
```

Ceci constitue le premier code que nous écrivons. Décomposons.

**Première ligne**
`use` est le mot clé nous permettant d’importer des modules ou des structures. Ici, il sert à importer notre structure `Welcomer`, dans laquelle se trouve la fonction que nous utiliserons. C’est un mécanisme qui est rendu aisé grâce à l’utilisation d’un IDE tel que IntelliJ où Visual Studio Code. A l’avenir, nous ferons l’impasse sur les lignes d’import dans l’article, mais vous pourrez toujours les retrouver dans le code qui vous est joint.

**Deuxième ligne**
Cet attribut sert d'annotation sur la fonction. Quand nous lancerons les tests à l'aide de Cargo, Cargo reconnaîtra la fonction, et la considèrera comme une fonction de test.

**Troisième ligne**
Ici, on déclare la fonction, avec son nom : `should_welcome_anyone`. Qui explicite ce que nous cherchons à implémenter : n'importe qui doit pouvoir recevoir un bonjour.

**Quatrième ligne**
Celle-ci est plus technique, nous déclarons notre première variable ! Ici nous appelons la fonction `compute_welcome_message` de la classe `Welcomer` qui retourne une variable de type String ! Que nous stockons dans notre variable `welcome_message` à l'aide de l'opérateur `let`.

**Cinquième ligne**
Nous faisons appel à la macro `assert_eq!`, que nous utilisons afin de nous assurer que notre variable `welcome_message` vaut bien notre bonjour !

Ce qui nous amène à la question suivante : qu'est-ce qu'une macro ? Ce n'est pas une fonction ?

Non ! Une macro est en quelque sorte du code qui va générer du code. Elles sont caractérisées par le point d'exclamation à la fin de leur nom. Elles sont en général utilisées en tant que sucre syntaxique, afin de rendre le code plus lisible. Chacun peut créer ses propres macros, mais c'est un procédé complexe pouvant être dangereux pour la maintenabilité de votre code ! A utiliser avec parcimonie.

Nous allons maintenant créer notre structure `Welcomer`, car pour le moment, nos tests ne passent pas, mais pas pour la bonne raison : le code ne compile pas !

### Notre premier objet !

Créons le fichier `src/welcomer.rs` :

```rust
pub struct Welcomer;

impl Welcomer {
	pub fn compute_welcome_message() -> String {
		String::from("")
	}
}
```

Voici donc notre premier objet, notre premier **struct**ure de données en Rust !

Décomposons là encore, ligne par ligne, ce morceau de code.

**Première ligne**
Ici nous déclarons notre structure de données. C'est ici que nous pouvons déclarer les attributs de notre objet. Pour le moment, il n'en a aucun. C'est pourquoi nous ne déclarons que son nom. Nous déclarons notre structure en `pub`lique afin de pouvoir y avoir accès en dehors du fichier.

**Deuxième ligne**
Nous allons ici déclarer les comportements de notre structure de données. S'il est totalement possible d'avoir une `struct` sans avoir d' `impl` émentation, l'inverse n'est pas possible, car nous implémentons un comportement à la structure précédemment déclarée.

**Troisième ligne**
Nous déclarons la fonction `pub`lique `compute_welcome_message` ! Il faut insister sur le fait qu'il s'agisse d'une _fonction_ et non d'une _méthode_ ! La fonction ne dépend pas d'une instance de la structure de données. On peut dire que c'est similaire à ce qu'est une fonction statique par exemple.

Nous noterons également que notre type de retour est un **String**. Ceci est important pour la suite des évènements, qui arrivent maintenant.

**Quatrième ligne**
Plusieurs questions doivent vous venir à l'esprit en voyant cette ligne. Nous allons y répondre ensemble.

> [!question]
> La fonction est censée retourner un String, où est le `return` ?

En Rust, la dernière instruction d'une fonction/méthode est ce qui est retourné ! Soit ici, l'objet `String` renvoyé par `String::from("")`

> [!question]
> Pourquoi mange-t-on certains animaux, et en domestiquons d'autres ?

Alors je ne vais pas répondre à cette question

> [!question]
> Pourquoi retournons-nous `String::from("")` et non pas "" directement ?

Et c'est là que le bât blesse. Disons simplement que notre `""` n'est pas un `String`. Mais un `&str`. Ce qui nous permet de nous pencher sur l'une des fonctionnalités les plus importantes et complexes de Rust : **l'Ownership**. Il s’agit d’un concept complexe que je vous expliquerai dès lors que notre test sera passant.

Lorsque nous lançons nos tests, ils sont au rouge.

```
Left:
Right: Bonjour !

thread 'should_welcome_anyone' panicked at 'assertion failed: `(left == right)`
left: `""`,
right: `"Bonjour !"`', tests/welcoming_test.rs:7:5
```

Ici notre test attend un bonjour, mais nous n'obtenons qu'une chaîne vide. Il faut l'implémenter !

`src/welcomer.rs`

```rust
pub struct Welcomer;

impl Welcomer {
	pub fn compute_welcome_message() -> String {
		String::from("Bonjour !")
	}
}
```

Tout ça m'a l'air d'être parfait !

Nous avons implémenté notre première fonctionnalité de `Hello World` ! Et en plus, la fonctionnalité est testée. Superbe !

> [!info]
> Retrouvez le <a href="https://github.com/bachrc/bienveillance-land/tree/9e80d5a74cb439568dab56bb56b991836e86fa47">code de l'étape</a>

Prenez une grande inspiration, nous allons rentrer dans le vif du sujet : l’Ownership.

### L'Ownership : quel enfer

L'Ownership est une des fonctionnalités centrales du langage, elle est notamment responsable de l'établissement du cycle de vie de la mémoire de Rust à la compilation, avec son système de responsabilités de variables.
C'est un principe complexe que nous ne ferons que survoler ici. Pour plus de détails, cf. le livre de Rust : [Lien vers la référence](https://doc.rust-lang.org/book/ch04-01-what-is-ownership.html)

L'Ownership est régi par trois règles :

- Chaque valeur en Rust possède une variable qui est appelée sa propriétaire.
- Il ne peut y avoir qu'un responsable à la fois
- Quand le responsable sort du scope : la valeur est nettoyée de la mémoire.

Prenons la fonction suivante.

```rust
// Attention : ce code ne COMPILE PAS
fn main() {
	let salutation = String::from("Coucou la petite COMMU");
	let longueur_de_salutation = calculate_length(salutation);

	println!("La chaine {} fait {} caractères !", salutation, longueur_de_salutation);
}

fn calculate_length(some_string: String) -> usize {
	some_string.len()
}
```

Cependant, ce code ne compile pas. Pourquoi donc ?

**Ligne 4**
La variable `salutation` a la propriété de sa valeur.

**Ligne 6**
Est ici déléguée la propriété du contenu de la valeur jusqu'ici possédée par `salutation` à la fonction `calculate_length`. **La fonction calculate_length est désormais propriétaire de la valeur de contenu.**

**Ligne 12**
La fonction retourne la longueur de la chaîne de caractères dont elle a la propriété. **Cependant**, elle ne fait rien de la valeur de cette chaîne. **La valeur de celle-ci est donc nettoyée.**

**Ligne 8**
L'erreur se situe ici. La propriété de la variable ayant été déléguée à `calculate_length`, la variable `salutation` ne possède plus rien ! On ne peut plus l'afficher, ni même l'utiliser. Son contenu a été nettoyé à la sortie du scope de `calculate_length`.

Quand nous compilons le code, cette erreur nous est indiquée de manière très explicite :

```
error[E0382]: borrow of moved value: `salutation`
--> src/main.rs:8:51
  |
4 | let salutation = String::from("Coucou la petite COMMU");
  | ---------- move occurs because `salutation` has type `String`, which does not implement the `Copy` trait
5 |
6 | let longueur_de_salutation = calculate_length(salutation);
  | ---------- value moved here
7 |
8 | println!("La chaine {} fait {} caractères !", salutation, longueur_de_salutation);
  | ^^^^^^^^^^ value borrowed here after move
error: aborting due to previous error

For more information about this error, try `rustc --explain E0382`.
error: could not compile `playground`
```

Comme nous l'avons spécifié auparavant : le compilateur nous fait certes un peu mal, mais avec pédagogie : en nous aidant par l'explication à ne plus répéter l'erreur, il nous permet de progresser. `rustc`, c'est plus qu'un compilateur. _C'est un ami._

> [!question]
> Quoi ? Ça veut dire qu'à chaque fois que je veux mettre une variable en paramètre d'une fonction, je ne peux plus l'utiliser derrière ?! Il est tout pété ton langage là !

Fort heureusement, dans le monde actuel, lorsqu'il n'est pas possible d'acquérir un bien, nous avons la CHANCE de pouvoir faire un emprunt ! Et c'est pareil en Rust, avec la mécanique du Borrowing, de l'emprunt.

### Emprunter des valeurs

En Rust, il est possible d'expliciter que nous ne souhaitons pas avoir la propriété d'une variable, mais seulement une référence à sa valeur. Modifions notre code afin d'utiliser la mécanique de l'emprunt.

```rust
// Attention : ce code COMPILE

fn main() {
	let salutation = String::from("Coucou la petite COMMU");
	let longueur_de_salutation = calculate_length(&salutation);

	println!("La chaine {} fait {} caractères !", salutation, longueur_de_salutation);
}

fn calculate_length(some_string: &String) -> usize {
	some_string.len()
}
```

Vous pouvez noter deux différences ici, avec l'introduction du caractère de référence `&` :

**Ligne 6**
Nous ne donnons plus la propriété de la valeur de `salutation` à `calculate_length` : nous donnons une **référence** à la valeur de `salutation`. Notre variable `salutation` garde ainsi la propriété de sa valeur.

**Ligne 11**
La fonction `calculate_length` indique qu'elle ne requiert plus la propriété de la valeur : elle n'indique n'avoir besoin que d'une référence à cette valeur. A la fin du scope de la fonction, nous ne ferons que mettre fin à l'emprunt, et notre programme va ainsi pouvoir compiler. Vérifions !

```
La chaine Coucou la petite COMMU fait 22 caractères !
```

Notre programme avec l'emprunt fonctionne désormais !

> [!question]
> Ok... mais pourquoi on parle de tout ça en fait ? On parlait pas de chaîne de caractères ?

Oui ! Revenons au point de base. Pourquoi y a-t-il `&str` et `String` ?

Très simplement : `&str` est une référence à une partie d'une `String`. Lorsque vous compilez votre code avec des chaînes de caractères, vos chaînes de caractères se situent dans une mémoire allouée à des valeurs en lecture seule. Lorsque votre programme tourne : _votre variable est donc une référence à ce texte alloué dans cette mémoire en lecture seule._ Tout simplement parce que votre variable n'en a pas la propriété : c’est cette mémoire en lecture seule qui en a la propriété. Vous ne faites qu'un emprunt.

Revenons à notre code.

```rust
pub struct Welcomer;

impl Welcomer {
	pub fn compute_welcome_message() -> String {
		String::from("")
	}
}
```

Pourquoi donc nous préférons retourner un `String` plutôt qu'un `&str` ? Pour pouvoir donner la propriété de la chaîne de caractères à l'appelant de la fonction, afin de nous permettre une plus grande souplesse lors de l'utilisation.

Voilà, en résumé, l'explication de l'ownership, qui peut sembler complexe de prime abord mais ne s'avère être qu'une gymnastique mentale, qui, ne vous inquiétez pas, devient naturelle au fil du temps.

Dans le prochain article, nous allons continuer nos cycles de développement, afin d'obtenir toujours plus de chaleur. Comme avec des accueils personnalisés, accordés à nos pronoms, ainsi que des compliments ! Que demander de plus ?
