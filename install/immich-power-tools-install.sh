#!/usr/bin/env bash
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Mark Rickert (markrickert)
# License: MIT | https://github.com/community-scripts/ProxmoxVED/raw/main/LICENSE
# Source: https://github.com/immich-power-tools/immich-power-tools

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

read -r -p "Enter Immich server IP address (e.g. 192.168.1.100): " IMMICH_IP
read -r -p "Enter Immich port [2283]: " IMMICH_PORT
IMMICH_PORT="${IMMICH_PORT:-2283}"
read -r -p "Enter Immich API Key (Account Settings > API Keys in Immich): " IMMICH_API_KEY
read -r -p "Enter Immich PostgreSQL password (DB_PASSWORD from your Immich .env): " DB_PASSWORD
IMMICH_URL="http://${IMMICH_IP}:${IMMICH_PORT}"
DB_HOST="${IMMICH_IP}"

NODE_VERSION="22" setup_nodejs

msg_info "Installing Bun"
export BUN_INSTALL="/root/.bun"
curl -fsSL https://bun.sh/install | $STD bash
ln -sf /root/.bun/bin/bun /usr/local/bin/bun
ln -sf /root/.bun/bin/bunx /usr/local/bin/bunx
msg_ok "Installed Bun"

fetch_and_deploy_gh_release "immich-power-tools" "immich-power-tools/immich-power-tools" "tarball"

msg_info "Configuring Immich Power Tools"
JWT_SECRET=$(openssl rand -base64 32)
mkdir -p /opt/immich-power-tools/data
cat <<EOF >/opt/immich-power-tools/.env
IMMICH_URL=${IMMICH_URL}
IMMICH_API_KEY=${IMMICH_API_KEY}
EXTERNAL_IMMICH_URL=${IMMICH_URL}
DB_HOST=${DB_HOST}
DB_PORT=5432
DB_USERNAME=immich
DB_PASSWORD=${DB_PASSWORD}
DB_DATABASE_NAME=immich
JWT_SECRET=${JWT_SECRET}
APP_DB_PATH=/opt/immich-power-tools/data/app.db
NEXT_TELEMETRY_DISABLED=1
EOF
msg_ok "Configured Immich Power Tools"

msg_info "Building Immich Power Tools (Patience)"
cd /opt/immich-power-tools
$STD bun install
$STD npm run build
msg_ok "Built Immich Power Tools"

msg_info "Running Database Migrations"
$STD npm run db:migrate
msg_ok "Ran Database Migrations"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/immich-power-tools.service
[Unit]
Description=Immich Power Tools
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/immich-power-tools
EnvironmentFile=/opt/immich-power-tools/.env
ExecStart=/usr/bin/npm run start
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now immich-power-tools
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
