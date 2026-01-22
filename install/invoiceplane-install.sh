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
pkg_update
pkg_install curl wget git nginx
msg_ok "Installed Dependencies"

setup_php "8.3"
setup_mariadb "11"

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
fetch_and_deploy_gh_release "${APPLICATION}" "InvoicePlane/InvoicePlane" "tarball"
RELEASE=$(curl -fsSL https://api.github.com/repos/InvoicePlane/InvoicePlane/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
echo "${RELEASE}" >/opt/${APPLICATION}_version.txt

cat > /etc/nginx/blocks/invoiceplane <<EOF
server {
    root /opt/${APPLICATION};
    index  index.php index.html index.htm;

    listen 80;

    client_max_body_size 100M;

    server_name invoiceplane.localhost;

    error_log /var/log/nginx/invoiceplane.nginx.error.log warn;
    access_log /var/log/nginx/invoiceplane.nginx.access.log main;

    location / {
        try_files $uri $uri/ /index.php?q=$uri&$args;
    }

    location ~ \.php$ {
        include fastcgi.conf;
        fastcgi_pass unix:/var/run/php-fpm8/php-fpm.sock;
        fastcgi_param SCRIPT_NAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }
}
EOF

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
cleanup_lxc
