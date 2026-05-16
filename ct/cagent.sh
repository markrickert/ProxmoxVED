#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVED/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Mark Rickert (markrickert)
# License: MIT | https://github.com/community-scripts/ProxmoxVED/raw/main/LICENSE
# Source: https://docs.claude.com/en/docs/claude-code

APP="Cagent"
var_tags="${var_tags:-ai;dev-tools;agentic}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-10240}"
var_disk="${var_disk:-30}"
var_os="${var_os:-ubuntu}"
var_version="${var_version:-24.04}"
var_unprivileged="${var_unprivileged:-0}"
var_keyctl="${var_keyctl:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -f /usr/local/bin/claude && ! -f /root/.local/bin/claude ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  msg_info "Updating ${APP} LXC"
  $STD apt update
  $STD apt -y upgrade
  msg_ok "Updated ${APP} LXC"
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Enter the container and run:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}claude${CL}"
echo -e "${INFO}${YW} Code Server is available at:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8443${CL}"
echo -e "${INFO}${YW} Credentials saved to ~/cagent.creds inside the LXC.${CL}"
