# EC06 CareHub - CI/CD

> Rendu anonyme : ne pas ajouter de nom, prénom, e-mail, compte personnel ou URL personnelle dans cette archive ni dans les captures.

## 1. Présentation

Cette solution industrialise le déploiement du portail CareHub avec :
- conteneurisation Docker ;
- orchestration Docker Compose ;
- pipeline CI/CD GitHub Actions ;
- tests et seuil de couverture ;
- détection de secrets ;
- contrôle de conformité bloquant ;
- scan de vulnérabilités ;
- génération de SBOM ;
- signature d'image ;
- publication d'une image taguée par SHA de commit ;
- déploiement automatisé sur VPS ;
- healthchecks, ressources, scaling et rollback ;
- observabilité Prometheus / cAdvisor / Grafana.

## 2. Prérequis

Pour l'exécution locale :
- Docker Engine ;
- Docker Compose v2 ;
- Git ;
- facultatif : Python 3.11/3.12 pour exécuter les tests hors conteneur.

Pour la CI/CD :
- un dépôt GitHub ;
- GitHub Actions activé ;
- GitHub Container Registry (GHCR) ;
- un VPS Linux avec Docker et Docker Compose ;
- secrets GitHub configurés pour le déploiement.

## 3. Commande unique de démarrage

```bash
cd 02_conteneurisation
cp .env.example .env
```

Modifier ensuite `POSTGRES_PASSWORD` dans `.env`, puis :

```bash
docker compose --env-file .env up -d --build
```

L'application est disponible par défaut sur :

```text
http://localhost:8080/
http://localhost:8080/health
```

Arrêt :

```bash
docker compose --env-file .env down
```

## 4. Environnements

Les différences entre développement, recette et production sont externalisées :

- `02_conteneurisation/.env.dev.example`
- `02_conteneurisation/.env.recette.example`
- `02_conteneurisation/.env.prod.example`

Aucune valeur spécifique d'environnement n'est figée dans le Dockerfile.

Exemple :

```bash
cp .env.dev.example .env
docker compose --env-file .env up -d --build
```

## 5. Architecture

```text
Utilisateur
    |
    v
Nginx :8080
    |
    +------> app #1 :8000
    +------> app #2 :8000   (scaling)
    +------> app #3 :8000
                  |
                  v
             PostgreSQL
             volume nommé
```

Réseaux :
- `frontend` : Nginx <-> application ;
- `backend` : application <-> PostgreSQL, réseau interne.

## 6. Healthchecks et dépendances

- PostgreSQL : `pg_isready` ;
- application : `/health` ;
- proxy : `/nginx-health`.

L'application attend que PostgreSQL soit sain. Le proxy attend que l'application soit saine.

## 7. Ressources

Valeurs de départ configurables par variables :
- application : 256 Mio / 0,50 CPU en développement ;
- PostgreSQL : 512 Mio / 0,50 CPU ;
- Nginx : 128 Mio / 0,25 CPU.

Les valeurs de production proposées sont plus élevées et doivent être ajustées selon les métriques réelles.

## 8. Mise à l'échelle

```bash
cd 02_conteneurisation
docker compose --env-file .env up -d --scale app=3
docker compose ps
```

Règle proposée : augmenter le nombre d'instances si l'utilisation CPU applicative reste supérieure à 70 % pendant 5 minutes ; réduire après stabilisation sous 40 % pendant 15 minutes.

Docker Compose n'applique pas seul un autoscaling automatique : la règle est documentée et démontrée manuellement. Une évolution vers Kubernetes ou Swarm est proposée pour l'autoscaling natif.

## 9. Pipeline CI/CD

Workflow : `.github/workflows/ci-cd.yml`

Étapes :
1. Checkout.
2. Matrice Python 3.11 / 3.12.
3. Tests unitaires.
4. Seuil de couverture de 40 %.
5. Détection de secrets avec Gitleaks.
6. Contrôle bloquant personnalisé.
7. Contrôle Conftest / OPA.
8. Build Docker.
9. Scan Trivy HIGH / CRITICAL.
10. Publication GHCR avec tag `github.sha`.
11. Génération SBOM SPDX JSON.
12. Signature Cosign keyless.
13. Déploiement production via SSH.
14. Vérification post-déploiement `/health`.

## 10. Protection de branche

À configurer dans GitHub pour `main` :
- Pull Request obligatoire avant fusion ;
- exiger les checks `quality` et `security-build` ;
- interdire le push direct ;
- exiger une branche à jour avant fusion ;
- facultatif : une approbation minimum.

Cette protection se configure dans l'interface GitHub et ne peut pas être prouvée uniquement par un fichier du dépôt : faire une capture anonymisée de la règle.

## 11. Hooks de pré-commit

Le fichier `.pre-commit-config.yaml` active Gitleaks avant commit.

Installation :

```bash
pip install pre-commit
pre-commit install
pre-commit run --all-files
```

## 12. Contrôle de sécurité bloquant

Échec volontaire :

```bash
bash scripts/security-check.sh scripts/bad-compose.yml
```

Succès après remédiation :

```bash
bash scripts/security-check.sh 02_conteneurisation/docker-compose.yml
```

La règle personnalisée OPA interdit également les tags `:latest` et exige des healthchecks sur les services critiques.

## 13. Secrets GitHub nécessaires

À créer dans `Settings > Secrets and variables > Actions` :
- `VPS_HOST`
- `VPS_USER`
- `VPS_SSH_KEY`

Le `GITHUB_TOKEN` est fourni automatiquement par GitHub Actions.

Sur le VPS, le fichier `/opt/carehub/.env` contient les valeurs de production. Ce fichier ne doit jamais être commité.

## 14. Préparation du VPS

Exemple :

```bash
sudo mkdir -p /opt/carehub
sudo chown "$USER":"$USER" /opt/carehub
cd /opt/carehub
```

Copier le projet sur le VPS, créer le fichier `.env` à partir de `.env.prod.example`, puis vérifier :

```bash
docker compose --env-file .env -f 02_conteneurisation/docker-compose.yml -f 02_conteneurisation/docker-compose.prod.yml config
```

## 14.1 Limitation rencontrée - déploiement VPS non réalisé

Le déploiement en production sur un VPS n'a pas pu être réalisé pendant l'épreuve. Aucun VPS externe n'était disponible et la création d'un serveur VPS chez les fournisseurs consultés nécessitait la souscription à une offre payante. En conséquence, aucune adresse IP publique de serveur ni aucun accès SSH de déploiement n'étaient disponibles pour renseigner les secrets `VPS_HOST`, `VPS_USER` et `VPS_SSH_KEY`.

Le pipeline de déploiement via SSH est néanmoins configuré et prêt à être utilisé dès qu'un VPS est disponible. Les tests Python et les contrôles de sécurité ont pu être exécutés ; le job de déploiement s'arrête au moment de la connexion SSH avec l'erreur `missing server host`, faute de valeur `VPS_HOST`. Aucune valeur fictive ni aucun secret inventé n'a été ajouté au dépôt afin de conserver un rendu cohérent et sécurisé.

Cette limitation est donc explicitement assumée et documentée. La procédure de préparation du VPS, les secrets attendus et la stratégie de rollback restent décrits dans le projet afin de montrer comment le déploiement serait finalisé dans un environnement disposant d'un serveur cible.

## 15. Rollback

Les images sont taguées avec le SHA du commit. Pour revenir à une version précédente :

```bash
export PREVIOUS_IMAGE=ghcr.io/ORG/carehub:ANCIEN_SHA
bash scripts/rollback.sh
```

Le script redéploie l'image indiquée puis exécute un contrôle de santé.

## 16. Observabilité

```bash
cd 06_observabilite
docker compose -f docker-compose.observabilite.yml up -d
```

Services :
- Prometheus : port 9090 ;
- Grafana : port 3000 ;
- cAdvisor : port 8082.

Le fichier `06_observabilite/INDICATEURS_DORA.md` explique comment calculer au minimum la fréquence de déploiement et le Lead Time for Changes avec les exécutions réelles.

## 17. Dossier de preuves

Voir `03_preuves_execution/README_PREUVES.md`.

Important : les captures doivent être issues de vos propres exécutions. Aucune capture ni valeur DORA ne doit être inventée.

## 18. Deux faiblesses identifiées de la chaîne

1. Le déploiement repose sur SSH vers un VPS : cette méthode est simple mais moins robuste qu'une approche GitOps ou un runner de déploiement dédié.
2. Docker Compose ne fournit pas l'autoscaling natif ni un véritable rolling update orchestré comparable à Kubernetes/Swarm.

## 19. Structure du rendu

```text
README.md
01_pipeline/
02_conteneurisation/
03_preuves_execution/
04_securite_secrets.md
05_documentation_technique.md
06_observabilite/
```

Les fichiers `.github/workflows/`, `app/`, `tests/`, `scripts/` et `policy/` sont nécessaires au fonctionnement et accompagnent les éléments demandés.

## 20. Déclaration obligatoire d'utilisation de l'IA

### Outil utilisé
- ChatGPT, plateforme Web.

### Périmètre d'utilisation
L'outil d'IA a été utilisé pour aider à structurer le projet, proposer des exemples de configuration Docker / Docker Compose, construire un exemple de pipeline CI/CD, rédiger une politique de conformité et organiser la documentation technique.

### Prompts majeurs / démarche de Context Engineering
- Analyse du sujet EC06 CareHub et de l'arborescence de rendu demandée.
- Proposition d'une chaîne CI/CD simple mais complète couvrant tests, sécurité, construction, publication, signature et déploiement.
- Proposition d'une stratégie de gestion des secrets, de scaling, de rollback et d'observabilité.

### Audit et validation des réponses IA
Les propositions générées ont été relues avant intégration. Les points vérifiés sont notamment :
- absence de secret réel dans les fichiers versionnés ;
- utilisation de versions d'images explicites ;
- présence de healthchecks ;
- persistance PostgreSQL sur volume nommé ;
- séparation des réseaux ;
- exécution du conteneur applicatif avec un utilisateur non-root ;
- blocage du pipeline en cas de contrôle de sécurité en échec ;
- traçabilité de l'image par SHA de commit ;
- limites connues de Docker Compose pour l'autoscaling et le rolling update.

Les éléments dépendant d'un environnement réel (captures GitHub Actions, accès VPS, métriques et indicateurs DORA) doivent être validés par exécution réelle avant remise.
