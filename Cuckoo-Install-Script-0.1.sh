#!/bin/bash

######  INFO 
## Not even going to pretend I am some amazing script writer, so on that note please
## send me or post any corrections. You can email at zac at phenotyne.com or on github
## at github.com/ph3n0 
######

NEEDED_PKGS="linux-headers-generic python-magic python-dpkt python-mako python-sqlalchemy python-jinja2 python-bottle ssdeep python-pyrex subversion libfuzzy-dev python-pymongo mongodb g++ libpcre3-dev libcap2-bin git"

## Sorry we need to be root, prey I don't mistype something!

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

## Download and install VirtualBox and Extension Pack

echo "Grabbing VirtualBox 4.2.10\ "

wget http://download.virtualbox.org/virtualbox/4.2.10/virtualbox-4.2_4.2.10-84104~Ubuntu~precise_amd64.deb

dpkg -i virtualbox-4.2_4.2.10-84104~Ubuntu~precise_amd64.deb

wget http://download.virtualbox.org/virtualbox/4.2.10/Oracle_VM_VirtualBox_Extension_Pack-4.2.10.vbox-extpack

vboxmanage extpack install Oracle_VM_VirtualBox_Extension_Pack-4.2.10.vbox-extpack

## VirtualBox web interface
cd /var/www/  
wget https://phpvirtualbox.googlecode.com/files/phpvirtualbox-4.2-4.zip
unzip phpvirtualbox-4.2-4.zip
mv /var/www/phpvirtualbox-4.2-4 /var/www/phpvirtualbox  
#chown -R CHANGME:CHANGME /var/www/phpvirtualbox/  
cp /var/www/phpvirtualbox/config.php-example /var/www/phpvirtualbox/config.php 
## Setup credentials in config  ^^^^^^^^^^^^

## SSDEEP Python set
cd /opt
svn checkout http://pyssdeep.googlecode.com/svn/trunk/ pyssdeep  
cd pyssdeep  
python setup.py build  
python setup.py install

## Yara and Python Support 
cd /usr/src
wget http://yara-project.googlecode.com/files/yara-1.6.tar.gz  
tar -xvzf yara-1.6.tar.gz  
cd yara-1.6  
./configure  
make  
make check  
make install   
cd /usr/src
wget http://yara-project.googlecode.com/files/yara-python-1.6.tar.gz  
tar -xvzf yara-python-1.6.tar.gz  
cd yara-python-1.6  
python setup.py build  
python setup.py install 

## Modify Tcpdump

setcap cap_net_raw,cap_net_admin=eip /usr/sbin/tcpdump  

## Finally installing Cuckoo Sandbox

useradd cuckoo  
groupadd vboxusers
usermod -a -G vboxusers cuckoo   
cd /opt
sudo git clone git://github.com/cuckoobox/cuckoo.git

echo "Well hopefully you don't have 1000 errors on your screen."
echo "If everything looked good then you should have Cuckoo sitting"
echo "in /opt/cuckoo."
echo " "
echo "Don't forget to go back and edit /var/www/phpvirtualbox/config.php"
echo "to add in your login user information for configuring and running"
echo "VMs from the web interface."
echo " "
while true; do
    read -p "Do you wish to edit that config file now?" yn
    case $yn in
        [Yy]* ) nano /var/www/phpvirtualbox/config.php; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

sleep 3

##Clean Up

while true; do
    read -p "Do you wish to clean up downloaded files?" yn
    case $yn in
        [Yy]* ) rm virtualbox-4.2_4.2.10-84104~Ubuntu~precise_amd64.deb; rm Oracle_VM_VirtualBox_Extension_Pack-4.2.10.vbox-extpack; rm /var/www/phpvirtualbox-4.2-4.zip; rm /usr/src/yara-1.6.tar.gz; rm /usr/src/yara-python-1.6.tar.gz; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done