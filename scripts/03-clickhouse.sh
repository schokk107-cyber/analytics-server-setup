#!/usr/bin/env bash
set -Eeuo pipefail
[[ $EUID -eq 0 ]] || exit 1
BASE=/opt/clickhouse
if [[ -e "$BASE/compose.yaml" ]]; then
  echo "Refusing to overwrite existing $BASE/compose.yaml. Configure manually." >&2
  exit 1
fi
[[ ! -e "$BASE/.env" ]] || { echo 'Existing .env detected; refusing to overwrite' >&2; exit 1; }
install -d -m 0755 "$BASE" "$BASE/config"
install -d -m 0700 "$BASE/data" "$BASE/logs" "$BASE/backups"
chown 101:101 "$BASE/data" "$BASE/logs" "$BASE/backups"
install -m 0644 "$PROJECT_DIR/templates/compose.yaml" "$BASE/compose.yaml"
install -m 0644 "$PROJECT_DIR/templates/backups.xml" "$BASE/config/backups.xml"
# DB password never appears in stdout or git.
DB_PASSWORD=$(openssl rand -hex 24)
(umask 077; printf 'DB_NAME=%s\nDB_USER=%s\nCLICKHOUSE_VERSION=%s\nCLICKHOUSE_PASSWORD=%s\n' "$DB_NAME" "$DB_USER" "$CLICKHOUSE_VERSION" "$DB_PASSWORD" > "$BASE/.env")
cd "$BASE"
docker compose config --quiet
docker compose up -d
printf 'ClickHouse deployed. Credentials stored in %s/.env (root only).\n' "$BASE"
