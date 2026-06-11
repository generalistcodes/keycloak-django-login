#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

docker compose -f "$ROOT_DIR/compose/django.yml" down
docker compose -f "$ROOT_DIR/compose/keycloak.yml" down

if docker network inspect keycloak-django-network >/dev/null 2>&1; then
  docker network rm keycloak-django-network || true
fi

echo "All services stopped."
