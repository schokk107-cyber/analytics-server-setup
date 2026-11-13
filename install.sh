#!/usr/bin/env bash
set -Eeuo pipefail
[[ $EUID -eq 0 ]] || { echo 'Use sudo ./install.sh' >&2; exit 1; }
PROJECT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
export PROJECT_DIR
[[ -f "$PROJECT_DIR/config.env" ]] || { echo 'Copy config.env.example to config.env and edit it first.' >&2; exit 1; }
# shellcheck disable=SC1091
source "$PROJECT_DIR/config.env"
: "${APP_USER:?}" "${DB_NAME:?}" "${DB_USER:?}" "${CLICKHOUSE_VERSION:?}" "${BACKUP_HOUR_UTC:?}" "${BACKUP_KEEP:?}" "${MIN_FREE_GB:?}"
[[ $APP_USER =~ ^[a-z_][a-z0-9_-]*$ ]] || exit 1
[[ $DB_NAME =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || exit 1
[[ $DB_USER =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || exit 1
[[ $BACKUP_HOUR_UTC =~ ^([0-9]|1[0-9]|2[0-3])$ ]] || exit 1
[[ $BACKUP_KEEP =~ ^[1-9][0-9]*$ && $MIN_FREE_GB =~ ^[1-9][0-9]*$ ]] || exit 1
export APP_USER DB_NAME DB_USER CLICKHOUSE_VERSION BACKUP_HOUR_UTC BACKUP_KEEP MIN_FREE_GB
printf 'Choose step: 1=system, 2=docker, 3=clickhouse, 4=backups, 5=verify, all=1-5\n'
read -r -p 'Step: ' STEP
run_step() { bash "$PROJECT_DIR/scripts/$1"; }
case "$STEP" in
  1) run_step 01-system.sh;;
  2) run_step 02-docker.sh;;
  3) run_step 03-clickhouse.sh;;
  4) run_step 04-backups.sh;;
  5) run_step 05-verify.sh;;
  all) for f in 01-system.sh 02-docker.sh 03-clickhouse.sh 04-backups.sh 05-verify.sh; do run_step "$f"; done;;
  *) echo 'Invalid step' >&2; exit 1;;
esac
