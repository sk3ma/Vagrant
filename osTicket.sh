#!/usr/bin/env bash

#################################################################################
# The purpose of the script is to automate a LAMP installation on Ubuntu.       #      
# The script installs LAMP, osTicket, and creates a database and virtualhost.   #
# Issue 'mysql -u root -pivyLab > /var/www/osticket.sql | pv' to load database. #
#################################################################################

# Declaring variables.
DISTRO=$(lsb_release -ds)
USERID=$(id -u)
IPADDR=192.168.33.90

# Sanity checking.
if [[ "${USERID}" -ne "0" ]]; then
    echo -e "\e[31;1;3mYou must be root, exiting.\e[m"
    exit 1
fi

# Apache installation.
apache() {
    echo -e "\e[96;1;3mDistribution: ${DISTRO}\e[m"
    echo -e "\e[32;1;3mUpdating system\e[m"
    apt update
    echo -e "\e[32;1;3mInstalling Apache\e[m"
    apt install apache2 apache2-{doc,utils} openssl libssl-{dev,doc} vim -qy
    cd /var/www/html
    echo "<h1>Apache is operational</h1>" > index.html
    systemctl start apache2
    systemctl enable apache2
}

# PHP installation.
php() {
    echo -e "\e[32;1;3mInstalling PHP\e[m"
    apt install libapache2-mod-php7.4 php7.4 php7.4-{cli,dev,common,gd,mbstring,zip} -qy
    echo "<?php phpinfo(); ?>" > info.php
}

# MySQL installation.
mysql() {
    echo -e "\e[32;1;3mInstalling MySQL\e[m"
    debconf-set-selections <<< 'mysql-server mysql-server/root_password password ivyLab'
    debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password ivyLab'
    apt install mysql-server-8.0 mysql-client-8.0 php7.4-mysql -qy
    systemctl start mysql
    systemctl enable mysql
}

# Apache configuration.
config() {
    echo -e "\e[32;1;3mConfiguring Apache\e[m"
    tee /etc/apache2/sites-available/osticket.conf << STOP
<VirtualHost *:80>
     ServerAdmin levon@locstat.co.za
     DocumentRoot /var/www/osTicket/upload
     ServerName ticket.locstat.co.za
     ServerAlias www.locstat.co.za
     <Directory /var/www/osTicket/>
          Options FollowSymlinks
          AllowOverride All
          Require all granted
     </Directory>

     ErrorLog ${APACHE_LOG_DIR}/osticket_error.log
     CustomLog ${APACHE_LOG_DIR}/osticket_access.log combined
</VirtualHost>
STOP
}

# Database creation.
database() {
    echo -e "\e[32;1;3mConfiguring MySQL\e[m"
    tee /var/www/osticket.sql << STOP
UPDATE mysql.user SET plugin = 'mysql_native_password' WHERE User = 'root';
CREATE DATABASE osticket_db;
CREATE USER 'osadmin'@'localhost' IDENTIFIED BY 'P@ssword321';
GRANT ALL PRIVILEGES ON osticket_db.* TO 'osadmin'@'localhost';
FLUSH PRIVILEGES;
STOP
}

# osTicket installation.
osticket() {
    echo -e "\e[32;1;3mDownloading osTicket\e[m"
    apt install vim unzip pv -qy
    cd /opt
    wget --progress=bar:force https://github.com/osTicket/osTicket/releases/download/v1.15.2/osTicket-v1.15.2.zip
    echo -e "\e[32;1;3mUnpacking files\e[m"   
    unzip osTicket-v1.15.2.zip -d osTicket
    mv -v osTicket /var/www/
    cp -v /var/www/osTicket/upload/include/ost-sampleconfig.php /var/www/osTicket/upload/include/ost-config.php
    chown -vR www-data:www-data /var/www/
    chmod -vR 755 /var/www/osTicket
    rm -f rm osTicket-v1.15.2.zip
}

# Firewall exception.
firewall() {
    echo -e "\e[32;1;3mAdjusting firewall\e[m"
    ufw allow 80/tcp
    ufw allow 3306/tcp
    echo "y" | ufw enable
    ufw reload
}

# Enabling service.
service() {
    echo -e "\e[32;1;3mRestarting Apache\e[m"
    cd /etc/apache2/sites-available
    a2dissite 000-default.conf
    a2ensite osticket.conf
    systemctl restart apache2
    echo -e "\e[33;1;3;5mFinished, configure webUI - http://${IPADDR}/setup/install.php\e[m"
    exit
}

# Calling functions.
if [[ -f /etc/lsb-release ]]; then
    echo -e "\e[33;1;3;5mUbuntu detected, proceeding...\e[m"
    apache
    php
    mysql
    config
    database
    osticket
    firewall
    service
fi

# Post-installation step: 
# rm -rf /var/www/osTicket/upload/setup/
# Fasting:
# no food, only water.
# no smoking.
# no TV or internet for a period of time.
# when you fast, do so with God in mind for His pleasure (deny yourself physically to grow spiritually).
# God has asked us to fast as Christians (but it works in concert with prayer).
# when you fast you choose the soul over your body (asking God to nourish your soul).
# 0637164875 - Charlette
# spend time and effort on being the right person instead of finding the right person.
