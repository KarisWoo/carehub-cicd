# 04 - Sécurité et gestion des secrets

## Inventaire des secrets

| Secret | Utilisation | Stockage recommandé | Injection |
|---|---|---|---|
| POSTGRES_PASSWORD | Mot de passe BDD | Secret GitHub pour CI/CD et fichier `.env` protégé sur VPS | Variable d'environnement au démarrage |
| VPS_HOST | Adresse du VPS | GitHub Actions Secrets | Action SSH |
| VPS_USER | Compte de déploiement | GitHub Actions Secrets | Action SSH |
| VPS_SSH_KEY | Clé privée de déploiement | GitHub Actions Secrets | Action SSH |
| GITHUB_TOKEN | Publication GHCR | Fourni automatiquement par GitHub Actions | Variable temporaire du job |

## Principes appliqués

1. Aucun secret réel n'est enregistré dans Git.
2. `.env.example` contient uniquement des valeurs factices.
3. Le fichier `.env` réel du VPS n'est jamais ajouté au dépôt.
4. Les images Docker ne contiennent aucun secret.
5. Le pipeline utilise `secrets.*` pour les valeurs sensibles.
6. Les journaux ne doivent jamais afficher un secret avec `echo`.

## Cycle de vie

- Création : secret généré avec une valeur forte et unique.
- Stockage : GitHub Actions Secrets ou coffre-fort de secrets de l'organisation.
- Injection : uniquement au moment de l'exécution.
- Rotation : renouvellement périodique ou immédiatement après suspicion de compromission.
- Révocation : suppression de l'ancien secret après validation du nouveau.

## Procédure de renouvellement de POSTGRES_PASSWORD

1. Générer un nouveau mot de passe fort.
2. Mettre à jour la valeur sur le serveur cible sans la commiter.
3. Modifier le mot de passe du compte PostgreSQL.
4. Redémarrer les services applicatifs avec la nouvelle valeur.
5. Vérifier `/health`.
6. Supprimer/révoquer l'ancienne valeur.

## Contrôle de sécurité bloquant

Le script `scripts/security-check.sh` bloque le pipeline si :
- une image utilise `:latest` ;
- un secret évident est écrit en clair ;
- aucun `healthcheck` n'est présent.

La politique `policy/compose.rego` ajoute un contrôle Conftest et constitue la règle personnalisée demandée : interdiction du tag flottant `:latest`.

## Remédiation démontrable

Échec volontaire :

```bash
bash scripts/security-check.sh scripts/bad-compose.yml
```

Résultat attendu : échec avec détection du tag `:latest` et/ou du secret en clair.

Succès après correction :

```bash
bash scripts/security-check.sh 02_conteneurisation/docker-compose.yml
```

Résultat attendu : `OK: contrôle de sécurité réussi`.
