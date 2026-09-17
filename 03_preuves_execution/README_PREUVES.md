# 03_preuves_execution — Dossier de preuves complet

Ce dossier regroupe les preuves réelles obtenues pendant l'épreuve CareHub. Les captures sont ciblées et anonymisées : aucun nom, adresse e-mail, identifiant de compte personnel ou URL de dépôt personnel n'est nécessaire à leur compréhension.

## 1. Sécurité CI/CD — échec bloquant puis remédiation

### `01_controle_securite_echec_trivy.png`
**Ce que la capture prouve :** le contrôle de sécurité Trivy détecte des vulnérabilités de sévérité élevée et termine le job avec un code de sortie `1`. Le contrôle est donc réellement bloquant.

### `02_details_cve_openssl_avant_remediation.png`
**Ce que la capture prouve :** détail des vulnérabilités détectées avant remédiation, avec sévérité, version installée et version corrigée proposée.

### `03_pipeline_securite_reussie_apres_remediation.png`
**Ce que la capture prouve :** après remédiation, les tests Python 3.11 et 3.12 et la construction/sécurité passent. Le pipeline atteint ensuite le déploiement production.

## 2. Conteneurisation et continuité de service

### `04_scaling_3_instances_healthy.png`
**Ce que la capture prouve :** exécution de Docker Compose avec `--scale app=3`. Les trois instances `app-1`, `app-2`, `app-3` sont `healthy`; la base et le proxy sont également opérationnels.

### `05_application_disponible_apres_scaling.png`
**Ce que la capture prouve :** l'application reste disponible après la montée en charge. La réponse HTTP locale renvoie `status: ok`.

## 3. Limite du déploiement VPS

### `06_limitation_deploiement_vps_missing_host.png`
**Ce que la capture prouve :** le workflow arrive à l'étape SSH puis échoue sur `missing server host`. Aucun VPS externe n'était disponible pendant l'épreuve. La création d'un VPS chez les fournisseurs consultés nécessitait une offre payante. Cette limite est explicitement déclarée dans le README principal plutôt que masquée.

## 4. Observabilité — Prometheus, cAdvisor et Grafana

### `07_observabilite_stack_prometheus_grafana_cadvisor.png`
**Ce que la capture prouve :** démarrage de la pile d'observabilité Docker avec Prometheus, Grafana et cAdvisor, ainsi que leurs ports d'exposition.

### `08_prometheus_target_cadvisor_up.png`
**Ce que la capture prouve :** Prometheus collecte réellement la cible `cadvisor:8080/metrics`; la cible est `UP`.

### `09_cadvisor_cpu_memoire.png`
**Ce que la capture prouve :** cAdvisor remonte les métriques d'exploitation CPU et mémoire des conteneurs.

### `10_cadvisor_reseau.png`
**Ce que la capture prouve :** cAdvisor remonte les métriques réseau (octets TX/RX) et le suivi des erreurs réseau.

### `11_grafana_cpu_conteneurs.png`
**Ce que la capture prouve :** Grafana interroge Prometheus avec la requête CPU `sum(rate(container_cpu_usage_seconds_total[1m]))` et affiche une série temporelle réelle.

### `12_grafana_reseau_entrant.png`
**Ce que la capture prouve :** Grafana interroge Prometheus avec la requête réseau `sum(rate(container_network_receive_bytes_total[1m]))` et affiche les variations du trafic entrant.

### `13_grafana_dashboards.png`
**Ce que la capture prouve :** trois tableaux de bord de supervision ont été créés pour la mémoire, le trafic réseau et le CPU des conteneurs.

## Correspondance avec les exigences de l'épreuve

| Exigence | Preuve(s) |
|---|---|
| Contrôle de sécurité bloquant | 01, 02 |
| Réussite après remédiation | 03 |
| Tests et construction CI/CD | 03 |
| Mise à l'échelle du service | 04 |
| Maintien de disponibilité | 05 |
| Déploiement VPS | Limitation documentée : 06 |
| Supervision / observabilité | 07 à 13 |
| CPU / mémoire / réseau | 09 à 12 |

## Limites assumées

Le déploiement réel sur VPS et l'application accessible sur une adresse publique n'ont pas été réalisés. Il n'est donc pas possible de fournir une capture authentique de production ni de calculer honnêtement des indicateurs DORA dépendant d'un déploiement de production réussi (par exemple le lead time jusqu'à la production). Aucune valeur n'est inventée.
