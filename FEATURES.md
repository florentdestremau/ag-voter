# AG-Voter - Features Documentation

Une application de vote en temps réel avec gestion participative.

**Note:** Ce document est framework-agnostique. Peut être implémenté en Rails, Symfony, Django, FastAPI, etc.

## Vue d'ensemble

AG-Voter est une application permettant à un administrateur de créer des sessions de vote, de poser des questions avec des choix de réponse, et aux participants de voter en temps réel. Les résultats sont affichés instantanément à l'administrateur via WebSocket.

## Architecture générale

- **Frontend:** HTML/CSS/JavaScript
- **Backend:** API REST/GraphQL avec WebSocket
- **Persistence:** SQL Database (SQLite, PostgreSQL, MySQL)
- **Temps réel:** WebSocket (Server-Sent Events alternatif)
- **Authentification Admin:** Session HTTP + mot de passe
- **Identification Participants:** Tokens URL uniques par participant (JWT ou simple token)

## Modèle de données

### Entités

#### AgSession
| Champ | Type | Spec |
|-------|------|------|
| id | UUID/Int | Primary key |
| name | String | Nom de la session (requis) |
| token | String | URL token unique (généré automatiquement, ex: SecureRandom 16 chars) |
| status | Enum | `pending`, `active`, `closed` |
| created_at | DateTime | Timestamp création |
| updated_at | DateTime | Timestamp modification |

**Relations:**
- OneToMany: Participants (cascade delete)
- OneToMany: Questions (cascade delete, ordonnées par position)

**Méthodes:**
- `get_active_question()` → Question active ou null
- `is_active()` → booléen

#### Question
| Champ | Type | Spec |
|-------|------|------|
| id | UUID/Int | Primary key |
| ag_session_id | FK | Foreign key vers AgSession |
| text | String | Texte de la question (requis) |
| position | Int | Ordre d'affichage |
| status | Enum | `pending`, `active`, `closed` |
| created_at | DateTime | Timestamp création |
| updated_at | DateTime | Timestamp modification |

**Relations:**
- ManyToOne: AgSession
- OneToMany: Choices (cascade delete, ordonnées par id)
- OneToMany: Votes (cascade delete)

**Méthodes:**
- `get_total_votes()` → Int
- `get_results()` → Array<{choice, count, percentage}>
- `get_other_free_texts()` → Array<String>

#### Choice
| Champ | Type | Spec |
|-------|------|------|
| id | UUID/Int | Primary key |
| question_id | FK | Foreign key vers Question |
| text | String | Texte du choix (requis) |
| is_other | Boolean | True si accepte texte libre |
| created_at | DateTime | Timestamp création |
| updated_at | DateTime | Timestamp modification |

**Relations:**
- ManyToOne: Question

**Scopes/Queries:**
- `where is_other = false` → choix normaux
- `where is_other = true` → choix "autre"

#### Participant
| Champ | Type | Spec |
|-------|------|------|
| id | UUID/Int | Primary key |
| ag_session_id | FK | Foreign key vers AgSession |
| name | String | Nom du participant (requis) |
| token | String | URL token unique (généré automatiquement) |
| claimed_at | DateTime | Timestamp de l'identification (nullable) |
| created_at | DateTime | Timestamp création |
| updated_at | DateTime | Timestamp modification |

**Relations:**
- ManyToOne: AgSession
- OneToMany: Votes (cascade delete)

**Méthodes:**
- `has_voted_on(question)` → booléen
- `is_claimed()` → booléen (claimed_at IS NOT NULL)
- `claim()` → set claimed_at = now()

**Constraints:**
- token UNIQUE
- (ag_session_id, token) UNIQUE

#### Vote
| Champ | Type | Spec |
|-------|------|------|
| id | UUID/Int | Primary key |
| participant_id | FK | Foreign key vers Participant |
| question_id | FK | Foreign key vers Question |
| choice_id | FK | Foreign key vers Choice |
| free_text | String | Texte libre saisi (nullable, requis si choice.is_other=true) |
| created_at | DateTime | Timestamp création |
| updated_at | DateTime | Timestamp modification |

**Relations:**
- ManyToOne: Participant
- ManyToOne: Question
- ManyToOne: Choice

**Constraints:**
- UNIQUE (participant_id, question_id) - un vote par participant par question
- FOREIGN KEY choice.question_id = question_id (intégrité référentielle)
- Validation: free_text IS NOT NULL si choice.is_other = true

## Fonctionnalités Participant

### Page d'identification (Shared Link)
- **Route:** `GET /ag/:session_token`
- **Fonctionnalité:** Liste des participants de la session avec boutons Rejoindre/Quitter
- **Flux:**
  1. Un lien unique par session est partagé (exemple: `/ag/ABC123`)
  2. Participant entre son nom
  3. Clique "Rejoindre" pour être ajouté à la session
  4. Reçoit un lien personnel `/vote/session_token/participant_token`
- **Quitter:** Bouton pour supprimer l'identité (unclaim) et rejoindre plus tard avec un nouveau token

### Salle d'attente (Waiting Room)
- **Affichage:** Avant que la session soit ouverte (`status: pending`)
- **Interface:**
  - Horloge animée ⏳ avec spinner
  - Message: "La session {name} n'a pas encore commencé"
  - Message en attente du démarrage
- **Mise à jour temps réel:** WebSocket reçoit les broadcasts via canal `session_status_{session_id}`

### Interface de vote (Voting Area)
- **Affichage:** Quand la session est `active`
- **Navigation:**
  - En haut: Nom de la session + Bonjour {participant}
  - Zone de vote avec la question active
  - Historique des questions clôturées (seulement leurs résultats)
- **Mise à jour temps réel:** WebSocket reçoit les updates de `voting_{participant_token}`

### Question active
- **Affichage:**
  - Texte de la question
  - Liste des choix (boutons radio ou texte libre)
  - Si "autre" sélectionné: champ libre requis
  - Message si déjà voté: "Vous avez déjà voté sur cette question"
- **Actions:**
  - Cliquer sur un choix
  - Si autre: entrer un texte libre
  - Bouton "Voter"
- **Validation côté client+serveur:**
  - Texte libre obligatoire pour choix "autre"
  - Le choix doit appartenir à la question
  - Un seul vote par participant par question
- **Après vote:**
  - Redirect vers la page de vote (affiche "Vous avez déjà voté")
  - Broadcast du nombre de votes à l'admin

### Historique des questions
- **Affichage:** Sous la question active
- **Contenu:** Toutes les questions `closed`
- **Pour chaque question fermée:**
  - Texte de la question
  - Résultats en barres (count et pourcentage)
  - Textes libres saisis (pour les "autre")

## Fonctionnalités Admin

### Authentification Admin
- **Route:** `GET /admin/login` (POST pour form)
- **Contrôle:** Simple session (pas de bcrypt actuellement)
- **Logout:** `DELETE /admin/logout`
- **Protection:** `before_action` en admin namespace

### Dashboard Admin
- **Route:** `GET /admin/`
- **Affichage:** Liste de toutes les sessions (ordonnées récentes d'abord)
- **Actions par session:**
  - Voir détails
  - Modifier
  - Ouvrir (change status `pending` → `active`, déclenche broadcast)
  - Fermer (change status `active` → `closed`)
  - Supprimer

### Détails session
- **Route:** `GET /admin/ag_sessions/:id`
- **Affichage:**
  - Informations de la session (nom, statut)
  - Liste des participants et leur statut (claimed/unclaimed)
  - Liste des questions (pending/active/closed)
  - Nombre de votes en direct pour la question active

### Création/Édition de session
- **Route:** `POST/PATCH /admin/ag_sessions` (GET pour formulaires)
- **Champs:** Nom de la session
- **Lien partagé:** Token généré automatiquement, peut être copié

### Gestion des participants
- **Route:** `POST /admin/ag_sessions/:id/participants` (create), `DELETE` (destroy)
- **Actions:**
  - Ajouter manuellement un participant
  - Supprimer un participant
  - Unclaim un participant (réinitialise son token de partage)

### Gestion des questions
- **Route:** `GET/POST/PATCH/DELETE /admin/ag_sessions/:id/questions`
- **Champs:**
  - Texte de la question
  - Position (ordre d'affichage)
  - Choix (nested form):
    - Texte du choix
    - Checkbox "Est un choix 'autre'" (accepte du texte libre)
    - Boutons ajouter/supprimer choix
- **Actions:**
  - Créer
  - Éditer (sauf si active)
  - Supprimer (sauf si active)
  - Activer (une seule question active à la fois; ferme les autres)
  - Clôturer (arrête le vote, affiche résultats aux participants)

### Vote Count Dashboard
- **Affichage:** Sur la page de détails de la session
- **Contenu:** Pour chaque question active
  - Nom de la question
  - Nombre de votes actuels / nombre de participants
  - Badge de statut (En attente / En cours / Clôturée)
- **Mise à jour temps réel:** WebSocket reçoit les updates de `admin_session_{session_id}`

## Temps Réel (WebSocket)

Les mises à jour en temps réel utilisent WebSocket. Implémentation possible:
- WebSocket natif (Socket.io, ws)
- Server-Sent Events (SSE) comme fallback
- GraphQL subscriptions

### Canaux WebSocket

#### 1. Canal: `voting_{participant_token}`
**Utilisateurs:** Participants de la session

**Messages:**
```json
{
  "type": "replace_voting_area",
  "data": {
    "active_question": { /* Question object ou null */ },
    "already_voted": boolean,
    "closed_questions": [ /* Array<Question> */ ],
    "session": { /* Session object */ },
    "participant": { /* Participant object */ }
  }
}
```

**Déclencheurs:**
- Admin active une question (PATCH /admin/.../questions/{id}/activate)
- Admin clôture une question (PATCH /admin/.../questions/{id}/close)
- Admin ouvre la session (PATCH /admin/.../open)

#### 2. Canal: `session_status_{session_id}`
**Utilisateurs:** Participants en salle d'attente

**Messages:**
```json
{
  "type": "replace_waiting_room",
  "data": {
    "session_status": "active",
    "active_question": { /* Question object */ }
  }
}
```

**Déclencheur:**
- Admin ouvre la session (status: pending → active)
- Remplace la salle d'attente par l'interface de vote

#### 3. Canal: `admin_session_{session_id}`
**Utilisateurs:** Administrateurs

**Messages:**
```json
{
  "type": "update_vote_count",
  "data": {
    "question_id": "...",
    "vote_count": 5,
    "participant_count": 10
  }
}
```

**Déclencheur:**
- Un participant soumet un vote (POST /vote/.../...

## API Endpoints

### Endpoints Publiques (Participants)

#### Identification page
```
GET /ag/{session_token}
Response: HTML page avec liste des participants et formulaire d'ajout
- Affiche: nom session, liste participants, formulaires
- Pas d'authentification requise
```

#### Rejoindre une session
```
POST /ag/{session_token}/claim
Body: { "name": "John Doe" }
Response: { "participant_token": "xyz...", "participant_id": "..." }
- Crée un nouveau Participant
- Génère un token unique
- Redirect vers /vote/{session_token}/{participant_token}
```

#### Quitter (unclaim)
```
PATCH /ag/{session_token}/{participant_token}/unclaim
Response: { "success": true }
- Set claimed_at = NULL
- Permet de rejoindre à nouveau plus tard
```

#### Page de vote
```
GET /vote/{session_token}/{participant_token}
Response: HTML page
- Si session.status != 'active': affiche salle d'attente
- Si session.status == 'active': affiche question active + historique
- Inclut WebSocket connection channel: voting_{participant_token}
```

#### Soumettre un vote
```
POST /vote/{session_token}/{participant_token}
Body: { "choice_id": "...", "free_text": "..." }
Response: { "success": true } ou { "errors": [...] }
- Validation: session.status == 'active'
- Validation: no existing vote for (participant, question)
- Validation: free_text required si choice.is_other = true
- Broadcast via WebSocket: vote_count pour admin
```

### Endpoints Admin

#### Authentification
```
GET /admin/login
Response: HTML page avec formulaire login

POST /admin/login
Body: { "password": "..." }
Response: Set-Cookie session; Redirect /admin/

DELETE /admin/logout
Response: Clear session; Redirect /
```

#### Dashboard sessions
```
GET /admin/
Response: HTML page
- Affiche: liste de toutes les sessions (triées récentes d'abord)
- Actions: View, Edit, Open, Close, Delete
```

#### CRUD Sessions
```
GET /admin/ag_sessions/new
Response: HTML formulaire création session

POST /admin/ag_sessions
Body: { "name": "..." }
Response: { "id": "...", "token": "...", "status": "pending" }

GET /admin/ag_sessions/{id}
Response: HTML page détails
- Affiche: infos session, liste participants, liste questions
- Affiche: vote count live pour question active
- WebSocket channel: admin_session_{session_id}

GET /admin/ag_sessions/{id}/edit
Response: HTML formulaire édition

PATCH /admin/ag_sessions/{id}
Body: { "name": "..." }
Response: { "success": true }

DELETE /admin/ag_sessions/{id}
Response: { "success": true }

PATCH /admin/ag_sessions/{id}/open
Response: { "status": "active" }
- Change status pending → active
- Broadcast: voting_area à tous les participants via canal session_status_{id}

PATCH /admin/ag_sessions/{id}/close
Response: { "status": "closed" }
- Change status active → closed
```

#### Gestion participants
```
POST /admin/ag_sessions/{id}/participants
Body: { "name": "..." }
Response: { "participant_id": "...", "token": "..." }
- Crée participant, génère token

DELETE /admin/ag_sessions/{id}/participants/{participant_id}
Response: { "success": true }
- Supprime participant et votes associés

PATCH /admin/ag_sessions/{id}/participants/{participant_id}/unclaim
Response: { "success": true }
- Set claimed_at = NULL
```

#### Gestion questions
```
GET /admin/ag_sessions/{id}/questions
Response: HTML page
- Affiche: toutes les questions avec actions

POST /admin/ag_sessions/{id}/questions
Body: {
  "text": "...",
  "position": 1,
  "choices": [
    { "text": "Yes", "is_other": false },
    { "text": "Other", "is_other": true }
  ]
}
Response: { "id": "...", "status": "pending" }

GET /admin/ag_sessions/{id}/questions/{question_id}/edit
Response: HTML formulaire édition

PATCH /admin/ag_sessions/{id}/questions/{question_id}
Body: { "text": "...", "position": 1, "choices": [...] }
Response: { "success": true }
- Validation: status != 'active' pour éditer

DELETE /admin/ag_sessions/{id}/questions/{question_id}
Response: { "success": true }
- Validation: status != 'active' pour supprimer

PATCH /admin/ag_sessions/{id}/questions/{question_id}/activate
Response: { "status": "active" }
- Change status pending → active
- Ferme toutes autres questions actives (status pending → closed)
- Broadcast: voting_area à tous les participants via canal voting_{participant_token}

PATCH /admin/ag_sessions/{id}/questions/{question_id}/close
Response: { "status": "closed" }
- Change status active → closed
- Broadcast: voting_area à tous les participants (affiche "En attente du prochain vote...")
```

## Stack Technologique (recommandé)

### Backend Options
- **Rails 8:** Ruby + ActiveRecord (implémentation actuelle)
- **Symfony 7:** PHP + Doctrine
- **Django 5:** Python + ORM
- **FastAPI:** Python + SQLAlchemy
- **Node.js:** Express/Fastify + TypeORM/Prisma
- **Go:** Gin/Echo + GORM

### Bases de données
- SQLite3 (développement)
- PostgreSQL (production recommandé)
- MySQL (alternatif)

### Frontend
- HTML5 (template engine du framework)
- CSS3 (responsive, breakpoints 768px et 480px)
- Vanilla JavaScript (ES6+)
  - WebSocket natif ou ws library
  - Fetch API pour requêtes HTTP
  - Pas de dépendance frontend majeure

### WebSocket
- **Native WebSocket API** (support navigateur moderne)
- **Socket.io** (fallback, reconnection auto)
- **Server-Sent Events (SSE)** (alternatif si WebSocket impossible)

### Optionnel
- **Docker:** Containerization
- **Tests:** Framework natif du langage (Jest, pytest, RSpec, PHPUnit)
- **Linting:** ESLint (JS), black/flake8 (Python), etc.
- **Cache:** Redis (optionnel, pour scale)

## Sécurité

- **Tokens:** URL tokens uniques par session/participant (format: alphanumeric 16+ chars, ex: base64)
- **CSRF Protection:** Implémentée selon framework (Rails CSRF, Django CSRF middleware, etc.)
- **Authentification Admin:** Session HTTP + password (hash avec bcrypt/argon2)
- **Validations:**
  - Côté serveur: chaque model valide ses données
  - Côté client: feedback utilisateur
- **Autorisation:**
  - Participants ne peuvent voter que sur sessions active
  - Participants ne peuvent voter qu'une fois par question
  - Admins protégés par session
- **Intégrité référentielle:**
  - Foreign keys avec cascade delete
  - Validation: choice.question_id == vote.question_id

## Persistance & State

- **Base de données:**
  - Tables: ag_sessions, questions, choices, participants, votes
  - Indexes: token (unique), participant_id+question_id (unique)
  - Contraintes: foreign keys, uniqueness
- **Tokens:** Générés à création (UUID ou SecureRandom), persistés en DB
- **Sessions HTTP:** Cookie pour admin (HttpOnly, Secure)
- **WebSocket:** Stateless, basé sur tokens URL (pas de session requise)

## Données de Test (optionnel)

Fixtures recommandées:
- **Sessions:** 1 active, 1 pending
- **Participants:** 3-5 par session (mix claimed/unclaimed)
- **Questions:** 2-3 par session (mix pending/active/closed)
- **Choices:** 3-4 par question (inclure min 1 "autre")
- **Votes:** Pré-remplis pour certains scénarios de test

## Déploiement

### Développement local
```bash
1. Installer le framework et dépendances
2. Créer base de données
3. Lancer migrations
4. Démarrer serveur web + WebSocket
5. Frontend: accéder http://localhost:3000
```

### Production
- Base de données: PostgreSQL recommandé
- Server web: framework-natif (Puma, Gunicorn, etc.)
- WebSocket: spécifique au framework (Action Cable, Channels, etc.)
- Reverse proxy: Nginx/Apache (SSL, compression, static files)
- Container: Docker optionnel
- CI/CD: GitHub Actions, GitLab CI, etc.

## Points clés pour régénération à l'identique

Checklist pour recréer le projet:

### Setup initial
1. Créer nouveau projet avec le framework choisi
2. Configurer base de données (schema ci-dessus)
3. Générer models: AgSession, Question, Choice, Participant, Vote

### Modèles
4. Ajouter relations (OneToMany, ManyToOne)
5. Ajouter validations et constraints
6. Ajouter méthodes métier (get_active_question, get_results, etc.)

### Authentification
7. Authentification admin: session HTTP + password
8. Identification participants: token URL

### API Endpoints
9. Implémenter endpoints (voir section "API Endpoints")
10. Validations: status checks, uniqueness, cascade delete

### Frontend
11. Pages HTML: identification, vote, admin dashboard
12. CSS responsive: 3 breakpoints (desktop, 768px, 480px)
13. Jeu 2048: implémentation JavaScript pur

### Temps réel
14. WebSocket: 3 canaux (voting_{token}, session_status_{id}, admin_session_{id})
15. Broadcasts: déclencher selon actions admin

### Testing
16. Tests unitaires: models + validations
17. Tests d'intégration: endpoints HTTP
18. Tests WebSocket: canaux et broadcasts
19. Tests browser: E2E voting flow

### Optionnel
20. Fixtures de test
21. Docker setup
22. CI/CD pipeline
23. Documentation API (Swagger/OpenAPI)
