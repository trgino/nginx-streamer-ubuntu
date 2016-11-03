#!/bin/bash

# Author: Olaf Reitmaier <olafrv@gmail.com>
# Tested on: Ubuntu 16.04.1 LTS 
# Test date: 02-Nov-2016
#
# Fresh download, build and install:
# ./nginx.sh reinstall download 
#
# Only fresh install, reuse builded and downloaded:
# ./nginx.sh reinstall          

NGINX_VERSION="1.10.2"
NGINX_SOURCE="nginx-${NGINX_VERSION}.tar.gz"
NGINX_DIR=$(basename ${NGINX_SOURCE} .tar.gz)
NGINX_URL="http://nginx.org/download/${NGINX_SOURCE}"
NGINX_INSTALL_DIR="/usr/local/nginx"
NGINX_ROOT="/hls"
NGINX_WORKING_DIR="/tmp/working"

NGINX_RTMP_VERSION="1.1.10"
NGINX_RTMP_SOURCE="v${NGINX_RTMP_VERSION}.tar.gz"
NGINX_RTMP_URL="https://github.com/arut/nginx-rtmp-module/archive/${NGINX_RTMP_SOURCE}"
NGINX_RTMP_DIR="nginx-rtmp-module-${NGINX_RTMP_VERSION}"

WORDPRESS_VERSION=4.6.1
WORDPRESS_SOURCE="wordpress-${WORDPRESS_VERSION}.tar.gz"
WORDPRESS_DIR=$(basename ${WORDPRESS_SOURCE} .tar.gz)
WORDPRESS_URL=https://wordpress.org/wordpress-${WORDPRESS_VERSION}.tar.gz
WORDPRESS_INSTALL_DIR="$NGINX_INSTALL_DIR/html/wordpress"

if [ "$1" == "reinstall" ]
then
	if [ "$2" == "download" ]
	then 
		rm -rf $NGINX_WORKING_DIR
	fi
	sudo rm -rf $NGINX_INSTALL_DIR
fi

[ $(id -u) -eq 0 ] && echo "Can't run as root" && exit 1; 

# Needed for NGINX compile & installation
sudo apt-get --yes install build-essential libpcre3 libpcre3-dev  libaio1 libaio-dev libssl1.0.0 libssl-dev libxslt1.1 libxslt1-dev

# Needed for live video resolution conversion 
sudo apt-get --yes install ffmpeg
sudo apt-get --yes install libavcodec-extra

# Needed for frontend
sudo apt-get install php7.0-fpm php7.0-mysql php7.0-gd mysql-server unrar

[ ! -d "$NGINX_WORKING_DIR" ] && mkdir "$NGINX_WORKING_DIR" 

if [ ! -d "$NGINX_INSTALL_DIR" ]
then

	BEFORE=$(pwd)

	cd "$NGINX_WORKING_DIR"
	
	[ ! -f "$NGINX_SOURCE" ] && wget $NGINX_URL
	[ ! -f "$NGINX_RTMP_SOURCE" ] && wget $NGINX_RTMP_URL
	[ ! -d "$NGINX_DIR" ] && tar xvfz $NGINX_SOURCE
	[ ! -d "$NGINX_RTMP_DIR" ] && tar xvfz $NGINX_RTMP_SOURCE

	cd "$NGINX_DIR"
	./configure --with-http_ssl_module --with-http_xslt_module --with-file-aio \
		--with-http_mp4_module --with-http_flv_module --add-module="../$NGINX_RTMP_DIR"
	make
	sudo make install

	cd $BEFORE

	sudo cp nginx.init -O /etc/init.d/nginx
	sudo chmod +x /etc/init.d/nginx
	sudo update-rc.d nginx defaults

	mkdir -p ~/.vim/syntax
	cp nginx.vim -O ~/.vim/syntax/nginx.vim
	if [ $(grep nginx ~/.vimrc) -eq 0 ]
	then 
		echo "
au BufRead,BufNewFile *.nginx set ft=nginx
au BufRead,BufNewFile */etc/nginx/* set ft=nginx
au BufRead,BufNewFile */usr/local/nginx/conf/* set ft=nginx
au BufRead,BufNewFile nginx.conf set ft=nginx
" | tee -a ~/.vimrc
	fi

	# Generate Config Files
	sudo service nginx restart
fi

# Nginx configuration
cat nginx.conf | sudo tee ${NGINX_INSTALL_DIR}/conf/nginx.conf

# Crossdomain Policy for Video Linking (CORS)
echo "
<?xml version="1.0"?>
<!DOCTYPE cross-domain-policy SYSTEM "http://www.adobe.com/xml/dtds/cross-domain-policy.dtd">
<cross-domain-policy>
<allow-access-from domain="*"/>
</cross-domain-policy>
" | sudo tee ${NGINX_INSTALL_DIR}/html/crossdomain.xml


# https://www.nginx.com/blog/scalable-live-video-streaming-nginx-plus-bitmovin/
echo '
<?xml version="1.0"?>
<cross-domain-policy>
<allow-access-from domain="*" to-ports="80,443" secure="false"/>
<site-control permitted-cross-domain-policies="master-only" />
</cross-domain-policy>
'

echo '
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:output method="html"/>

<xsl:param name="app"/>
<xsl:param name="name"/>

<xsl:template match="/">
    <xsl:value-of select="count(//application[name=$app]/live/stream[name=$name]/client[not(publishing) and flashver])"/>
</xsl:template>

</xsl:stylesheet>
' | sudo tee ${NGINX_INSTALL_DIR}/html/nclients.xsl

# MP4 HLS demostration
sudo cp index.html ${NGINX_ROOT}
sudo cp small.png ${NGINX_ROOT}
sudo cp small.mp4 ${NGINX_ROOT}/vod/

sudo service nginx restart
sudo systemctl status nginx.service

mkdir -p /hls/{live,mobile,vod,show}
sudo chown -R root:www-data /hls
sudo chmod -R 775 /hls


# MSE-based HLS client
# https://github.com/dailymotion/hls.js

# NGINX-based Media Streaming Server
# https://github.com/arut/nginx-rtmp-module

# Setup Nginx-RTMP on Ubuntu 14.04
# https://www.vultr.com/docs/setup-nginx-rtmp-on-ubuntu-14-04

# Setup Nginx on Ubuntu to Stream Live HLS Video
# https://www.vultr.com/docs/setup-nginx-on-ubuntu-to-stream-live-hls-video

# Setting Up Adaptive Streaming with Nginx
# https://licson.net/post/setting-up-adaptive-streaming-with-nginx/

# Optimizing Nginx for (large) file delivery
# https://licson.net/post/optimizing-nginx-for-large-file-delivery/

# Setup Nginx-RTMP on Ubuntu 14.04
# https://www.vultr.com/docs/setup-nginx-rtmp-on-ubuntu-14-04

# NGINX Module ngx_http_mp4_module
# http://nginx.org/en/docs/http/ngx_http_mp4_module.html

# NGINX Pitfalls and Common Mistakes
# https://www.nginx.com/resources/wiki/start/topics/tutorials/config_pitfalls/

# Restreamer - Live video streaming on your website without streaming providers
# https://datarhei.github.io/restreamer/

# Youtube RTMP Live Streams
# https://www.youtube.com/live_dashboard_splash
# ThemeForest and CodeCanyon (VideoPro)
# http://videopro.cactusthemes.com/v1/top-10-tank-champions-league-of-legends/
# http://preview.themeforest.net/item/videopro-video-wordpress-theme/full_screen_preview/16677956
# WOW -> http://videopro.cactusthemes.com/v1/home-page-v2/

# Open Brocaster Studio
# https://obsproject.com
# https://github.com/jp9000/obs-studio/wiki/Install-Instructions#linux

# Open Source Video Conferencing and Streaming Server
# http://openvcx.com/download.php
