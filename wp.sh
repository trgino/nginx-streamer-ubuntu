#!/bin/bash

# Author: Olaf Reitmaier <olafrv@gmail.com>
# Tested on: Ubuntu 16.04.1 LTS 
# Test date: 02-Nov-2016

WORDPRESS_VERSION=4.6.1
WORDPRESS_SOURCE="wordpress-${WORDPRESS_VERSION}.tar.gz"
WORDPRESS_DIR=$(basename ${WORDPRESS_SOURCE} .tar.gz)
WORDPRESS_URL=https://wordpress.org/wordpress-${WORDPRESS_VERSION}.tar.gz
WORDPRESS_INSTALL_DIR="/usr/local/nginx/html/wordpress"

if [ ! -d "$WORDPRESS_INSTALL_DIR" ]
then
	cd /tmp
	pwd
	
	[ ! -f "$WORDPRESS_SOURCE" ] && wget $WORDPRESS_URL
	[ ! -d "$WORDPRESS_DIR" ] && tar xvfz $WORDPRESS_SOURCE && sudo mv wordpress $WORDPRESS_INSTALL_DIR

	# curl -s https://api.wordpress.org/secret-key/1.1/salt/
	# cp ~/wp-config.php $WORDPRESS_INSTALL_DIR

	mkdir $WORDPRESS_INSTALL_DIR/wp-content/upgrade

	# Video Pro Theme
	# unrar x -o+ ~/videopro122_jojotheme.rar
	# mv "videopro122/Installation Files/themes/videopro" $WORDPRESS_INSTALL_DIR/wp-content/themes/

	sudo chown -R root:www-data $WORDPRESS_INSTALL_DIR
	sudo find $WORDPRESS_INSTALL_DIR -type d -exec chmod g+s {} \;
	sudo chmod g+w $WORDPRESS_INSTALL_DIR/wp-content
   sudo chmod -R g+w $WORDPRESS_INSTALL_DIR/wp-content/{themes,plugins}

	echo "Creating MySQL Wordpress database as root..."
mysql -u root -p <<END
CREATE DATABASE IF NOT EXISTS wordpress DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;
GRANT ALL ON wordpress.* TO 'wordpress'@'localhost' IDENTIFIED BY 'password';
FLUSH PRIVILEGES;
END
		
fi

