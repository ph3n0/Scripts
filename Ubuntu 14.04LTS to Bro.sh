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
echo "This is going to install all the packages required to take a Ubuntu 14.04 LTS server x64"
echo "fresh install and setup Bro from git. The system will be updated"
echo "and the required packages will installed. Then the src for Bro will be downloaded"
echo "compiled, and installed. "
echo " "
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
## 
## Stop,install,start in broctl

echo " "
echo " Now it is time to configure the monitoring interface."
echo " "
echo " What interface is your SPAN/TAP connected to?"
echo " "
echo " "

read -e -p "Monitoring Interface (such as eth0): " MONITOR_INTERFACE

BRO_CONFIG="/opt/bro/etc/node.cfg"

python -c "import sys; inputfile = '$BRO_CONFIG'; interface = '$MONITOR_INTERFACE'; data = open(inputfile).read(); data.replace ('interface=eth0\n', 'interface=%s\n'%interface); open(inputfile, 'w').write(data)";

/opt/bro/bin/broctl install;

/opt/bro/bin/broctl restart; 









