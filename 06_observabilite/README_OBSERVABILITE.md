# Observabilité

Démarrage :

```bash
cd 06_observabilite
docker compose -f docker-compose.observabilite.yml up -d
```

Accès :
- Prometheus : http://localhost:9090
- Grafana : http://localhost:3000
- cAdvisor : http://localhost:8082

Preuves à capturer : CPU/mémoire d'un conteneur CareHub, état des cibles Prometheus, tableau de bord Grafana, puis tableau DORA complété à partir de vos exécutions réelles.
