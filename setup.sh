#!/bin/bash

# Check if the user has sudo rights
if [ $(id -u) -ne 0 ]; then
    echo "You need sudo rights to run this script."
    exit 1
fi

# List of packages to install
packages=(
    package1
    package2
    package3
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

echo "Adding PHP repository..."
sudo add-apt-repository -y ppa:ondrej/php

echo "Installing packages..."
for package in "${packages[@]}"
do
    sudo apt install -y "$package"
done

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
sudo cp /tmp/ioncube/ioncube_loader_lin_7.2.so /usr/local/ioncube

echo "Configuring ionCube loaders..."
# Add ionCube configuration to PHP configuration file (e.g., /etc/php/7.2/cli/php.ini)
echo "zend_extension=/usr/local/ioncube/ioncube_loader_lin_7.2.so" | sudo tee -a /etc/php/7.2/cli/php.ini

echo "Restarting PHP-FPM..."
sudo systemctl restart php7.2-fpm

echo "Cloning ProxCP repository..."
git clone https://github.com/Jurgens92/ProxCP.git /tmp/proxcp_temp

echo "Creating /var/www/proxcp directory..."
sudo mkdir -p /var/www/proxcp

echo "Moving ProxCP content to /var/www/proxcp..."
sudo mv /tmp/proxcp_temp/web/* /var/www/proxcp/
sudo rm -r /tmp/proxcp_temp

echo "Installing PHP 7.2 and necessary extensions..."
sudo apt-get install -y php7.2 php7.2-fpm php7.2-mysql php7.2-gd php7.2-curl php7.2-mbstring php7.2-xml php7.2-json php7.2-zip php7.2-openssl php7.2-xmlrpc php7.2-iconv php7.2-intl sendmail

echo "Setting up Nginx for ProxCP..."
sudo tee /etc/nginx/sites-available/proxcp <<EOF
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    # Try these filenames when no file specified in URL
    index index.php index.html index.htm;

    # Rewrite / to index
    rewrite ^/$ /index permanent;

    # Do PHP with no extension
    location / {
        try_files \$uri @ext;
    }
    location ~ \/\.php {
        rewrite "^(.*)\/.php" \$1.php last;
    }
    location @ext {
        rewrite "^(.*)$" \$1.php;
    }

    # Support PHP
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php7.2-fpm.sock;
    }

    # Main content
    root /var/www/proxcp;

    location ~ /\.ht {
        deny all;
    }
}
EOF

echo "Setting default site to ProxCP..."
sudo rm /etc/nginx/sites-enabled/default
sudo ln -s /etc/nginx/sites-available/proxcp /etc/nginx/sites-enabled/

echo "Restarting Nginx..."
sudo systemctl restart nginx

echo "All packages installed, MariaDB setup completed, ionCube loaders configured, PHP 7.2 installed with necessary extensions, and Nginx configured to serve ProxCP as the default site."
