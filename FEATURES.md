# AG-Voter - Features

Une application simple de vote en temps réel. Un admin crée des sessions, les participants rejoignent et votent.

## Principes clés

### Session (Admin)
Une **Session** est une session de vote créée par l'admin. Elle a:
- Un **nom** (ex: "Réunion du 15 mars")
- Un **lien unique** partageables aux participants
- Un **statut**: `pending` (en attente) → `active` (en cours de vote) → `closed` (terminée)
- Une **liste de questions** à voter (créées/éditées par l'admin)
- Une **liste de participants** (identifiés par nom)

L'admin peut ouvrir/fermer la session et gérer les questions une par une.

### Participant
Un **Participant** rejoint une session en:
1. Cliquant le lien unique de la session
2. Entrant son nom
3. Recevant un **lien personnel unique** pour voter

Un participant peut se retirer et se réinscrire plus tard (nouveau lien).

### Question
Une **Question** a:
- Un **texte** (ex: "Avez-vous aimé la présentation?")
- Plusieurs **choix de réponse** (ex: "Oui", "Non", "Peut-être")
- Un **statut**: `pending` → `active` (les participants votent) → `closed` (résultats affichés)
- Un ou plusieurs choix peuvent être "libre" (accepte texte libre en plus du choix)

L'admin active une question à la fois. Quand elle est fermée, les résultats s'affichent.

### Vote
Un **Vote** = un participant qui répond à une question.
- **Règle:** Un participant ne peut voter **qu'une seule fois** par question
- Le vote peut inclure du texte libre (si le choix l'accepte)

### Résultats
Quand une question est fermée:
- Les participants voient les résultats (nombre/pourcentage par choix)
- L'admin voit aussi les résultats + les textes libres saisis

## Flux utilisateur

### Participant - Avant le vote
1. Participant arrive sur le lien de session
2. Voit la **salle d'attente** (horloge, "En attente du démarrage")
3. Quand l'admin ouvre la session → salle se rafraîchit, affiche la première question

### Participant - Pendant le vote
1. Voit la question active
2. Clique sur un choix (et texte libre si applicable)
3. Clique "Voter"
4. Page dit "Vous avez déjà voté sur cette question"
5. Peut voir l'historique des questions fermées + résultats
6. Attend la prochaine question active

### Admin - Gestion session
1. Crée une session + partage le lien
2. Voit en temps réel les participants qui rejoignent
3. Crée les questions + choix
4. **Ouvre** la session → participants voient la salle d'attente se transformer en page de vote
5. **Active** une question → tous les participants votent
6. Voit le **nombre de votes en direct** (ex: 7/10)
7. **Ferme** la question → résultats affichés aux participants
8. Recommence avec la question suivante
9. **Ferme** la session (optionnel)

## Mises à jour en temps réel

Tout se met à jour **sans rafraîchir la page**:
- Admin active une question → participants le voient immédiatement
- Admin ferme une question → résultats apparaissent immédiatement
- Admin ouvre la session → salle d'attente disparaît, vote apparaît
- Admin vote count → affichage en direct (ex: "3/10 votes")

Implémentation: WebSocket (ou Server-Sent Events en fallback)

## Spécificités

### Identité des participants
- Pas de compte, pas de mot de passe
- Nom fourni librement à l'arrivée
- Lien unique = jeton anonyme pour voter
- Peut se retirer et revenir avec un nouveau lien

### Salle d'attente
- Affichée tant que la session n'est pas `active`
- Peut avoir du contenu interactif (optionnel: jeu, compteur, etc.)
- Disparaît dès que la session est ouverte

### Pas de session fermée
- Quand la session est `closed`, on pourrait:
  - Afficher les résultats finaux
  - Rediriger vers la page d'identification
  - Bloquer les nouveaux votes
  - Idée: laisser flexible pour usage futur

## Concepts optionnels

- **Relocation:** Admin peut modifier une question (tant qu'elle est pending)
- **Supprimer participant:** Admin peut retirer un participant (son vote reste)
- **Résultats exportables:** Admin peut télécharger les résultats
- **Historique:** Garder trace des sessions clôturées

## Technologies

**Flexible** - implémentable en:
- Rails 8, Django, Symfony, FastAPI, Node.js, Go...
- Base de données: SQLite / PostgreSQL / MySQL
- Frontend: HTML + CSS + JavaScript vanilla
- WebSocket: natif, Socket.io, ou SSE
