# AG-Voter - Features Documentation

Une application de vote en temps réel avec gestion participative et jeu 2048 en salle d'attente.

## Vue d'ensemble

AG-Voter est une application Rails 8 permettant à un administrateur de créer des sessions de vote, de poser des questions avec des choix de réponse, et aux participants de voter en temps réel. Les résultats sont affichés instantanément à l'administrateur via Turbo Streams (WebSocket).

## Architecture générale

- **Frontend:** Rails 8 + Hotwire (Turbo + Stimulus)
- **Backend:** Rails 8 + SQLite3
- **Temps réel:** Action Cable + Turbo Streams
- **Authentification Admin:** Session simple avec mot de passe
- **Identification Participants:** Tokens URL uniques par participant

## Modèles de données

### AgSession
- **Statuts:** `pending`, `active`, `closed`
- **Attributes:** `name`, `token` (généré automatiquement)
- **Relations:**
  - `has_many :participants` (avec `dependent: :destroy`)
  - `has_many :questions` (ordonnées par position, avec `dependent: :destroy`)
- **Méthodes:**
  - `active_question` - retourne la question actuellement active
  - `active?` - booléen si le statut est actif

### Question
- **Statuts:** `pending`, `active`, `closed`
- **Attributes:** `text`, `position`, `status`, `ag_session_id`
- **Relations:**
  - `belongs_to :ag_session`
  - `has_many :choices` (ordonnées par id, avec `dependent: :destroy`)
  - `has_many :votes` (avec `dependent: :destroy`)
- **Méthodes:**
  - `total_votes` - nombre total de votes sur cette question
  - `results` - tableau avec résultats par choix (count, pourcentage)
  - `other_free_texts` - textes libres saisis pour le choix "autre"
- **Features:**
  - `accepts_nested_attributes_for :choices` (rejet des blancs, destruction autorisée)

### Choice
- **Attributes:** `text`, `is_other` (booléen), `question_id`
- **Relations:** `belongs_to :question`
- **Scopes:**
  - `regular` - choix normaux (`is_other: false`)
  - `other` - choix "autre" (`is_other: true`)

### Participant
- **Attributes:** `name`, `token` (généré automatiquement), `claimed_at`, `ag_session_id`
- **Relations:**
  - `belongs_to :ag_session`
  - `has_many :votes` (avec `dependent: :destroy`)
- **Méthodes:**
  - `voted_on?(question)` - booléen si le participant a voté sur cette question
  - `claimed?` - booléen si le participant s'est identifié
  - `claim!` - enregistre l'identification (timestamp `claimed_at`)

### Vote
- **Attributes:** `free_text`, `participant_id`, `question_id`, `choice_id`
- **Relations:**
  - `belongs_to :participant`
  - `belongs_to :question`
  - `belongs_to :choice`
- **Validations:**
  - `participant_id` unique par `question_id` (un vote par question)
  - `free_text` requis si le choix est "autre"
  - Validation custom: le choix doit appartenir à la question

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
  - Jeu 2048 intégré pour divertissement
  - Message en attente du démarrage
- **Mise à jour temps réel:** Turbo Streams reçoit les broadcasts de `session_status_{session_id}`

### Interface de vote (Voting Area)
- **Affichage:** Quand la session est `active`
- **Navigation:**
  - En haut: Nom de la session + Bonjour {participant}
  - Zone de vote avec la question active
  - Historique des questions clôturées (seulement leurs résultats)
- **Mise à jour temps réel:** Turbo Streams reçoit les updates de `voting_{participant_token}`

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
- **Mise à jour temps réel:** Turbo Streams reçoit les updates de `admin_session_{session_id}`

## Fonctionnalités Temps Réel (Turbo Streams)

### Canaux d'Action Cable

**1. Participants qui voient la question changer**
- **Canal:** `voting_{participant_token}`
- **Déclencheurs:**
  - Admin active une question → broadcast `replace` de `voting_area`
  - Admin clôture une question → broadcast `replace` de `voting_area`
- **Contenu:** Partial `voting/_voting_area` avec les variables:
  - `active_question`
  - `already_voted`
  - `closed_questions`
  - `session`
  - `participant`

**2. Participant voit la transition waiting room → voting area**
- **Canal:** `session_status_{session_id}`
- **Déclencheur:** Admin ouvre la session (`open` action)
- **Contenu:** Broadcast `replace` du partial `voting/_voting_area`
  - Remplace la salle d'attente
  - Affiche la première question (ou "En attente du prochain vote...")

**3. Admin voit les votes s'incrémenter**
- **Canal:** `admin_session_{session_id}`
- **Déclencheur:** Un participant vote (via `broadcast_vote_count` dans `VotingController#create`)
- **Contenu:** Broadcast `replace` du partial `admin/questions/_vote_count`
  - ID cible: `question_{question_id}_vote_count`
  - Affiche le nombre de votes actuel

## Jeu 2048 en Salle d'Attente

### Intégration
- **Emplacement:** Dans le partial `voting/_waiting_room.html.erb`
- **Affichage:** Sur mobile et desktop

### Mécaniques
- **Plateau:** 4×4
- **Tuiles:** Valeurs 2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048+
- **Spawn:** Nouvelles tuiles (90% = 2, 10% = 4) à chaque coup

### Contrôles
- **Desktop:** Flèches clavier (↑ ↓ ← →)
- **Mobile:**
  - Swipe (gestures) - seuil 30px pour éviter les faux positifs
  - Boutons fléchés visuels (fallback pour Chrome Android)
- **Reset:** Bouton "Nouveau jeu"

### Score
- **Calcul:** +valeur_tuile à chaque fusion
- **Affichage:** En temps réel sous les contrôles

### Responsive
- **Desktop (>768px):** Plateau 280×280px
- **Tablette/Mobile (≤768px):** Plateau 240×240px
- **Petit mobile (≤480px):** Plateau 200×200px

## Routes

### Routes Publiques (Participants)
```
GET  /ag/:session_token                          → Identification#show (page d'identification)
POST /ag/:session_token/claim                    → Identification#claim
GET  /vote/:session_token/:participant_token     → Voting#show (salle attente ou vote)
POST /vote/:session_token/:participant_token     → Voting#create (soumettre un vote)
```

### Routes Admin
```
GET    /admin/login                              → Admin::Sessions#new
POST   /admin/login                              → Admin::Sessions#create
DELETE /admin/logout                             → Admin::Sessions#destroy

GET    /admin                                    → Admin::AgSessions#index
GET    /admin/ag_sessions/new                    → Admin::AgSessions#new
POST   /admin/ag_sessions                        → Admin::AgSessions#create
GET    /admin/ag_sessions/:id                    → Admin::AgSessions#show
GET    /admin/ag_sessions/:id/edit               → Admin::AgSessions#edit
PATCH  /admin/ag_sessions/:id                    → Admin::AgSessions#update
DELETE /admin/ag_sessions/:id                    → Admin::AgSessions#destroy
PATCH  /admin/ag_sessions/:id/open               → Admin::AgSessions#open
PATCH  /admin/ag_sessions/:id/close              → Admin::AgSessions#close

POST   /admin/ag_sessions/:id/participants       → Admin::Participants#create
DELETE /admin/ag_sessions/:id/participants/:id   → Admin::Participants#destroy
PATCH  /admin/ag_sessions/:id/participants/:id/unclaim → Admin::Participants#unclaim

GET    /admin/ag_sessions/:id/questions          → Admin::Questions#index
GET    /admin/ag_sessions/:id/questions/new      → Admin::Questions#new
POST   /admin/ag_sessions/:id/questions          → Admin::Questions#create
GET    /admin/ag_sessions/:id/questions/:id/edit → Admin::Questions#edit
PATCH  /admin/ag_sessions/:id/questions/:id      → Admin::Questions#update
DELETE /admin/ag_sessions/:id/questions/:id      → Admin::Questions#destroy
PATCH  /admin/ag_sessions/:id/questions/:id/activate → Admin::Questions#activate
PATCH  /admin/ag_sessions/:id/questions/:id/close    → Admin::Questions#close
```

## Stack Technologique

### Framework & Core
- **Rails:** 8.1.1
- **Ruby:** 3.4+
- **Database:** SQLite3 (2.1+)
- **Server:** Puma (5.0+)

### Frontend
- **Hotwire Turbo:** Page transitions sans reload, Turbo Frames pour lazy loading
- **Hotwire Stimulus:** Contrôleurs JavaScript pour interactions
- **ImportMap Rails:** Gestion ES modules
- **CSS:** Inline styles (pas de framework)

### Temps Réel
- **Action Cable:** WebSocket pour Turbo Streams
- **Solid Cable:** Adapateur de base de données pour ActionCable

### Infrastructure
- **Solid Cache:** Cache via SQLite
- **Solid Queue:** Queue asynchrone (pour futures features)
- **Thruster:** Compression et optimisation Puma
- **Kamal:** Déploiement Docker

### Tests
- **Capybara:** Tests d'intégration browser
- **Selenium WebDriver:** Driver browser
- **MiniTest:** Framework test (inclus dans Rails)

### Qualité de Code
- **Brakeman:** Analyse sécurité
- **Bundler Audit:** Audit des gems
- **RuboCop Rails Omakase:** Linting/Formatting

## Sécurité

- **Tokens:** URLs uniques par session/participant (SecureRandom.urlsafe_base64)
- **CSRF:** Rails CSRF tokens (inclus par défaut)
- **Validations:** Chaque modèle valide ses données
- **Uniqueness:** Chaque participant ne peut voter qu'une fois par question
- **Contrôle d'accès:** Routes admin protégées par session

## Persistance & State

- **Base de données:** SQLite3 (adhérente au projet, simple à setup)
- **Tokens:** Générés à la création, persistés en DB
- **Sessions:** HTTP sessions pour admin, tokens URL pour participants
- **Action Cable:** Utilise Solid Cable (DB-backed)

## Données de Test

Fixtures fournies:
- **Sessions:** `active_session` (status: active), `pending_session` (status: pending)
- **Participants:** `alice` (claimed), `bob` (unclaimed), `charlie` (unclaimed sur pending_session)
- **Questions:** `active_question`, `closed_question`
- **Choices:** `pour`, `contre`, `autre`
- **Votes:** Pre-populated pour certains scénarios

## Déploiement

- **Docker:** Support via Kamal + Thruster
- **Volumes:** SQLite3 persist à `/data`
- **Assets:** Propshaft pour build
- **Health check:** `/up` endpoint pour container orchestration

## Points clés pour régénération

Pour régénérer ce projet à l'identique:

1. Rails 8.1 nouveau projet
2. Installer gems (Turbo, Stimulus, Solid*, Kamal, Thruster)
3. Générer models: AgSession, Question, Choice, Participant, Vote
4. Associations et validations selon spec ci-dessus
5. Routes selon liste ci-dessus
6. Contrôleurs et vues (considérer les Turbo Streams)
7. Ajouter Turbo Streams broadcasts dans les controllers
8. Css inline pour responsive (breakpoints 768px et 480px)
9. Jeu 2048 en JavaScript pur (pas de gem)
10. Tests d'intégration avec fixtures
