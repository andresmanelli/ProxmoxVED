#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: andresmanelli
# License: MIT | https://github.com/community-scripts/ProxmoxVED/raw/main/LICENSE
# Source: http://github.com/InvoicePlane/InvoicePlane

# Import Functions und Setup
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

# Installing Dependencies
msg_info "Installing Dependencies"
#$STD apt-get install -y
msg_ok "Installed Dependencies"

# setup_php
# setup => database driver

# Template: MySQL Database
msg_info "Setting up Database"
DB_NAME=invoiceplane
DB_USER=invoiceplane
DB_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
$STD mysql -u root -e "CREATE DATABASE $DB_NAME;"
$STD mysql -u root -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED WITH mysql_native_password AS PASSWORD('$DB_PASS');"
$STD mysql -u root -e "GRANT ALL ON $DB_NAME.* TO '$DB_USER'@'localhost'; FLUSH PRIVILEGES;"
{
  echo "${APPLICATION} Credentials"
  echo "Database User: $DB_USER"
  echo "Database Password: $DB_PASS"
  echo "Database Name: $DB_NAME"
} >>~/invoiceplane.creds
msg_ok "Set up Database"

# Setup App
msg_info "Setup ${APPLICATION}"
RELEASE=$(curl -fsSL https://api.github.com/repos/InvoicePlane/InvoicePlane/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
curl -fsSL -o "${RELEASE}.zip" "https://github.com/InvoicePlane/InvoicePlane/archive/refs/tags/${RELEASE}.zip"
unzip -q "${RELEASE}.zip"
mv "${APPLICATION}-${RELEASE}/" "/opt/${APPLICATION}"
#
#
#
echo "${RELEASE}" >/opt/"${APPLICATION}"_version.txt
msg_ok "Setup ${APPLICATION}"

# Creating Service (if needed)
#msg_info "Creating Service"
#cat <<EOF >/etc/systemd/system/"${APPLICATION}".service
#[Unit]
#Description=${APPLICATION} Service
#After=network.target
#
#[Service]
#ExecStart=[START_COMMAND]
#Restart=always
#
#[Install]
#WantedBy=multi-user.target
#EOF
#systemctl enable -q --now "${APPLICATION}"
#msg_ok "Created Service"

motd_ssh
customize

# Cleanup
msg_info "Cleaning up"
rm -f "${RELEASE}".zip
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
