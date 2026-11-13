#!/usr/bin/env bash
set -Eeuo pipefail
[[ $EUID -eq 0 ]] || exit 1
[[ -d /opt/clickhouse/backups ]] || { echo 'ClickHouse backup directory missing' >&2; exit 1; }
install -m 0700 "$PROJECT_DIR/templates/clickhouse-backup.sh" /usr/local/sbin/clickhouse-backup.sh
sed -i "s/^KEEP=.*/KEEP=$BACKUP_KEEP/; s/^MIN_FREE_GB=.*/MIN_FREE_GB=$MIN_FREE_GB/; s/^DB_NAME=.*/DB_NAME=$DB_NAME/" /usr/local/sbin/clickhouse-backup.sh
bash -n /usr/local/sbin/clickhouse-backup.sh
printf 'CRON_TZ=UTC\n0 %s * * * root /usr/local/sbin/clickhouse-backup.sh >> /var/log/clickhouse-backup.log 2>&1\n' "$BACKUP_HOUR_UTC" > /etc/cron.d/clickhouse-backup
chown root:root /etc/cron.d/clickhouse-backup
chmod 0644 /etc/cron.d/clickhouse-backup
systemctl enable --now cron
printf 'Daily backup scheduled at %s:00 UTC. Run backup script manually to verify.\n' "$BACKUP_HOUR_UTC"
