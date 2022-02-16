# Get domain name passed from Vagrantfile
vagrant_domain=$1

sudo cp /srv/config/nginx/default.conf /etc/nginx/conf.d/default.conf
sudo sed -i "s/VAGRANT_DOMAIN/$vagrant_domain/g" /etc/nginx/conf.d/default.conf
sudo fuser -k 80/tcp
sudo fuser -k 443/tcp
sudo service nginx restart
echo 'LOADED...'