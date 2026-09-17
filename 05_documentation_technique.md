# 05 - Documentation technique CareHub

## 1. Chaîne du commit à la production

```text
Développeur
   |
   v
Git push / Pull Request
   |
   v
GitHub Actions
   |-- Tests unitaires
   |-- Détection de secrets (Gitleaks)
   |-- Contrôle personnalisé de conformité
   |-- Conftest / OPA
   |-- Build Docker
   |-- Scan Trivy
   |-- SBOM
   |-- Publication GHCR
   |-- Signature Cosign
   v
Déploiement VPS par SSH
   |
   v
Docker Compose
   |-- Nginx
   |-- Application CareHub x N
   |-- PostgreSQL
   v
Healthcheck + supervision
```

## 2. Portabilité dev / recette / production

Le même `Dockerfile` et le même `docker-compose.yml` sont utilisés partout. Les différences sont externalisées dans des variables d'environnement : port, nom de base, image, ressources, environnement applicatif et secrets.

Aucune valeur d'environnement métier n'est figée dans l'image. Les exemples se trouvent dans :
- `.env.dev.example`
- `.env.recette.example`
- `.env.prod.example`

Commande de démarrage :

```bash
cd 02_conteneurisation
cp .env.example .env
# Modifier POSTGRES_PASSWORD dans .env
docker compose --env-file .env up -d --build
```

## 3. Dépendances et santé

PostgreSQL expose un healthcheck basé sur `pg_isready`.
L'application ne démarre qu'après l'état sain de PostgreSQL.
Nginx ne démarre qu'après l'état sain de l'application.

Cela évite les temporisations arbitraires du type `sleep 30` pour gérer les dépendances.

## 4. Persistance

Les données PostgreSQL utilisent le volume nommé `carehub_db_data`. Les données applicatives ne reposent pas sur la couche écrivable d'un conteneur.

## 5. Ressources

Hypothèse de charge : portail hospitalier de rendez-vous avec trafic modéré, principalement HTTP et requêtes SQL simples.

Valeurs initiales :
- Application : 0,50 CPU / 256 Mio en dev, jusqu'à 1 CPU / 512 Mio en production.
- PostgreSQL : 0,50 CPU / 512 Mio en dev, jusqu'à 1 CPU / 1 Gio en production.
- Nginx : 0,25 CPU / 128 Mio.

Ces valeurs servent de point de départ. Elles doivent être ajustées à partir des mesures cAdvisor/Prometheus lors d'un test de charge.

## 6. Mise à l'échelle

Exemple de montée à 3 instances :

```bash
cd 02_conteneurisation
docker compose --env-file .env up -d --scale app=3
```

Le proxy Nginx distribue les requêtes vers le service `app`. La base de données reste unique et persistante.

Règle proposée :
- 1 instance en charge normale ;
- passer à 2 instances si CPU applicatif > 70 % pendant 5 minutes ;
- passer à 3 instances si CPU > 80 % ou hausse soutenue des temps de réponse ;
- redescendre après 15 minutes sous 40 %.

Avec Docker Compose seul, cette règle est documentée et appliquée manuellement. Une évolution vers Kubernetes/Swarm permettrait l'autoscaling automatique.

## 7. Continuité pendant une mise à jour

Approche : plusieurs instances applicatives derrière Nginx, puis remplacement progressif. En environnement Docker Compose simple, la continuité dépend du maintien d'au moins une instance saine pendant le remplacement.

Procédure de démonstration :
1. Monter à 2 instances.
2. Lancer une boucle `curl` sur l'URL publique.
3. Construire/publier la nouvelle image.
4. Redéployer l'application.
5. Vérifier que les requêtes continuent de répondre.

Pour un vrai déploiement rolling automatisé garanti, l'évolution recommandée est Kubernetes ou Docker Swarm avec `update_config`.

## 8. Retour arrière

Chaque image est taguée avec le SHA du commit, ce qui rend une version précisément identifiable.

Rollback :

```bash
export PREVIOUS_IMAGE=ghcr.io/ORG/carehub:<ancien_sha>
bash scripts/rollback.sh
```

Le script redéploie l'image précédente et vérifie le healthcheck.

## 9. Sécurité DevOps

Contrôles intégrés :
- Gitleaks : secrets ;
- contrôle personnalisé shell ;
- Conftest/OPA : conformité du fichier Compose ;
- Trivy : vulnérabilités HIGH/CRITICAL ;
- SBOM SPDX ;
- Cosign : signature de l'image ;
- image construite avec utilisateur non-root ;
- tags d'image traçables au SHA du commit.

## 10. Observabilité

Le dossier `06_observabilite/` contient Prometheus, cAdvisor et Grafana. Les métriques CPU/mémoire sont utilisées pour justifier les limites de ressources et les décisions de scaling.

## 11. Limites et pistes d'évolution

- Docker Compose ne fournit pas un autoscaling natif complet.
- Le déploiement SSH peut évoluer vers un runner auto-hébergé ou GitOps.
- Les secrets peuvent être migrés vers Vault ou un secret manager cloud.
- Ajouter SAST, DAST et tests de charge automatisés.
- Ajouter sauvegarde et test de restauration PostgreSQL.
