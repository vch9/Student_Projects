# Compilation -- Master 1 Paris Diderot -- 2019-2020

## Description de ce dépôt

Dans ce dépôt, vous trouverez:

- dans `doc/`: le journal du cours, des notes et des documents de références.
- dans `flap/`: le code source du compilateur à développer dans ce cours.
- dans `.mrconfig`: la liste des dépôts étudiants.

## Objectifs

Dans ce cours, vous allez programmer un compilateur. C'est un cours
orienté "projet" : c'est à travers le développement du compilateur que
nous allons rencontré les différents sujets du cours. Ils nous feront
passer par différentes disciplines de l'informatique : la théorie et
l'implémentation des langages de programmation, mais aussi
l'algorithmique des graphes, la théorie des automates ou encore
l'architecture des ordinateurs.

Du point de vue des compétences, nous cherchons à vous faire
travailler vos compétences de développeur sur un projet de taille
moyenne. Les phases de développement seront bien documentés à la fois
en cours et sous la forme de spécifications : la difficulté résidera
dans l'implémentation de ces spécifications et la maîtrise des
concepts sur lesquelles elles s'appuient.

Ce cours est aussi l'occasion de vous faire pratiquer la programmation
fonctionnelle, qui est particulièrement bien adaptée à l'écriture
d'analyseur et de traducteur de ces objets symboliques que sont les
programmes. Nous suivrons du mieux possible le principe de
décomposition associée à ce paradigme de programmation, c'est-à-dire
de former des programmes par la composition de multiples fonctions
simples et générales.

## Enseignants

Le cours magistral est donné par Adrien Guatto <guatto@irif.fr> et par Yann
Régis-Gianas <yrg@irif.fr>. Les travaux dirigés sont menés par Peter
Habermehl <peter.habermehl@irif.fr>.

N'hésitez pas à nous solliciter par email si vous rencontrez des
difficultés à comprendre ce cours ou à réaliser le projet. Si votre
question peut intéresser la totalité de la promotion, posez-là sur
la liste de diffusion du cours <compilation-m1-2019@listes.univ-paris-diderot.fr>

Vous __devez__ vous inscrire sur la liste de diffusion en vous rendant à
l'adresse suivante:

http://listes.univ-paris-diderot.fr/sympa/info/compilation-m1-2019

### Evaluation

Le développement du compilateur est décomposé en 7 jalons qui seront
rendus au fur et à mesure du semestre. Chaque jalon est accompagné
d'une batterie de tests qui vous aide à vous auto-évaluer. Il n'est
pas interdit de continuer à travailler sur un jalon après sa date de
rendu mais un bonus est donné aux étudiants qui respectent les dates
de rendu.

Une soutenance finale, qui a lieu traditionnellement en janvier,
déterminera votre note au projet en fonction de votre réalisation et
de votre compréhension du code. L'examen final portera aussi sur votre
compréhension du projet. Le plagiat est interdit et conduit à une
note finale de 0/20.

### Processus de développement

Vous devez effectuer un "fork" de ce projet sur gitlab et y rajouter
les deux membres de votre binôme ainsi que tous les comptes de vos
enseignants.

Vous __devez__ vous assurer que le fichier `.mrconfig` du présent dépôt
public (et non de votre fork) contient une ligne de la forme:

```
[students/luke-darth]
checkout = git clone git@gaufre.informatique.univ-paris-diderot.fr:luke/compilation-m1-2019.git luke-darth
```

où vous avez remplacé l'URL du dépôt par la vôtre ainsi que "luke" et
"darth" par vos noms de famille. Pour cela, vous __devez__ faire une
`pull-request` sur le présent dépôt.

Vous __devez__ enfin régulièrement mettre à jour votre dépôt en important
les changements de ce dépôt public.

### Contributions au dépôt public

N'hésitez pas à faire des `pull-requests` sur le dépôt public pour en
améliorer la qualité.
