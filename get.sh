#!/bin/bash

# List of packages to install
packages=(
    nginx
    software-properties-common
)

echo "Updating package lists..."
sudo apt update

echo "Installing packages..."
for package in "${packages[@]}"
do
    sudo apt install -y "$package"
done

echo "Adding PHP repository..."
sudo add-apt-repository -y ppa:ondrej/php

echo "Updating package lists after adding repository..."
sudo apt update

echo "Installing PHP 7.2 and related packages..."
sudo apt install -y php7.2 php7.2-common php7.2-cli php7.2-fpm

echo "All packages installed."
