#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/andresmanelli/ProxmoxVED/refs/heads/invoice_plane/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: andresmanelli
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: http://github.com/InvoicePlane/InvoicePlane

# App Default Values
# Name of the app (e.g. Google, Adventurelog, Apache-Guacamole"
APP="InvoicePlane"
# Tags for Proxmox VE, maximum 2 pcs., no spaces allowed, separated by a semicolon ; (e.g. database | adblock;dhcp)
var_tags="${var_tags:-invoicing;finance}"
# Number of cores (1-X) (e.g. 4) - default are 2
var_cpu="${var_cpu:-1}"
# Amount of used RAM in MB (e.g. 2048 or 4096)
var_ram="${var_ram:-512}"
# Amount of used disk space in GB (e.g. 4 or 10)
var_disk="${var_disk:-2}"
# Default OS (e.g. debian, ubuntu, alpine)
var_os="${var_os:-debian}"
# Default OS version (e.g. 12 for debian, 24.04 for ubuntu, 3.20 for alpine)
var_version="${var_version:-12}"
# 1 = unprivileged container, 0 = privileged container
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

#function update_script() {
#  header_info
#  check_container_storage
#  check_container_resources
#
#  # Check if installation is present | -f for file, -d for folder
#  if [[ ! -f /opt/invoiceplane/ipconfig.php ]]; then
#    msg_error "No ${APP} Installation Found!"
#    exit
#  fi
#
#  # Crawling the new version and checking whether an update is required
#  RELEASE=$(curl -fsSL [RELEASE_URL] | [PARSE_RELEASE_COMMAND])
#  if [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]] || [[ ! -f /opt/${APP}_version.txt ]]; then
#    # Stopping Services
#    msg_info "Stopping $APP"
#    systemctl stop [SERVICE_NAME]
#    msg_ok "Stopped $APP"
#
#    # Creating Backup
#    msg_info "Creating Backup"
#    tar -czf "/opt/${APP}_backup_$(date +%F).tar.gz" [IMPORTANT_PATHS]
#    msg_ok "Backup Created"
#
#    # Execute Update
#    msg_info "Updating $APP to v${RELEASE}"
#    [UPDATE_COMMANDS]
#    msg_ok "Updated $APP to v${RELEASE}"
#
#    # Starting Services
#    msg_info "Starting $APP"
#    systemctl start [SERVICE_NAME]
#    msg_ok "Started $APP"
#
#    # Cleaning up
#    msg_info "Cleaning Up"
#    rm -rf [TEMP_FILES]
#    msg_ok "Cleanup Completed"
#
#    # Last Action
#    echo "${RELEASE}" >/opt/${APP}_version.txt
#    msg_ok "Update Successful"
#  else
#    msg_ok "No update required. ${APP} is already at v${RELEASE}"
#  fi
#  exit
#}

function update_script() {
    header_info
    check_container_storage
    check_container_resources
    if [[ ! -d /opt/snipeit ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi
    msg_error "Currently we don't provide an update function for this ${APP}."
    exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}${CL}"
