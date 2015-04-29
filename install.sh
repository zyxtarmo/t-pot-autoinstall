#!/bin/bash
########################################################
# T-Pot install script    							   #
# Ubuntu server 14.04, x64                             #
#                                                      #
# v0.1 by av, DTAG 2015-04-08						   #
#                                                      # 
# based on T-Pot Community Edition Script 			   #
# v0.46 by mo, DTAG, 2015-03-09			   			   #
########################################################


# Let's create a function for colorful output
fuECHO () {
local myRED=1
local myWHT=7
tput setaf $myRED
echo $1 "$2"
tput setaf $myWHT
}

echo "
########################################################
# T-Pot install script    							   #
# for Ubuntu server 14.04, x64                         #
########################################################

Make sure the SSH login for your normal user is working.
"

# check for superuser
if [[ $EUID -ne 0 ]]; then
    fuECHO "This script must be run as root. Do not run via sudo! Script will abort!"
    exit 1
fi

fuECHO "Which user do you usually work with? This script is invoked by root, but what is your normal username?"
read myuser

# Make sure all the necessary prerequisites are met.
fuECHO "Checking prerequisites..." 

# check if user exists
if ! grep -q $myuser /etc/passwd
	then 
		fuECHO "User '$myuser' not found. Script will abort!"
        exit 1
fi


# check if ssh daemon is running
sshstatus=$(service ssh status)
if [[ ! $sshstatus =~ "ssh start/running, process" ]];
	then
		echo "SSH is not running. Script will abort!"
		exit 1
fi
	
# check for available, non-empty SSH key 
if ! fgrep -qs ssh /home/$myuser/.ssh/authorized_keys 
    then
        fuECHO "No SSH keys for user '$myuser' found. Script will abort!"
        exit 1
fi

# check for default SSH port
sshport=$(fgrep Port /etc/ssh/sshd_config|cut -d ' ' -f2)
if [ $sshport != 22 ];
    then
        fuECHO "SSH port is not 22. Script will abort!"
        exit 1
fi

# check if pubkey authentication is active
if ! fgrep -q "PubkeyAuthentication yes" /etc/ssh/sshd_config
	then
		fuECHO "Public Key Authentication is disabled /etc/ssh/sshd_config. Enable it by changing PubkeyAuthentication to 'yes'."
		exit 1
fi

# check for ubuntu 14.04. distribution
if ! fgrep  -q 'Ubuntu 14.04' /etc/issue
    then
        fuECHO "Wrong distribution. Must be Ubuntu 14.04.*. Script will abort! "
        exit 1
fi

# Let's make sure there is a warning if running for a second time
if [ -f install.log ];
  then fuECHO "### Running more than once may complicate things. Erase install.log if you are really sure."
  exit 1;
fi


fuECHO "Everything looks OK..."

# End checks

# Let's log for the beauty of it
set -e
exec 2> >(tee "t-pot-error.log")
exec > >(tee "t-pot-install.log")

# Let's modify the sources list
sed -i '/cdrom/d' /etc/apt/sources.list

# Let's add the docker repository
fuECHO "### Adding docker repository."
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 36A1D7869245C8950F966E92D8576A8BA88D21E9
tee /etc/apt/sources.list.d/docker.list <<EOF
deb https://get.docker.io/ubuntu docker main
EOF

# Let's pull some updates
fuECHO "### Pulling Updates."
apt-get update -y
fuECHO "### Installing Updates."
apt-get dist-upgrade -y

# Let's install all the packages we need
fuECHO "### Installing packages."
apt-get install curl ethtool git ntp libpam-google-authenticator lxc-docker-1.5.0 vim -y

# getting t-pot git repo
fuECHO "### Cloning T-Pot Repository."
cwdir=$(pwd)
git clone https://github.com/dtag-dev-sec/tpotce.git
cp -R $cwdir/tpotce/installer/ $cwdir
rm -rf $cwdir/tpotce/
rm $cwdir/installer/install1.sh $cwdir/installer/install2.sh
cwdir=$cwdir/installer/
cd $cwdir

# Let's add a new user
fuECHO "### Adding new user."
addgroup --gid 2000 tpot
adduser --system --no-create-home --uid 2000 --disabled-password --disabled-login --gid 2000 tpot

# Let's set the hostname
fuECHO "### Setting a new hostname."
myHOST=ce$(date +%s)$RANDOM
hostnamectl set-hostname $myHOST
sed -i 's#127.0.1.1.*#127.0.1.1\t'"$myHOST"'#g' /etc/hosts

# Let's patch sshd_config
fuECHO "### Patching sshd_config to listen on port 64295 and deny password authentication."
sed -i 's#Port 22#Port 64295#' /etc/ssh/sshd_config
sed -i 's#\#PasswordAuthentication yes#PasswordAuthentication no#' /etc/ssh/sshd_config

# Let's patch docker defaults, so we can run images as service
fuECHO "### Patching docker defaults."
tee -a /etc/default/docker <<EOF
DOCKER_OPTS="-r=false"
EOF

# Let's patch /etc/issue for t-pot autoinstall
sed -i '14,15d' $cwdir/etc/issue
echo "Container status is written to ~/docker-status" >> $cwdir/etc/issue

exit 1

# Let's load docker images from remote
fuECHO "### Downloading docker images from DockerHub. Please be patient, this may take a while."
for name in $(cat $cwdir/data/images.conf) 
do
  docker pull dtagdevsec/$name
done

# Let's add the daily update check with a weekly clean interval
fuECHO "### Modifying update checks."
tee /etc/apt/apt.conf.d/10periodic <<EOF
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "0";
APT::Periodic::AutocleanInterval "7";
EOF

# Let's add some conrjobs
fuECHO "### Adding cronjobs."
tee -a /etc/crontab <<EOF

# Determine running containers every 60s 
*/1 * * * * 	root 	/usr/bin/status.sh > /home/$myuser/docker-status

# Check if containers and services are up
*/5 * * * * 	root 	/usr/bin/check.sh

# Check if updated images are available and download them 
27 1 * * *  	root	for i in \$(cat /data/images.conf); do /usr/bin/docker pull dtagdevsec/\$i:latest; done

# Restart docker service and containers
27 3 * * * 	root 	/usr/bin/dcres.sh

# Delete elastic indices older than 30 days
27 4 * * *  root  /usr/bin/docker exec elk bash -c '/usr/local/bin/curator --host 127.0.0.1 delete --older-than 30'
EOF

# Let's take care of some files and permissions
chmod 500 $cwdir/bin/*
chmod 600 $cwdir/data/*
chmod 644 $cwdir/etc/issue
chmod 755 $cwdir/etc/rc.local
chmod 700 $cwdir/home/*
chown $myuser:$myuser $cwdir/home/*
chmod 644 $cwdir/upstart/*

# Let's create some files and folders
fuECHO "### Creating some files and folders."
mkdir -p /data/ews/log /data/ews/conf /data/elk/data /data/elk/log

# Let's move some files
cp -R $cwdir/bin/* /usr/bin/
cp -R $cwdir/data/* /data/
cp -R $cwdir/etc/issue /etc/
cp -R $cwdir/home/* /home/$myuser/
cp -R $cwdir/upstart/* /etc/init/

# Let's take care of some files and permissions
chmod 660 -R /data
chown tpot:tpot -R /data
chown $myuser:$myuser /home/$myuser/2fa_enable.sh

# we already have ssh enabled. so we can remove this.
rm /home/$myuser/ssh_enable.sh

# Final steps
fuECHO "### Thanks for your patience. Now rebooting. Remember to login on SSH port 64295 next time!"
mv $cwdir/etc/rc.local /etc/rc.local && rm -rf $cwdir && sleep 2 &&reboot
