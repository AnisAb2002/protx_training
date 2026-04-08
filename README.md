#ProtX Training 🏋️‍♂️

ProtX Training est une application web de suivi de musculation développée en Swift avec le framework Hummingbird. Elle permet aux utilisateurs de planifier des séances, de suivre leur progression via un système d'XP et de visualiser leurs exercices via des démonstrations animées.

---

## 1) Fonctionnement

L'application repose sur un système de progression ludique :

- Profil Personnalisé : Calcul automatique de l'IMC et du niveau (débutant, pro, dragon ...) en fonction des points accumulés.

- Planification : Création de séances en choisissant parmi une base de données d'exercices filtrables par muscle ou par nom.

- Validation : Une fois la séance effectuée, l'utilisateur la valide pour créditer les points à son profil.

- Base de Données : Utilisation de SQLite avec une relation Many-to-Many pour lier les exercices aux séances.

---

## 2) Lancement

Faire un build du projet (résoudre les dépendances et compiler) :

```bash
./build.sh
```

Lancer le serveur :

```bash
./run.sh
```

Accès : Ouvrez votre navigateur sur http://localhost:8080

---

## 3) Liste des Routes

1) Authentification & Profil

| Méthode | Route | Description |
|---|---|---|
| GET | /login | Page de connexion (gère l'erreur via paramètre ?error=1) |
| POST | /login | Vérification des identifiants et redirection |
| GET | /register | Formulaire de création de compte |
| POST | /register | Création de l'utilisateur en base de données |
| GET | /profil | Affichage des données de l'utilisateur et de son IMC |
| POST | /profil/update | Mise à jour du poids, taille, nom et prénom |

2) Gestion des Séances

| Méthode | Route | Description |
|---|---|---|
| GET | / | Tableau de bord (nécessite ?user=ID). Affiche le récapitulatif |
| POST | /seance/add | Crée une séance et lie les exercices sélectionnés |
| POST | /seance/valider/:id | Marque une séance comme faite et ajoute l'XP au profil |
| POST | /seance/delete/:id | Supprime une séance et ses liaisons (Cascade) |

---

## 4) Modèle de Données (Schéma SQL)

L'application utilise 4 tables SQLite :

- utilisateurs : Stocke les infos physiques et le score global.

- exercices : Catalogue des mouvements (nom, muscle, XP, image).

- seances : Liste des entraînements planifiés.

- seance_exercices : Table de liaison (Many-to-Many) permettant d'ajouter plusieurs exercices à une même séance.

---

## 5) Fonctionnalités Bonus Implémentées

### Recherche & Filtrage : 

Système dynamique en JavaScript dans la vue de planification pour filtrer les exercices par muscle ou par nom sans recharger la page.

### Relation Many-to-Many : 

Gestion complexe des exercices liés aux séances via une table pivot.

### Interface UX/UI : 

Utilisation de Pico CSS avec un thème sombre personnalisé, des cartes d'exercices visuelles (GIFs) et des indicateurs de progression.

### Logique Métier : 

Calcul en temps réel de l'IMC et changement automatique de grade (Niveaux) selon le score total.

---

## 6) Notes spécifiques

- La base de données est automatiquement initialisée avec un "Seed" d'exercices au premier lancement.

- La sécurité des routes est gérée par le passage du login dans l'URL (?user=...), assurant la persistance de la session durant la navigation.

---

## 7) Sources et Crédits

### Visuels des exercices : 

Les images et GIFs animés illustrant les mouvements ont été extraits du site Docteur Fitness.

Ces ressources sont utilisées exclusivement dans un but pédagogique dans le cadre de ce projet d'études.

### Frameworks : 

Hummingbird, SQLite.swift, Pico CSS.

---

## 8) Auteur

### Anis ABDAT

Etuiant en informatique