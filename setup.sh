#!/bin/bash

# List of packages to install
packages=(
    nginx
    software-properties-common
    git
    # Add more packages here if needed
)

DB_NAME="proxcp_db"
DB_USER="proxcp_user"
DB_PASSWORD="your_password"  # Replace with your desired password

echo "Updating package lists..."
sudo apt update

echo "Installing packages..."
for package in "${packages[@]}"
do
    sudo apt install -y "$package"
done

echo "Adding PHP repository..."
sudo add-apt-repository -y ppa:ondrej/php

echo "Adding MariaDB repository..."
sudo apt-get install -y software-properties-common
sudo apt-key adv --fetch-keys 'https://mariadb.org/mariadb_release_signing_key.asc'
sudo add-apt-repository 'deb [arch=amd64,arm64,ppc64el] http://sfo1.mirrors.digitalocean.com/mariadb/repo/10.6/ubuntu focal main'

echo "Installing MariaDB..."
sudo apt-get update
sudo apt-get install -y mariadb-server

echo "Setting up MariaDB..."
sudo mariadb <<EOF
CREATE DATABASE $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASSWORD';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
EXIT;
EOF

echo "Downloading ionCube loaders..."
# Replace '/tmp/ioncube' with the directory where you placed the ionCube loaders.
sudo mkdir -p /usr/local/ioncube
cd /tmp
$ wget https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz
tar -zxvf ioncube_loaders_lin_x86*
sudo cp /tmp/ioncube/ioncube_loader_lin_7.2.so /usr/local/ioncube

echo "Configuring ionCube loaders..."
# Add ionCube configuration to PHP configuration file (e.g., /etc/php/7.2/cli/php.ini)
echo "zend_extension=/usr/local/ioncube/ioncube_loader_lin_7.2.so" | sudo tee -a /etc/php/7.2/cli/php.ini

echo "Cloning ProxCP repository..."
git clone https://github.com/Jurgens92/ProxCP.git

echo "All packages installed, MariaDB setup completed, and ionCube loaders configured."
