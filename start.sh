#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NETWORK_NAME="keycloak-django-network"

if [ -f "$ROOT_DIR/.env" ]; then
  set -a
  # shellcheck disable=SC1091
  source "$ROOT_DIR/.env"
  set +a
fi

KEYCLOAK_HTTP_PORT="${KEYCLOAK_HTTP_PORT:-8080}"
export KEYCLOAK_HTTP_PORT

log() {
  printf '[start.sh] %s\n' "$1"
}

require_docker() {
  if ! command -v docker >/dev/null 2>&1; then
    echo "Docker is required but not installed." >&2
    exit 1
  fi
  if ! docker compose version >/dev/null 2>&1; then
    echo "Docker Compose plugin is required." >&2
    exit 1
  fi
}

check_port() {
  if command -v ss >/dev/null 2>&1 && ss -tln | grep -q ":${KEYCLOAK_HTTP_PORT} "; then
    echo "Port ${KEYCLOAK_HTTP_PORT} is already in use." >&2
    echo "Stop the other service or run: KEYCLOAK_HTTP_PORT=8180 ./start.sh" >&2
    exit 1
  fi
}

create_network() {
  if ! docker network inspect "$NETWORK_NAME" >/dev/null 2>&1; then
    log "Creating shared Docker network: $NETWORK_NAME"
    docker network create "$NETWORK_NAME"
  fi
}

wait_for_service() {
  local service="$1"
  local compose_file="$2"
  local attempts="${3:-60}"
  local delay="${4:-5}"

  log "Waiting for $service to become healthy..."
  for _ in $(seq 1 "$attempts"); do
    if docker compose -f "$compose_file" ps --status running "$service" | grep -q "(healthy)"; then
      log "$service is healthy"
      return 0
    fi
    sleep "$delay"
  done

  echo "Timed out waiting for $service." >&2
  docker compose -f "$compose_file" ps
  exit 1
}

start_keycloak() {
  log "Starting Keycloak stack (Keycloak + PostgreSQL)..."
  docker compose -f "$ROOT_DIR/compose/keycloak.yml" up -d --build
  wait_for_service keycloak "$ROOT_DIR/compose/keycloak.yml" 30 5
}

start_django() {
  log "Starting Django stack (Django + PostgreSQL)..."
  docker compose -f "$ROOT_DIR/compose/django.yml" up -d --build
  wait_for_service django "$ROOT_DIR/compose/django.yml" 24 5
}

print_summary() {
  cat <<EOF

Services are running:

  Keycloak Admin:  http://localhost:${KEYCLOAK_HTTP_PORT}/admin/
                   user: admin / password: admin

  Keycloak Realm:  tutorial
  Demo user:       demo / demo
  Admin user:      admin / admin

  Django app:      http://localhost:8000/
  Login:           http://localhost:8000/oidc/authenticate/
  Profile API:     http://localhost:8000/api/profile/

Run unit tests locally:

  cd django_app
  python -m venv .venv && source .venv/bin/activate
  pip install -r requirements.txt
  python manage.py test

Stop everything:

  ./stop.sh

EOF
}

main() {
  require_docker
  check_port
  create_network
  start_keycloak
  start_django
  print_summary
}

main "$@"
