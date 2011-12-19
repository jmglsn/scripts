#!/bin/bash

# Error handling
set -x
set -o nounset
set -o errexit

# TODO:
#
# - add targets (update, delete)
# - check if packages are already installed
# - save username in variable and replace $USER


# To delete the complete macports installation, including macports itself

# %% sudo port -f uninstall installed

# %% sudo rm -rf \
#    /opt/local \
#    /Applications/DarwinPorts \
#    /Applications/MacPorts \
#    /Library/LaunchDaemons/org.macports.* \
#    /Library/Receipts/DarwinPorts*.pkg \
#    /Library/Receipts/MacPorts*.pkg \
#    /Library/StartupItems/DarwinPortsStartup \
#    /Library/Tcl/darwinports1.0 \
#    /Library/Tcl/macports1.0 \
#    ~/.macports

[ $1 ] && USERNAME=$1 || read -p "Enter USERNAME: " USERNAME

svn co http://svn.macports.org/repository/macports/trunk/base/ macports_source
cd macports_source
./configure
make
sudo make install
sudo /opt/local/bin/port selfupdate

sudo port install curl +ssl

sudo port install mysql5-server

sudo launchctl load -w /Library/LaunchDaemons/org.macports.mysql5.plist

sudo -u mysql mysql_install_db5

echo 'export PATH=/opt/local/bin:/opt/local/lib/mysql5/bin:$PATH' >> ~/.profile
#echo "alias apache2ctl='sudo /opt/local/apache2/bin/apachectl'" >> ~/.profile

#decide how to do it.
#echo "
#alias apachectl='sudo /opt/local/apache2/bin/apachectl'
#alias mysqlstart='sudo /opt/local/bin/mysqld_safe5 &' 
#alias mysqlstop='/opt/local/bin/mysqladmin5 -u root -p shutdown'
#" >> .profile

sudo touch /opt/local/etc/mysql5/my.cnf
sudo chmod 664 /opt/local/etc/mysql5/my.cnf
sudo echo '[mysqld_safe] socket = /tmp/mysql.sock' >> /opt/local/etc/mysql5/my.cnf
sudo chmod 644 /opt/local/etc/mysql5/my.cnf

sudo ln -s /opt/local/var/run/mysql5/mysqld.sock /tmp/mysql.sock

sudo port install php5 +apache2 +pear php5-mysql +mysqlnd

sudo launchctl load -w /Library/LaunchDaemons/org.macports.apache2.plist

cd /opt/local/etc/php5/
sudo cp php.ini-development php.ini
sudo chmod 664 php.ini
sudo echo 'date.timezone = Europe/Berlin' >> php.ini
sudo chmod 644 php.ini

cd /opt/local/apache2/modules
sudo /opt/local/apache2/bin/apxs -a -e -n "php5" libphp5.so

sudo chmod 664 /opt/local/apache2/conf/httpd.conf
echo '
DocumentRoot "/Users/'${USERNAME}'/workspace"

<Directory "/Users/'${USERNAME}'/workspace">
	Options Indexes FollowSymLinks
	AllowOverride All
	<IfModule dir_module>
	  DirectoryIndex index.html index.php
	</IfModule>
	Order allow,deny
	Allow from all
</Directory>

AddType application/x-httpd-php .php
AddType application/x-httpd-php-source .phps
' >> /opt/local/apache2/conf/httpd.conf

sudo chmod 644 /opt/local/apache2/conf/httpd.conf

sudo port install php5-openssl php5-curl php5-gd php5-iconv php5-http php5-mcrypt php5-xdebug

ln -s /opt/local/apache2/htdocs/ /Users/${USERNAME}/workspace

sudo chown -R ${USERNAME} /opt/local/apache2/htdocs/

sudo pear install mdb2#mysql

sudo port install git-core