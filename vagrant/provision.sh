#VARS
ENV_NAME = $1


#------------------------------------------------------------------------------------------------------------------#


#REMOVE APACHE
echo "Removing Default Apache..."
sudo systemctl stop apache2
sudo systemctl disable apache2
sudo apt remove apache2 -y
sudo apt autoremove


#------------------------------------------------------------------------------------------------------------------#


#NGINX
echo "Installing NGINX..."
sudo apt clean all && sudo apt update && sudo apt dist-upgrade
sudo apt update
sudo apt install nginx -y
sudo ufw app list
sudo ufw allow "Nginx Full"
sudo ufw status
sudo ufw enable

# NGINX INITIAL SETUP
echo "Configuring NGINX..."
sudo cp /srv/config/nginx/nginx.conf /etc/nginx/nginx.conf
sudo cp /srv/config/nginx/default.conf /etc/nginx/conf.d/default.conf
sudo cp /srv/config/nginx/mail.conf /etc/nginx/conf.d/mail.conf
sudo cp /srv/config/nginx/db.conf /etc/nginx/conf.d/db.conf
sudo sed -i "s/VAGRANT_DOMAIN/$ENV_NAME/g" /etc/nginx/conf.d/default.conf
sudo sed -i "s/VAGRANT_DOMAIN/$ENV_NAME/g" /etc/nginx/conf.d/mail.conf
sudo sed -i "s/VAGRANT_DOMAIN/$ENV_NAME/g" /etc/nginx/conf.d/db.conf


#------------------------------------------------------------------------------------------------------------------#


#MYSQL
echo "Installing MYSQL..."
sudo apt update
sudo apt install mysql-server -y

#INSTALL DATABASE
echo "Creating Database..."
mysql -u root -ppassword << EOF
CREATE DATABASE IF NOT EXISTS vagrant;
GRANT ALL PRIVILEGES ON vagrant.* TO 'vagrant'@'localhost' IDENTIFIED BY 'password';
EOF


#------------------------------------------------------------------------------------------------------------------#


#PHP v8.1
echo "Installing PHP8.1"
sudo apt update && sudo apt -y upgrade
sudo apt update
sudo apt install lsb-release ca-certificates apt-transport-https software-properties-common -y
sudo add-apt-repository ppa:ondrej/php
sudo apt install php8.1 -y

echo "Installing PHP8.1 modules"
sudo apt install php8.1-{bcmath,ctype,dom,gd,zip,iconv,intl,mbstring,pdo-mysql,simplexml,soap,xsl,zip,fpm} -y


#------------------------------------------------------------------------------------------------------------------#


#ELASTIC SEARCH
echo "Installing ElasticSuite..."
sudo apt update
sudo apt -y upgrade
sudo apt -y install gnupg
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
sudo apt -y install apt-transport-https
echo "deb https://artifacts.elastic.co/packages/oss-7.x/apt stable main" | sudo tee  /etc/apt/sources.list.d/elastic-7.x.list
sudo apt update
sudo apt -y install elasticsearch-oss

#ELASTIC CONFIG
echo "Configuring ElasticSuite..."
sudo cp /srv/config/elasticsearch/elasticsearch.yml /etc/elasticsearch/elasticsearch.yml

sudo -i service elasticsearch stop
sudo -i service elasticsearch start

sudo /bin/systemctl daemon-reload
sudo /bin/systemctl enable elasticsearch.service


#------------------------------------------------------------------------------------------------------------------#


#COMPOSER INSTALL
echo "Installing Composer..."
curl -sS https://getcomposer.org/installer | php
chmod +x composer.phar
mv composer.phar /usr/local/bin/composer

#COMPOSER FOR MAGENTO 2
sudo composer self-update --1
sudo mkdir ~/.composer
sudo chown vagrant.vagrant ~/.composer


#------------------------------------------------------------------------------------------------------------------#


# Install mailhog
if [ ! -f /usr/local/bin/mailhog ]; then
    echo "Installing mailhog..."
    wget --quiet -O ~/mailhog https://github.com/mailhog/MailHog/releases/download/v0.2.1/MailHog_linux_amd64
    chmod +x ~/mailhog
    mv ~/mailhog /usr/local/bin/mailhog
    sudo service mailhog start
fi


#------------------------------------------------------------------------------------------------------------------#


# Install mhsendmail
if [ ! -f /usr/local/bin/mhsendmail ]; then
    echo "Installing mhsendmail..."
    wget --quiet -O ~/mhsendmail https://github.com/mailhog/mhsendmail/releases/download/v0.2.0/mhsendmail_linux_amd64
    chmod +x ~/mhsendmail
    mv ~/mhsendmail /usr/local/bin/mhsendmail
fi