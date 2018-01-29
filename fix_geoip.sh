#!/bin/bash

mkdir -p /opt/geoip
curl http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz | gunzip | tee /opt/geoip/GeoLiteCity.dat
curl http://download.maxmind.com/download/geoip/database/asnum/GeoIPASNum.dat.gz | gunzip | tee /opt/geoip/GeoIPASNum.dat
