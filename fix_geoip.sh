#!/bin/bash

mkdir -p /opt/geoip
cd /opt/geoip
wget http://geolite.maxmind.com/download/geoip/database/GeoLite2-City.tar.gz
wget http://geolite.maxmind.com/download/geoip/database/GeoLite2-ASN.tar.gz
for tarfile in *.tar.gz ; do tar xzvf $tarfile ; done
find . -name \*.mmdb -exec mv {} . \;
for tgt in `ls -d */` ; do rm $tgt; done
for tgt in `ls -d *.gz` ; do rm $tgt; done