#!/bin/bash

# Check if the user has sudo rights
if [ $(id -u) -ne 0 ]; then
    echo "You need sudo rights to run this script."
    exit 1
fi

# List of packages to install
packages=(
    nginx
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


echo "Installing PHP 7.2 and necessary extensions..."
sudo apt-get install -y php7.2 
sudo apt-get install -y php7.2-fpm 
sudo apt-get install -y php7.2-mysql 
sudo apt-get install -y php7.2-gd 
sudo apt-get install -y php7.2-curl 
sudo apt-get install -y php7.2-mbstring 
sudo apt-get install -y php7.2-xml 
sudo apt-get install -y php7.2-json 
#sudo apt-get install -y php7.2-zip 
#sudo apt-get install -y php7.2-openssl 
#sudo apt-get install -y php7.2-xmlrpc
sudo apt-get install -y php7.2-iconv 
#sudo apt-get install -y php7.2-intl sendmail
sudo apt-get install -y certbot python3-certbot-nginx

#echo "Restarting PHP-FPM..."
#sudo systemctl restart php7.2-fpm


echo "Downloading ionCube loaders..."
# Replace '/tmp/ioncube' with the directory where you placed the ionCube loaders.
cd /tmp
wget https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz
tar -zxvf ioncube_loaders_lin_x86*
sudo mkdir -p /usr/local/ioncube
sudo cp /tmp/ioncube/ioncube_loader_lin_7.2.so /usr/local/ioncube

echo "Configuring ionCube loaders..."
# Add ionCube configuration to PHP configuration file (e.g., /etc/php/7.2/cli/php.ini)
echo "zend_extension=/usr/local/ioncube/ioncube_loader_lin_7.2.so" | sudo tee -a /etc/php/7.2/cli/php.ini

echo "Cloning ProxCP repository..."
git clone https://github.com/Jurgens92/ProxCP.git /tmp/proxcp_temp

echo "Creating /var/www/proxcp directory..."
sudo mkdir -p /var/www/proxcp

echo "Moving ProxCP content to /var/www/proxcp..."
sudo mv /tmp/proxcp_temp/web/* /var/www/proxcp/
sudo rm -r /tmp/proxcp_temp



echo "Setting up Nginx for ProxCP..."
sudo tee /etc/nginx/sites-available/proxcp <<EOF
server {
    listen 80;
    listen [::]:80;
	
	# Rename to your fqdn
	server_name cloud.itwindow.co.za

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
#sudo rm /etc/nginx/sites-enabled/default
sudo ln -s /etc/nginx/sites-available/proxcp /etc/nginx/sites-enabled/


# somehow, something is installing apache... wtf
echo "removing apache"
sudo service apache2 stop
sudo apt-get purge apache2 apache2-utils apache2.2-bin apache2-common
sudo apt-get autoremove
sudo rm -rf /etc/apache2  

echo "Restarting Nginx..."
sudo systemctl restart nginx

echo "All packages installed, MariaDB setup completed, ionCube loaders configured, PHP 7.2 installed with necessary extensions, and Nginx configured to serve ProxCP as the default site."
