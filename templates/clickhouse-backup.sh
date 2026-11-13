#!/usr/bin/env bash
set -Eeuo pipefail
BACKUP_DIR=/opt/clickhouse/backups
DB_NAME=analytics
KEEP=7
MIN_FREE_GB=10
exec 9>/run/lock/clickhouse-backup.lock
flock -n 9 || { echo 'Backup already running'; exit 1; }
FREE_KB=$(df -Pk "$BACKUP_DIR" | awk 'NR==2 {print $4}')
(( FREE_KB >= MIN_FREE_GB * 1024 * 1024 )) || { echo 'Insufficient free disk space'; exit 1; }
NAME="analytics_$(date -u +%Y%m%d_%H%M%S).zip"
echo "Starting backup: $NAME"
docker exec clickhouse clickhouse-client --query "BACKUP DATABASE \`$DB_NAME\` TO File('/backups/$NAME')"
test -s "$BACKUP_DIR/$NAME"
echo 'Backup created successfully.'
mapfile -t OLD < <(find "$BACKUP_DIR" -maxdepth 1 -type f -name 'analytics_*.zip' -printf '%f\n' | sort -r | tail -n +$((KEEP+1)))
for file in "${OLD[@]}"; do rm -- "$BACKUP_DIR/$file"; echo "Removed old backup: $file"; done
echo 'Backup completed.'
