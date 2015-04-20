#!/bin/bash

#################################################
## This is an automation script to install     ##
## the Malware Repository Framework by Adlice. ##
## Created by Zac "ph3n0" Hinkel.              ##
## github/ph3n0 or zac at phenotyne . com      ##
#################################################

echo "This is an automation script for the install of the "
echo "Malware Repository Framework by Adlice."
echo " "
echo "The base system is Ubuntu 14.04.1 Server, installed by "
echo "VMWare using easy install. It is the quickest way, and I"
echo "assume most people are using something similar. This is "
echo "quick and dirty. You should probably follow up with some"
echo "best practices to harden the machine once the script is done. "
echo " "
echo "You will need to run as root or sudo since we will be installing packages"
echo " "

NEEDED_PKGS="git apache2 apache2-utils mysql-server mysql-client mysql-common libmcrypt4 php5 php5-mcrypt libapache2-mod-php5 libapache2-mod-auth-mysql php5-mysql php5-curl"

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi
 
while true; do
    read -p "Are you ready to get started?" yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

CURRENT_DIR="$( cd "$( dirname "$0" )" && pwd )"

## Install needed Ubuntu packages with apt-get

#Get updated
apt-get update && sudo apt-get -y upgrade


#Install extra packages
apt-get -y install $NEEDED_PKGS

# Do some MySQL Mx
mysql_install_db

## Lets grab the framework from GitHub
git clone https://github.com/Tigzy/malware-repo.git

## Move the files over to the web directory
mv ./malware-repo/* /var/www/html

## Get rid of that git directory.
rm -rf ./malware-repo

## Create the MySQL DB of 'storage' 
## And yes I know there is a better way to do this
## but remember quick and dirty? ;)

echo " "
echo "We are about to create the mySQL database MRF will use"
echo "The database will be named MRF and the user MRF_USER"
echo "Unfortunately this is going to write a temporary file"
echo "that does contain the user password while we create the DB."
echo "This file will be deleted as soon as it is imported."
echo " "
echo "Please provide a password for the MRF_USER account"
echo "P.S This isn't going to echo back. "
echo " "
read -s -p "Enter MRF_USER password : " SQL_USER_PASS
echo

cat <<_EOF_ >> maldb.sql
CREATE DATABASE MRF;
USE MRF;
CREATE USER 'MRF_USER'@'localhost' IDENTIFIED BY '$SQL_USER_PASS';
GRANT ALL PRIVILEGES ON MRF . * TO 'MRF_USER'@'localhost';
CREATE TABLE IF NOT EXISTS \`storage\` (
  \`md5\` VARCHAR(32) NOT NULL,
  \`filename\` text NOT NULL,
  \`vendor\` text NOT NULL,
  \`vtlink\` text NOT NULL,
  \`vt_scan_id\` text NOT NULL,
  \`filesize\` INT(11) NOT NULL,
  \`vtscore\` INT(11) NOT NULL DEFAULT '0',
  \`is_vtscanned\` INT(11) NOT NULL DEFAULT '0',
  \`timestamp\` datetime NOT NULL,
  \`cuckoo_link\` text NOT NULL,
  \`is_cuckoo_scanned\` INT(11) NOT NULL DEFAULT '-2'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

ALTER TABLE \`storage\`
 ADD UNIQUE KEY \`md5\` (\`md5\`);
_EOF_

echo " "
echo "The MySQL import is ready next we need your MYSQL root password you"
echo "set when the MySQL package was being installed."
echo " "

#Import the file we just made to create the db and user.
mysql -uroot -p < maldb.sql

#Delete that import file
rm maldb.sql

#Set the database username and password in the PHP file

perl -pi -e 's/YOUR_LOGIN_HERE/MRF_USER/g' /var/www/html/server/php/Database.php

perl -pi -e "s/YOUR_PASSWORD_HERE/$SQL_USER_PASS/g" /var/www/html/server/php/Database.php

##Store the Malware in /opt/malware

echo " "
echo "Where would you like to store your malware?"
echo " "
echo "I am going to create the directory if it does not exist."
echo " "
read -e -p "Enter location: " -i "/opt/malware_storage" STORAGE_LOCATION

mkdir -p $STORAGE_LOCATION

v=$STORAGE_LOCATION perl -pi -e 's/YOUR_STORAGE_FOLDER_FULL_PATH_HERE/$ENV{v}/g' /var/www/html/server/php/index.php

## Set the VT API KEY
echo " "
echo "Now we need to set your VirusTotal API Key."
echo " "
echo "If you do not have an API key, you can obtain it my making"
echo "a free account at www.virustotal.com. Then once you confirm"
echo "your email you can login, click your profile at the top right"
echo "and then click My API Key."
echo " "
read -p "Enter VT API Key: " VT_API_KEY

perl -pi -e "s/YOUR_VT_API_KEY_HERE/$VT_API_KEY/g" /var/www/html/server/php/UploadCallback.php

## All done . . . hopefully

HOSTIP="$(ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p')"

echo " "
echo "*************************************"
echo "** Well that should be everything. **"
echo "*************************************" 
echo " "
echo "You should be able to load up the repository"
echo "now by going to http://"$HOSTIP
echo " "




