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

NEEDED_PKGS="git gawk libgeoip-dev sendmail ruby cmake make gcc g++ flex bison libpcap-dev libssl-dev python-dev swig zlib1g-dev libcurl4-openssl-dev python-software-properties libgoogle-perftools-dev python-software-properties software-properties-common"

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

### IPSumDump

cd /usr/src;
wget http://www.read.seas.harvard.edu/~kohler/ipsumdump/ipsumdump-1.84.tar.gz
tar xvfz ./ipsumdump-1.84.tar.gz;
cd ipsumdump-1.84;
./configure;
make;
make install;

## Lets get started with Bro!

cd /usr/src;
git clone --recursive git://git.bro.org/bro;
cd bro;
./configure --prefix=/opt/bro;
make;
make install;

export PATH=/opt/bro/bin:$PATH

###################
## Add configuring port
## Add turning on elasticsearch in /opt/bro/share/bro/policy/tuning/logs-to-elasticsearch.bro
## Stop,install,start in broctl

echo " "
echo " Now it is time to configure the monitoring interface."
echo " "
echo " What interface is your SPAN/TAP connected to?"
echo " "
echo " "

read -e -p "Monitoring Interface (such as eth0): " MONITOR_INTERFACE

BRO_CONFIG="/opt/bro/etc/node.cfg"

python -c "import sys; inputfile = '$BRO_CONFIG'; interface = '$MONITOR_INTERFACE'; data = open(inputfile).read(); data.replace ('interface=eth0\n', 'interface=%s\n'%interface); open(inputfile, 'w').write(data)"



## Grab Java for Elastic and others

sudo add-apt-repository ppa:webupd8team/java;
sudo apt-get update;
sudo apt-get -y install oracle-java8-installer;

## Start setting up for the ELK stack

##	Here is Elastic

wget http://packages.elasticsearch.org/GPG-KEY-elasticsearch
apt-key add GPG-KEY-elasticsearch
rm GPG-KEY-elasticsearch
apt-add-repository -y 'deb http://packages.elasticsearch.org/elasticsearch/1.2/debian stable main'

###################################################################################################
## So this weird thing happens with Ubuntu where even though a deb-src repository doesn't exist
## it is still added into the repo location file. So we just need to commend it out or else the
## 'apt-get update' will fail when it can't find it. 
###################################################################################################
REPO_LOC="/etc/


python -c "import sys; inputfile = '$BRO_CONFIG'; interface = '$MONITOR_INTERFACE'; data = open(inputfile).read(); data.replace ('interface=eth0\n', 'interface=%s\n'%interface); open(inputfile, 'w').write(data)"


apt-get update;
apt-get install -y elasticsearch
update-rc.d elasticsearch defaults 95 10
/etc/init.d/elasticsearch start

##	Here is logstash

#### And it is killing resources, so it has been pulled. 

#wget https://download.elasticsearch.org/logstash/logstash/packages/debian/logstash_1.4.2-1-2c0f5a1_all.deb;
#wget https://download.elasticsearch.org/logstash/logstash/packages/debian/logstash-contrib_1.4.2-1-efd53ef_all.deb;
#dpkg -i logstash_1.4.2-1-2c0f5a1_all.deb;
#dpkg -i logstash-contrib_1.4.2-1-efd53ef_all.deb;

##	Here is kibana

wget https://download.elasticsearch.org/kibana/kibana/kibana-3.1.0.tar.gz;
tar xvfz kibana-3.1.0.tar.gz;


