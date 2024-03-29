#!/usr/bin/env bash

#################################################################################
# The purpose of the script is to automate a LAMP installation on Ubuntu 20.04. #
# The script installs LAMP, osTicket, and creates a database and virtualhost.   #
#################################################################################

# Declaring variables.
DISTRO=$(lsb_release -ds)
USERID=$(id -u)
DIRE='/var/www/osTicket/upload/setup/'

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
    systemctl start apache2 && systemctl enable apache2
    sed -ie 's|80|8080|g' /etc/apache2/ports.conf
}

# PHP installation.
php() {
    echo -e "\e[32;1;3mAdding repository\e[m"
    add-apt-repository ppa:ondrej/php -y
    echo -e "\e[32;1;3mInstalling PHP\e[m"
    apt install php8.0 -qy
    apt install php8.0-{common,imap,apcu,intl,cgi,mbstring,mysql,gd,bcmath,xml,zip} -qy
    echo "<?php phpinfo(); ?>" > /var/www/html/info.php
}

# MariaDB installation.
mariadb() {
    echo -e "\e[32;1;3mInstalling MariaDB\e[m"
    apt install software-properties-common curl -qy
    cd /opt
    curl -LsS -O https://downloads.mariadb.com/MariaDB/mariadb_repo_setup
    bash mariadb_repo_setup --mariadb-server-version=10.6
    apt update && apt install mariadb-server-10.6 mariadb-client-10.6 mariadb-common -qy
    systemctl start mariadb
    systemctl enable mariadb
    rm -f mariadb_repo_setup
}

# Apache configuration.
config() {
    echo -e "\e[32;1;3mConfiguring Apache\e[m"
    local vhost=$(cat << STOP
<VirtualHost *:80>
     ServerAdmin sk3ma87@gmail.com
     DocumentRoot /var/www/osTicket/upload
     ServerName ticket.mycompany.com
     ServerAlias www.ticket.mycompany.com
     <Directory /var/www/osTicket/>
          Options FollowSymlinks
          AllowOverride All
          Require all granted
     </Directory>
     ErrorLog ${APACHE_LOG_DIR}/osticket_error.log
     CustomLog ${APACHE_LOG_DIR}/osticket_access.log combined
</VirtualHost>
STOP
)
    echo "${vhost}" > /etc/apache2/sites-available/osticket.conf
}

# Database creation.
database() {
    echo -e "\e[32;1;3mCreating database\e[m"
    local dbase=$(cat << STOP
CREATE DATABASE osticket_db character set utf8 collate utf8_bin;
CREATE USER 'osadmin'@'%' IDENTIFIED BY 'uECcq2sq';
GRANT ALL PRIVILEGES ON osticket_db.* TO 'osadmin'@'%';
STOP
)
    echo "${dbase}" > /var/www/osticket.sql
    echo -e "\e[32;1;3mConfiguring MariaDB\e[m"
    cat << STOP > /tmp/keystroke.txt
echo | "enter"
y
y
35mCb3dh
35mCb3dh
y
y
y
y
STOP
   mysql_secure_installation < /tmp/keystroke.txt
   echo -e "\e[32;1;3mImporting database\e[m"
   mysql -u root -p35mCb3dh < /var/www/osticket.sql
}

# osTicket installation.
osticket() {
    echo -e "\e[32;1;3mDownloading osTicket\e[m"
    apt install pv vim unzip -qy
    cd /opt
    wget --progress=bar:force https://github.com/osTicket/osTicket/releases/download/v1.17/osTicket-v1.17.zip
    echo -e "\e[32;1;3mDownloading plugin\e[m"
    wget --progress=bar:force https://github.com/sk3ma/Vagrant/blob/main/auth-oauth2.phar
    echo -e "\e[32;1;3mUnpacking files\e[m"
    unzip osTicket-v1.17.zip -d osTicket
    mv -v osTicket /var/www/
    echo -e "\e[32;1;3mConfiguring osTicket\e[m"
    cp -v /var/www/osTicket/upload/include/ost-sampleconfig.php /var/www/osTicket/upload/include/ost-config.php
    chown -vR www-data:www-data /var/www/
    chown -vR www-data:www-data auth-oauth2.phar
    chmod -vR 755 /var/www/osTicket
    mv -v auth-oauth2.phar /var/www/osTicket/upload/include/plugins/
    rm -f osTicket-v1.17.zip
}

# Firewall exception.
firewall() {
    echo -e "\e[32;1;3mAdjusting firewall\e[m"
    ufw allow 80,443,8080/tcp
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
    sed -ie 's|80|8080|g' /etc/apache2/sites-enabled/osticket.conf
    systemctl restart apache2
}
    
# Certbot installation.
cert() {
    echo -e "\e[32;1;3mInstalling Certbot\e[m"
    apt install certbot python3-certbot-apache -qy
    echo -e "\e[33;1;3;5mFinished, configure webUI.\e[m"
    echo -e "\e[33;1;3;5mPost configuration: remove ${DIRE} directory.\e[m"
    exit
}

# Calling functions.
if [[ -f /etc/lsb-release ]]; then
    echo -e "\e[33;1;3;5mUbuntu detected, proceeding...\e[m"
    apache
    php
    mariadb
    config
    database
    osticket
    firewall
    service
    cert
fi
