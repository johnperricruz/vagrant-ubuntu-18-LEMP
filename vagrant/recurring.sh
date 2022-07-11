#!/bin/bash


# Get domain name passed from Vagrantfile
vagrant_domain=$1

# nginx initial setup
echo "Configuring nginx..."
sudo cp /srv/config/nginx/nginx.conf /etc/nginx/nginx.conf
sudo cp /srv/config/nginx/default.conf /etc/nginx/conf.d/default.conf
sudo cp /srv/config/nginx/mail.conf /etc/nginx/conf.d/mail.conf
sudo cp /srv/config/nginx/db.conf /etc/nginx/conf.d/db.conf
sudo sed -i "s/VAGRANT_DOMAIN/$vagrant_domain/g" /etc/nginx/conf.d/default.conf
sudo sed -i "s/VAGRANT_DOMAIN/$vagrant_domain/g" /etc/nginx/conf.d/mail.conf
sudo sed -i "s/VAGRANT_DOMAIN/$vagrant_domain/g" /etc/nginx/conf.d/db.conf

# Restart all the services
echo "Restarting services..."
sudo fuser -k 80/tcp
sudo fuser -k 443/tcp
sudo service mysql restart
sudo service php8.1-fpm restart
#sudo systemctl unmask nginx.service
sudo service nginx restart
sudo service mailhog start


# Finished..................100%