#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVED/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Mark Rickert (markrickert)
# License: MIT | https://github.com/community-scripts/ProxmoxVED/raw/main/LICENSE
# Source: https://github.com/immich-power-tools/immich-power-tools

APP="Immich-Power-Tools"
var_tags="${var_tags:-images;tools}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-4}"
var_os="${var_os:-debian}"
var_version="${var_version:-12}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /opt/immich-power-tools ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
  if check_for_gh_release "immich-power-tools" "immich-power-tools/immich-power-tools"; then
    msg_info "Stopping ${APP} Service"
    systemctl stop immich-power-tools
    msg_ok "Stopped ${APP} Service"
    cp /opt/immich-power-tools/.env /opt/immich-power-tools.env.bak
    fetch_and_deploy_gh_release "immich-power-tools" "immich-power-tools/immich-power-tools" "tarball"
    cp /opt/immich-power-tools.env.bak /opt/immich-power-tools/.env
    cd /opt/immich-power-tools
    $STD /usr/local/bin/bun install
    $STD npm run build
    $STD npm run db:migrate
    msg_info "Starting ${APP} Service"
    systemctl start immich-power-tools
    msg_ok "Started ${APP} Service"
    msg_ok "Updated ${APP} successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL}"
echo -e "${INFO}${YW} To update configuration, edit:${CL}"
echo -e "${TAB}${BGN}/opt/immich-power-tools/.env${CL}"
echo -e "${TAB}then run: ${BGN}systemctl restart immich-power-tools${CL}"
