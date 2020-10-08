Projet de Programmation Fonctionnelle Avancée
============================================

**M1 Informatique - Paris Diderot**

### Enoncé : programmer par des exemples

[Le sujet](enonce.pdf)

[Quelques exemples](exemples)

### Consignes générales

  * Ce projet est à réaliser par groupe de 2 étudiants au plus
  * Date limite de rendu : A PRECISER (pas avant mai)
  * Soutenances de ce projet : A PRECISER (pas avant mai)
  * Pour réaliser ce projet et nous soumettre votre travail:
     - créez un "fork" du présent dépôt git `pfa-2020` par groupe
     - paramétrez votre dépôt pour qu'il soit privé
     - ajoutez Letouzey et Treinen parmi les membres ayant accès à votre dépôt
     - réalisez votre programme dans le répertoire `projet` (détails ci-dessous)
     - utilisez régulièrement `git commit` et `git push` pour enregistrer votre travail
     - et c'est tout!

### Consignes concernant votre programme

  * Votre répertoire `projet` doit contenir un fichier `Makefile` permettant de construire un programme nommé `genconcat` lorsqu'on tape la commande `make` dans ce répertoire.

  * Ce programme `genconcat` doit accepter au moins le mode de fonctionnement suivant : `genconcat <fichier>` doit afficher le programme Concat que vous avez produit  à partir du contenu de `<fichier>`. Voir le répertoire `projet/exemples` pour des exemples de fichiers à traiter

  * Votre programme devra pouvoir être compilé avec OCaml 4.05 (celui installé sur les PCs de l'UFR). Pour l'instant, la seule bibliothèque autorisée pour ce projet est la librairie standard d'OCaml. Vous pouvez éventuellement nous soumettre vos demandes (motivées) d'autorisation de bibliothèques externes, nous aviserons.

  * Le reste de l'organisation est libre (emplacement et découpage des fichiers sources par exemple).

  * La qualité du code produit (lisibilité, indentation, organisation, etc) sera évidemment prise en compte.

### Changelog

  * 26/2/2020: énoncé version 1
  * 05/5/2020: enoncé version 2 (section 3.4, précisions sur Start/End)
