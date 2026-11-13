#!/usr/bin/env bash
set -Eeuo pipefail
printf '\nDocker:\n'; docker --version; docker compose version
printf '\nClickHouse container:\n'; docker compose -f /opt/clickhouse/compose.yaml --env-file /opt/clickhouse/.env ps
printf '\nClickHouse version:\n'; docker exec clickhouse clickhouse-client --query 'SELECT version()'
printf '\nDatabases:\n'; docker exec clickhouse clickhouse-client --query 'SHOW DATABASES'
printf '\nFirewall:\n'; ufw status verbose || true
printf '\nCron:\n'; systemctl is-active cron; cat /etc/cron.d/clickhouse-backup
printf '\nDisk:\n'; df -h /opt/clickhouse
