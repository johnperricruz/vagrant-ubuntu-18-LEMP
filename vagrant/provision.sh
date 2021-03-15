#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

# Set start time
time_start="$(date +%s)"

# Get domain name passed from Vagrantfile
vagrant_domain=$1

# Add additional sources for packages
echo "Updating package sources..."
ln -sf /srv/config/apt-sources-extra.list /etc/apt/sources.list.d/apt-sources-extra.list

# Add nginx signing key
echo "Adding nginx signing key..."
wget --quiet http://nginx.org/keys/nginx_signing.key -O- | apt-key add -

# Add nodejs signing key
echo "Adding nodejs signing key..."
wget --quiet -O- https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add -

# Fix missing pub keys
echo "Adding missing public keys..."
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 4F4EA0AAE5267A6C #PHP
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 80E7349A06ED541C #phpMyAdmin

# Set MySQL default root password
echo "Setting up root MySQL password..."
echo mariadb-server mysql-server/root_password password password | debconf-set-selections
echo mariadb-server mysql-server/root_password_again password password | debconf-set-selections

# phpMyAdmin unattended installation
# See: http://gercogandia.blogspot.my/2012/11/automatic-unattended-install-of.html
echo "Setting up default phpMyAdmin configuration..."
echo phpmyadmin phpmyadmin/dbconfig-install boolean true | debconf-set-selections
echo phpmyadmin phpmyadmin/app-password-confirm password password | debconf-set-selections
echo phpmyadmin phpmyadmin/mysql/admin-pass password password | debconf-set-selections
echo phpmyadmin phpmyadmin/mysql/app-pass password password | debconf-set-selections
echo phpmyadmin phpmyadmin/reconfigure-webserver multiselect none | debconf-set-selections

echo "Updating packages list..."
apt-get update


echo "Installing php 7.2..."
add-apt-repository ppa:ondrej/php
apt-get update
apt-get install php7.2 -y

a2dismod php7.1
a2enmod php7.2

echo "Installing required packages..."
apt-get install -y \
    build-essential \
    curl \
    dos2unix \
    gettext \
    git \
    imagemagick \
    mariadb-server \
    nginx \
    nodejs \
    ntp \
    php7.2-bcmath \
    php7.2-cli \
    php7.2-common \
    php7.2-curl \
    php7.2-fpm \
    php7.2-dev \
    php7.2-gd \
    php7.2-imap \
    php7.2-intl \
    php7.2-mbstring \
    php7.2-mcrypt \
    php7.2-mysql \
    php7.2-soap \
    php7.2-xml \
    php7.2-xmlrpc \
    php7.2-zip \
    php-gettext \
    php-imagick \
    php-pear \
    subversion \
    unzip \
    zip

# Install phpmyadmin separately
apt-get install -y phpmyadmin

# Install Composer
if [ ! -f /usr/local/bin/composer ]; then
    echo "Installing Composer..."
    curl -sS https://getcomposer.org/installer | php
    chmod +x composer.phar
    mv composer.phar /usr/local/bin/composer
    #FOR MAGENTO 2
    sudo composer self-update --1
    sudo mkdir ~/.composer
    sudo chown vagrant.vagrant ~/.composer
fi

# # Install WP-CLI
# if [ ! -f /usr/local/bin/wp ]; then
#     echo "Installing wp-cli..."
#     curl -sS -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
#     chmod +x wp-cli.phar
#     mv wp-cli.phar /usr/local/bin/wp
# fi

# Install mailhog
if [ ! -f /usr/local/bin/mailhog ]; then
    echo "Installing mailhog..."
    wget --quiet -O ~/mailhog https://github.com/mailhog/MailHog/releases/download/v0.2.1/MailHog_linux_amd64
    chmod +x ~/mailhog
    mv ~/mailhog /usr/local/bin/mailhog
fi

# Install mhsendmail
if [ ! -f /usr/local/bin/mhsendmail ]; then
    echo "Installing mhsendmail..."
    wget --quiet -O ~/mhsendmail https://github.com/mailhog/mhsendmail/releases/download/v0.2.0/mhsendmail_linux_amd64
    chmod +x ~/mhsendmail
    mv ~/mhsendmail /usr/local/bin/mhsendmail
fi


# Post installation cleanup
echo "Cleaning up..."
apt-get -y autoremove

# nginx initial setup
echo "Configuring nginx..."
cp /srv/config/nginx/nginx.conf /etc/nginx/nginx.conf
cp /srv/config/nginx/default.conf /etc/nginx/conf.d/default.conf
cp /srv/config/nginx/mail.conf /etc/nginx/conf.d/mail.conf
cp /srv/config/nginx/db.conf /etc/nginx/conf.d/db.conf
sed -i "s/VAGRANT_DOMAIN/$vagrant_domain/g" /etc/nginx/conf.d/default.conf
sed -i "s/VAGRANT_DOMAIN/$vagrant_domain/g" /etc/nginx/conf.d/mail.conf
sed -i "s/VAGRANT_DOMAIN/$vagrant_domain/g" /etc/nginx/conf.d/db.conf

# PHP initial setup
echo "Configuring PHP..."
phpenmod mcrypt
phpenmod mbstring
cp /srv/config/php/php-custom.ini /etc/php/7.1/fpm/conf.d/php-custom.ini
sed -i "s/VAGRANT_DOMAIN/$vagrant_domain/g" /etc/php/7.1/fpm/conf.d/php-custom.ini

# Redis Setup
echo "Configuring Redis..."
sudo apt update
sudo apt install redis-server -y

# MySQL initial setup
echo "Configuring MySQL..."
mysql_secure_installation<<EOF
password
n
Y
Y
Y
Y
EOF

mysql -u root -ppassword << EOF
CREATE DATABASE IF NOT EXISTS vagrant;
GRANT ALL PRIVILEGES ON vagrant.* TO 'vagrant'@'localhost' IDENTIFIED BY 'password';
EOF

# phpMyAdmin initial setup
if [ ! -f /etc/phpmyadmin/config.inc.php ]; then
    echo "Configuring phpMyAdmin..."
    cp /srv/config/phpmyadmin/config.inc.php /etc/phpmyadmin/config.inc.php
fi

# Mailhog initial setup
if [ ! -f /etc/systemd/system/mailhog.service ]; then
    echo "Configuring Mailhog..."
    cp /srv/config/mailhog/mailhog.service  /etc/systemd/system/mailhog.service
    systemctl enable mailhog
fi

# Swap
echo "Setting up swap..."
fallocate -l 4G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
sh -c 'echo "/swapfile none swap sw 0 0" >> /etc/fstab'
sysctl vm.swappiness=10
sysctl vm.vfs_cache_pressure=50
sh -c "printf 'vm.swappiness=10\n' >> /etc/sysctl.conf"
sh -c "printf 'vm.vfs_cache_pressure=50\n' >> /etc/sysctl.conf"

# Restart all the services
echo "Restarting services..."
service mysql restart
service php7.2-fpm restart
service nginx restart
service mailhog start

# Add ubuntu user to the www-data group with correct owner
echo "Adding user to the correct group..."
usermod -a -G www-data ubuntu
sudo chown -R www-data:www-data /srv/www/

# Calculate time taken and inform the user
time_end="$(date +%s)"
echo "Provisioning completed in "$(expr $time_end - $time_start)" seconds"
