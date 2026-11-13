#!/usr/bin/env bash
set -Eeuo pipefail
[[ $EUID -eq 0 ]] || { echo 'Run as root (sudo)' >&2; exit 1; }
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y ca-certificates curl gnupg git openssh-server ufw cron util-linux openssl
systemctl enable --now ssh cron
if ! id "$APP_USER" >/dev/null 2>&1; then
  adduser --disabled-password --gecos '' "$APP_USER"
fi
usermod -aG sudo "$APP_USER"
echo "System ready. User: $APP_USER"
echo 'SSH keys and firewall are NOT changed automatically; see docs/SECURITY.md.'
