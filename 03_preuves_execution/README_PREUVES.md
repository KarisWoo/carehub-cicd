# 03 - Dossier de preuves d'exécution

Ce dossier doit contenir VOS captures et journaux réels. Les fichiers de preuve ne doivent pas être inventés.

## Captures obligatoires à produire

1. `01_pipeline_echec_securite.png`
   - Exécution GitHub Actions en échec à cause du contrôle de sécurité.

2. `02_pipeline_reussi.png`
   - Même pipeline après remédiation, tous les jobs importants au vert.

3. `03_build_scan_sbom.png`
   - Build Docker + scan Trivy + génération SBOM.

4. `04_image_signee.png`
   - Sortie Cosign ou preuve de signature de l'image.

5. `05_deploiement_vps.png`
   - Déploiement automatique réussi sur le VPS.

6. `06_application_en_ligne.png`
   - Navigateur ou `curl` montrant l'application CareHub accessible.

7. `07_scaling.png`
   - `docker compose ps` montrant plusieurs instances de `app`.

8. `08_continuite_service.png`
   - Boucle de requêtes HTTP pendant une mise à jour/scaling.

9. `09_prometheus_targets.png`
   - Cibles Prometheus actives.

10. `10_grafana_cpu_ram.png`
   - CPU et mémoire visibles sur un tableau de bord.

11. `11_dora.png`
   - Tableau DORA complété à partir des exécutions réelles.

## Commandes utiles pour produire les preuves

```bash
# Contrôle bloquant volontaire
bash scripts/security-check.sh scripts/bad-compose.yml

# Contrôle réussi
bash scripts/security-check.sh 02_conteneurisation/docker-compose.yml

# Démarrage
cd 02_conteneurisation
docker compose --env-file .env up -d --build

# Etat / santé
docker compose ps
curl -i http://localhost:8080/health

# Scaling
docker compose --env-file .env up -d --scale app=3
docker compose ps

# Continuité : lancer pendant le scaling/déploiement
while true; do date; curl -fsS http://localhost:8080/; echo; sleep 1; done
```

N'oubliez pas d'anonymiser toutes les captures : aucun nom, prénom, e-mail, compte personnel ou URL personnelle visible.
