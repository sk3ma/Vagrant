#!/usr/bin/env bash

######################################################################
# This script will automate a Dokuwiki installation on Ubuntu 20.04. #
# It will install Apache, PHP, Dokuwiki and creates a virtualhost.   #
######################################################################

# Declaring variables.
USERID=$(id -u)
DISTRO=$(lsb_release -ds)

# Sanity checking.
if [[ ${USERID} -ne "0" ]]; then
    echo -e "\e[31;1;3mYou must be root, exiting.\e[m"
    exit 1
fi

# Apache installation.
apache() {
    echo -e "\e[96;1;3mDistribution: ${DISTRO}\e[m"
    echo -e "\e[32;1;3mInstalling Apache\e[m"
    apt update && apt install apache2 apache2-{doc,utils} openssl libssl-{dev,doc} software-properties-common vim -qy
    echo "<h1>Apache is operational</h1>" > /var/www/html/index.html
    systemctl start apache2
    systemctl enable --now apache2
    sed -ie 's/80/8082/g' /etc/apache2/ports.conf
}

# PHP installation.
php() {
    echo -e "\e[32;1;3mInstalling PHP\e[m"
    apt install libapache2-mod-php7.4 php7.4 php7.4-{cli,curl,common,dev,fpm,gd,mbstring,xml} -qy
    echo "<?php phpinfo(); ?>" > /var/www/html/info.php
}

# Creating exception.
firewall() {
    echo -e "\e[32;1;3mAdjusting firewall\e[m"
    ufw allow ssh
    ufw allow http
    ufw allow https
    ufw allow 8082/tcp
    echo "y" | ufw enable
    ufw reload
}

# Downloading Dokuwiki.
wiki() {
    echo -e "\e[32;1;3mDownloading Dokuwiki\e[m"
    cd /opt
    mkdir -p /var/www/html/dokuwiki
    wget --progress=bar:force https://download.dokuwiki.org/src/dokuwiki/dokuwiki-stable.tgz
    tar -xzf dokuwiki-stable.tgz -C /var/www/html/dokuwiki/ --strip-components=1
    cp /var/www/html/dokuwiki/.htaccess{.dist,}
    chown -R www-data:www-data /var/www/html/dokuwiki
    rm -f dokuwiki-stable.tgz
}

# Dokuwiki configuration.
website() {
    echo -e "\e[32;1;3mCreating virtualhost\e[m"
    local vhost=$(cat << STOP
<VirtualHost *:80>
        ServerName wiki.mycompany.com
        DocumentRoot /var/www/html/dokuwiki

        <Directory ~ "/var/www/html/dokuwiki/(bin/|conf/|data/|inc/)">
            <IfModule mod_authz_core.c>
                AllowOverride All
                Require all denied
            </IfModule>
            <IfModule !mod_authz_core.c>
                Order allow,deny
                Deny from all
            </IfModule>
        </Directory>

        ErrorLog /var/log/apache2/dokuwiki_error.log
        CustomLog /var/log/apache2/dokuwiki_access.log combined
</VirtualHost>
STOP
)
    echo "${vhost}" > /etc/apache2/sites-available/dokuwiki.conf
    a2dissite 000-default.conf
    a2ensite dokuwiki.conf
    sed -ie 's/80/8082/g' /etc/apache2/sites-enabled/dokuwiki.conf
    systemctl reload apache2
}

# Sample page.
page() {
    echo -e "\e[32;1;3mCreating page\e[m"
    tee /var/www/html/dokuwiki/data/pages/start.txt << STOP > /dev/null
----
[[http://www.mycompany.com|{{ ::mycompany-1.png?400 |My Company}}]]

====== Greetings citizen ======
>> **''Welcome'' to the ''My Company'' wiki ''landing page''.**

  * **This is a ''private place'' where you can ''store code'' and ''technical documentation'' that is Git ''version controlled''.**
    * **All ''wiki pages'' are ''stored'' in ''plain text'' files, so there is ''no need'' for a ''database''.**
    * **''Pages'' are created by ''editing non-existing'' pages, so after the ''id='' portion in the ''web browser'' you would provide a wiki ''page name''.**
    * **For ''security concerns'' Dokuwiki uses ''access control lists'' for ''authentication'' and only ''registered users'' are allowed ''access''.**
    * **''Dokuwiki'' also makes use of email ''two-factor authentication'' for ''additional security''.**
    * **To ''search'' wiki pages click on ''Search'' and ''type something'', such as ''prometheus'' for instance.**
    * **To ''find'' a ''list'' of existing ''wiki pages'' click on ''Sitemap'', and for ''images'' click on ''Media Manager''.**
    * **To ''remove'' wiki pages simply ''delete'' the ''content'' from the ''wiki page''.**
    * :!: **ADMIN:** For ''backup purposes'' the Dokuwiki ''working directory'' resides in the ''/var/www/html/dokuwiki/data'' path.

----
STOP
}

# Certbot installation.
cert() {
    echo -e "\e[32;1;3mInstalling Certbot\e[m"
    apt install certbot python3-certbot-apache -qy
    echo -e "\e[33;1;3;5mFinished, configure webUI.\e[m"
    exit
}

# Calling functions.
if [[ -f /etc/lsb-release ]]; then
    echo -e "\e[35;1;3;5mUbuntu detected, proceeding...\e[m"
    apache
    php
    firewall
    wiki
    website
    page
    cert
fi
