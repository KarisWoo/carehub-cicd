#!/usr/bin/env bash
set -euo pipefail
FILE="${1:-02_conteneurisation/docker-compose.yml}"

echo "[SECURITY] Analyse de $FILE"
if grep -Eq 'image:[[:space:]]+[^#[:space:]]+:latest([[:space:]]|$)' "$FILE"; then
  echo "ECHEC: tag :latest détecté"
  exit 1
fi
if grep -Eq '(password|secret|token):[[:space:]]+[A-Za-z0-9_-]{8,}' "$FILE"; then
  echo "ECHEC: secret potentiellement écrit en clair"
  exit 1
fi
if ! grep -q 'healthcheck:' "$FILE"; then
  echo "ECHEC: aucun healthcheck détecté"
  exit 1
fi

echo "OK: contrôle de sécurité réussi"
