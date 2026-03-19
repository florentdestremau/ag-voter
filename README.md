# Votes AG

Application Rails de vote en assemblée générale d'association.

## Comment ça fonctionne

### Vue d'ensemble

L'application repose sur deux interfaces distinctes : une interface **admin** pour piloter la session, et une interface **participant** accessible via un lien personnel unique.

### Côté admin

L'admin accède à `/admin` avec un token de connexion (variable d'environnement `ADMIN_TOKEN`, valeur par défaut `admin-secret`).

Depuis le dashboard d'une session, l'admin :

1. **Crée une session** AG avec un nom (ex : "AG 2026 - Association XYZ")
2. **Ouvre la session** — un lien d'auto-identification devient actif, permettant aux participants de se déclarer eux-mêmes en début de séance
3. **Ajoute les participants** présents (nom uniquement) — chaque participant reçoit automatiquement un lien de vote personnel à partager
4. **Crée les questions** à soumettre au vote, avec leurs choix possibles. Un bouton "Pour / Contre / Abstention" pré-remplit les choix classiques. Chaque choix peut être marqué comme "champ libre" pour permettre une réponse texte
5. **Active les questions une par une** — une seule question peut être active à la fois. L'admin voit en temps réel le nombre de votes reçus
6. **Clôture le vote** — les résultats deviennent visibles pour tous les participants

### Côté participant

À l'ouverture de la session, l'admin partage un **lien d'auto-identification** (`/ag/:session_token`). Chaque personne présente peut y réclamer son nom dans la liste des participants, ce qui lui génère son lien de vote personnel.

Chaque participant accède ensuite à son lien personnel (`/vote/:session_token/:participant_token`).

Sa page se rafraîchit automatiquement toutes les 3 secondes :

- **En attente** → message "en attente du prochain vote"
- **Question active** → formulaire de vote avec les choix proposés. Si un choix "autre" est sélectionné, un champ texte libre apparaît
- **Vote enregistré** → confirmation, attente de la clôture
- **Question clôturée** → résultats anonymes avec barres de progression et pourcentages. Les réponses libres sont listées sans attribution

Les résultats sont **anonymes** : il est impossible de savoir qui a voté quoi.

---

## Lancer l'application

```bash
bundle install
bin/rails db:setup    # crée la base et charge les seeds de démo
bin/rails server
```

Admin : http://localhost:3000/admin/login
Token par défaut : `admin-secret`

Pour changer le token admin, définir la variable d'environnement `ADMIN_TOKEN`.

## Seeds de démo

`db/seeds.rb` crée une session avec 4 participants et 2 questions. Les liens de vote sont affichés dans la console au moment du seed.
