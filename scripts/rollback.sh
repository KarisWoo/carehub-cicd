#!/usr/bin/env bash
set -euo pipefail
: "${PREVIOUS_IMAGE:?Définir PREVIOUS_IMAGE, ex: ghcr.io/org/carehub:abc1234}"
cd "$(dirname "$0")/../02_conteneurisation"
export CAREHUB_IMAGE="$PREVIOUS_IMAGE"
docker compose --env-file .env -f docker-compose.yml -f docker-compose.prod.yml pull app
docker compose --env-file .env -f docker-compose.yml -f docker-compose.prod.yml up -d --no-deps app
sleep 5
curl --fail --silent http://127.0.0.1:${APP_PORT:-80}/health >/dev/null
echo "Rollback réussi vers $PREVIOUS_IMAGE"
