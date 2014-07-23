#!/bin/bash

######  INFO 
## Man I love the idea of scripts that work well, and allow me to be lazy. This script will
## probably not be one of those. Seriously I really suck at writing these things. So please
## review it or find someone that will for you before you run it. Chances are I will be like
## Mr Bolton, put some character in the wrong place, and end up wiping your hard drive. 
##
##
## Not even going to pretend I am some amazing script writer, so on that note please
## send me or post any corrections. You can email at zac at phenotyne.com or on github
## at github.com/ph3n0 
######

NEEDED_PKGS="git gawk libgeoip-dev sendmail ruby cmake make gcc g++ flex bison libpcap-dev libssl-dev python-dev swig zlib1g-dev libcurl4-openssl-dev python-software-properties"

## Sorry we need to be root, prey I don't mistype something!

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

echo " "
echo "This is going to install all the packages required to take a Ubuntu 12.04 LTS server x64"
echo "fresh install and setup Bro + Elasticsearch + Logstash + Kibana. The system will be updated"
echo "and the required packages will installed. Then the binary Bro distribution will be downloaded"
echo "and installed, followed by Java, Elasticsearch, logstash, and Kibana. All externally used"
echo "will be deleted at the end. Please execute this script in a safe directory for clean up."
echo "I will do my best not to delete too many files. . . but you know. . . "
echo " "

while true; do
    read -p "Are you ready to get started?" yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

DIR="$( cd "$( dirname "$0" )" && pwd )"

## Lets start with the update of the system

apt-get update;
apt-get -y upgrade; 

## Now for the extra dependiencies

apt-get -y install $NEEDED_PKGS;

## GeoIP

echo " "
echo "Grabbing the more detailed GeoIP database"
echo " "

wget http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz;
gunzip GeoLiteCity.dat.gz;
mv GeoLiteCity.dat /usr/share/GeoIP/GeoIPCity.dat;

## Grab Java for Elastic and others

sudo add-apt-repository ppa:webupd8team/java;
sudo apt-get update;
sudo apt-get -y install oracle-java7-installer;

## Start setting up for the ELK stack

##	Here is Elastic

wget http://packages.elasticsearch.org/GPG-KEY-elasticsearch
apt-key add GPG-KEY-elasticsearch
rm GPG-KEY-elasticsearch
apt-add-repository -y 'deb http://packages.elasticsearch.org/elasticsearch/1.2/debian stable main'
awk '/deb-src/ && /elastic/' /etc/apt/sources.list > test
###################################################################################################
##
##		Fix THIS!
##
###################################################################################################
apt-get update;
#apt-get install -y elasticsearch
#update-rc.d elasticsearch defaults 95 10
#/etc/init.d/elasticsearch start

##	Here is logstash

#wget https://download.elasticsearch.org/logstash/logstash/packages/debian/logstash_1.4.2-1-2c0f5a1_all.deb;
#wget https://download.elasticsearch.org/logstash/logstash/packages/debian/logstash-contrib_1.4.2-1-efd53ef_all.deb;
#dpkg -i logstash_1.4.2-1-2c0f5a1_all.deb;
#dpkg -i logstash-contrib_1.4.2-1-efd53ef_all.deb;

##	Here is kibana

wget https://download.elasticsearch.org/kibana/kibana/kibana-3.1.0.tar.gz;
tar xvfz kibana-3.1.0.tar.gz;


## Lets get started with Bro!

git clone --recursive git://git.bro.org/bro;
cd bro;
./configure --prefix=/opt/bro;
make;
make install;


