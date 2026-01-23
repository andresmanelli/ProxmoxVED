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
setup_php "8"
setup_mariadb "12"
pkg_install curl wget git nginx php-fpm php-bcmath php8.4-dom php-gd php-json php-mbstring php-mcrypt php8.4-mysql php-xml php-xmlrpc

msg_ok "Installed Dependencies"

msg_info "Setting up Database"
DB_NAME=invoiceplane
DB_USER=invoiceplane
DB_PORT=3306
DB_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
$STD mariadb -u root -e "CREATE DATABASE $DB_NAME;"
$STD mariadb -u root -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED WITH mysql_native_password AS PASSWORD('$DB_PASS');"
$STD mariadb -u root -e "GRANT ALL ON $DB_NAME.* TO '$DB_USER'@'localhost'; FLUSH PRIVILEGES;"
{
  echo "${APPLICATION} Credentials"
  echo "Database User: $DB_USER"
  echo "Database Password: $DB_PASS"
  echo "Database Name: $DB_NAME"
} >>~/invoiceplane.creds
msg_ok "Set up Database"

# Setup App
msg_info "Setup ${APPLICATION}"
RELEASE=$(curl -fsSL https://api.github.com/repos/InvoicePlane/InvoicePlane/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
curl -fsSL -o "v${RELEASE}.zip" "https://github.com/InvoicePlane/InvoicePlane/archive/refs/tags/v${RELEASE}.zip"
unzip -q "v${RELEASE}.zip"
mv "${APPLICATION}-${RELEASE}/" "/opt/${APPLICATION}"
echo "v${RELEASE}" >/opt/${APPLICATION}_version.txt

cat > /etc/nginx/sites-available/invoiceplane <<EOF
server {
    root /opt/${APPLICATION};
    index index.php index.html index.htm;

    listen 80;

    client_max_body_size 100M;

    error_log /var/log/nginx/invoiceplane.nginx.error.log warn;
    access_log /var/log/nginx/invoiceplane.nginx.access.log;

    location / {
        try_files \$uri \$uri/ /index.php?q=\$uri&\$args;
    }

    location ~ \.php$ {
        include fastcgi.conf;
        fastcgi_pass unix:/var/run/php/php-fpm.sock;
        fastcgi_param SCRIPT_NAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }
}
EOF
rm /etc/nginx/sites-enabled/default
ln -s /etc/nginx/sites-available/invoiceplane /etc/nginx/sites-enabled/invoiceplane
nginx -s reload

cp /opt/${APPLICATION}/ipconfig.php.example /opt/${APPLICATION}/ipconfig.php
sed -i "s|IP_URL=.*|IP_URL=http://$(get_current_ip())|" /opt/${APPLICATION}/ipconfig.php
sed -i "s/DB_HOSTNAME=.*/DB_HOSTNAME=localhost/" /opt/${APPLICATION}/ipconfig.php
sed -i "s/DB_USERNAME=.*/DB_USERNAME=${DB_USER}/" /opt/${APPLICATION}/ipconfig.php
sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=${DB_PASS}/" /opt/${APPLICATION}/ipconfig.php
sed -i "s/DB_DATABASE=.*/DB_DATABASE=${DB_NAME}/" /opt/${APPLICATION}/ipconfig.php
sed -i "s/DB_PORT=.*/DB_PORT=${DB_PORT}/" /opt/${APPLICATION}/ipconfig.php

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
