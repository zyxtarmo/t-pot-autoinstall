#!/bin/bash
##########################################################
# T-Pot 16.03 install script                             #
# Ubuntu server 14.04.04, x64                            #
#                                                        #
# v1.0 by av, DTAG 2016-03-15                            #
#                                                        #
# based on T-Pot 16.03 Community Edition Script          #
# v16.03.14 by mo, DTAG, 2016-03-08                      #
##########################################################


# Let's create a function for colorful output
fuECHO () {
local myRED=1
local myWHT=7
tput setaf $myRED
echo $1 "$2"
tput setaf $myWHT
}

fuECHO ""
echo "
##########################################################
# T-Pot 16.03 install script                             #
# for Ubuntu server 14.04.04, x64                        #
##########################################################
Make sure the SSH login for your normal user is working!
"

# check for superuser
if [[ $EUID -ne 0 ]]; then
    fuECHO "### This script must be run as root. Do not run via sudo! Script will abort!"
    exit 1
fi

echo "Which user do you usually work with? This script is invoked by root, but what is your normal username?"
echo -n "Enter username: "
read myuser

# Make sure all the necessary prerequisites are met.
echo ""
echo "Checking prerequisites..."

# check if user exists
if ! grep -q $myuser /etc/passwd
	then
		fuECHO "### User '$myuser' not found. Script will abort!"
        exit 1
fi


# check if ssh daemon is running
sshstatus=$(service ssh status)
if [[ ! $sshstatus =~ "ssh start/running, process" ]];
	then
		echo "### SSH is not running. Script will abort!"
		exit 1
fi

# check for available, non-empty SSH key
if ! fgrep -qs ssh /home/$myuser/.ssh/authorized_keys
    then
        fuECHO "### No SSH keys for user '$myuser' found. Script will abort!"
        exit 1
fi

# check for default SSH port
sshport=$(fgrep Port /etc/ssh/sshd_config|cut -d ' ' -f2)
if [ $sshport != 22 ];
    then
        fuECHO "### SSH port is not 22. Script will abort!"
        exit 1
fi

# check if pubkey authentication is active
if ! fgrep -q "PubkeyAuthentication yes" /etc/ssh/sshd_config
	then
		fuECHO "### Public Key Authentication is disabled /etc/ssh/sshd_config. Enable it by changing PubkeyAuthentication to 'yes'."
		exit 1
fi

# check for ubuntu 14.04. distribution
if ! fgrep  -q 'Ubuntu 14.04' /etc/issue
    then
        fuECHO "### Wrong distribution. Must be Ubuntu 14.04.*. Script will abort! "
        exit 1
fi

# Let's make sure there is a warning if running for a second time
if [ -f install.log ];
  then
        fuECHO "### Running more than once may complicate things. Erase install.log if you are really sure."
        exit 1
fi


echo "Everything looks OK..."
echo ""
clear
echo "##########################################################"
echo "#                                                        #"
echo "#     How do you want to proceed? Enter your choice.     #"
echo "#                                                        #"
echo "# 1 - T-Pot's STANDARD INSTALLATION (w/o INDUSTRIAL)     #"
echo "#     Requirements: >=4GB RAM, >=64GB disk               #"
echo "#     Services: Cowrie, Dionaea, ElasticPot, Glastopf,   #"
echo "#     Honeytrap, ELK, Suricata+P0f                       #"
echo "#                                                        #"
echo "# 2 - T-Pot's HONEYPOTS ONLY (w/o INDUSTRIAL)            #"
echo "#     Requirements: >=3GB RAM, >=64GB disk               #"
echo "#     Services:                                          #"
echo "#     Cowrie, Dionaea, ElasticPot, Glastopf, Honeytrap   #"
echo "#                                                        #"
echo "# 3 - T-Pot's INDUSTRIAL EDITION                         #"
echo "#     Requirements: >=3GB RAM, >=64GB disk               #"
echo "#     Services: ConPot, eMobility, ELK, Suricata+P0f     #"
echo "#                                                        #"
echo "# 4 - T-Pot's FULL INSTALLATION                          #"
echo "#     Requirements: >=8GB RAM, >=128GB disk              #"
echo "#     Services: Cowrie, Dionaea, ElasticPot, Glastopf,   #"
echo "#     Honeytrap, ELK, Suricata+P0f                       #"
echo "#                                                        #"
echo "##########################################################"
echo ""
echo -n "Your choice: "
read choice
	if [[ "$choice" != [1-4] ]];
		then
    		fuECHO "### You typed $choice, which I don't recognize. It's either '1', '2', '3' or '4'. Script will abort!"
            exit 1
	fi
	case $choice in
	1)
    	echo "You chose T-Pot's STANDARD INSTALLATION. The best default ever!"
    	mode="TPOT"
    	;;
	2)
    	echo "You chose to install T-Pot's HONEYPOTS ONLY. Ack."
    	mode="HP"
    	;;
	3)
    	echo "You chose T-Pot's INDUSTRIAL EDITION. ICS is the new IOT."
    	mode="INDUSTRIAL"
    	;;
	4)
    	echo "You chose to install T-Pot's FULL INSTALLATION. Bring it on..."
    	mode="ALL"
    	;;

	*)
    	fuECHO "### You typed $choice, which I don't recognize. It's either '1', '2', '3' or '4'. Script will abort!"
    	exit 1
    	;;
	esac


# End checks

# Let's log for the beauty of it
set -e
exec 2> >(tee "t-pot-error.log")
exec > >(tee "t-pot-install.log")

# Let's modify the sources list
sed -i '/cdrom/d' /etc/apt/sources.list

# Let's make sure SSH roaming is turned off (CVE-2016-0777, CVE-2016-0778)
fuECHO "### Let's make sure SSH roaming is turned off."
tee -a /etc/ssh/ssh_config <<EOF
UseRoaming no
EOF

# Let's add the docker repository
fuECHO "### Adding the docker repository."
apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
tee /etc/apt/sources.list.d/docker.list <<EOF
deb https://apt.dockerproject.org/repo ubuntu-trusty main
EOF

# Let's pull some updates
fuECHO "### Pulling Updates."
apt-get update -y
fuECHO "### Installing Updates."
apt-get upgrade -y

# Install packages needed
apt-get install apt-transport-https ca-certificates curl dialog dstat ethtool genisoimage git htop libpam-google-authenticator lm-sensors ntp openssh-server syslinux pv vim  -y

# Let's install docker
fuECHO "### Installing docker-engine."
apt-get install docker-engine=1.10.2-0~trusty -y

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

# getting t-pot git repo
fuECHO "### Cloning T-Pot Repository."
cwdir=$(pwd)
git clone https://github.com/dtag-dev-sec/tpotce.git -b 16.03
cp -R $cwdir/tpotce/installer/ $cwdir
rm -rf $cwdir/tpotce/
rm $cwdir/installer/install.sh $cwdir/installer/rc.local.install
cwdir=$cwdir/installer
cd $cwdir

# we need to create a couple of directories
mkdir -p /data/

# Let's make sure only myFLAVOR images will be downloaded and started
case $mode in
  HP)
    echo "### Preparing HONEYPOT flavor installation."
    cp $cwdir/data/imgcfg/hp_images.conf /data/images.conf
  ;;
  INDUSTRIAL)
    echo "### Preparing INDUSTRIAL flavor installation."
    cp $cwdir/data/imgcfg/industrial_images.conf /data/images.conf
  ;;
  TPOT)
    echo "### Preparing TPOT flavor installation."
    cp $cwdir/data/imgcfg/tpot_images.conf /data/images.conf
  ;;
  ALL)
    echo "### Preparing EVERYTHING flavor installation."
    cp $cwdir/data/imgcfg/all_images.conf /data/images.conf
  ;;
esac

# Let's load docker images
fuECHO "### Loading docker images. Please be patient, this may take a while."
if [ -d /root/tpot/images ];
  then
    fuECHO "### Found cached images and will load from local."
    for name in $(cat /data/images.conf)
    do
      fuECHO "### Now loading dtagdevsec/$name:latest1603"
      docker load -i /root/tpot/images/$name:latest1603.img
    done
  else
    for name in $(cat /data/images.conf)
    do
      docker pull dtagdevsec/$name:latest1603
    done
fi

# Let's patch /etc/issue for t-pot autoinstall
sed -i '14,15d' $cwdir/etc/issue
echo "Container status is written to ~/docker-status" >> $cwdir/etc/issue

# Let's add the daily update check with a weekly clean interval
fuECHO "### Modifying update checks."
tee /etc/apt/apt.conf.d/10periodic <<EOF
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "0";
APT::Periodic::AutocleanInterval "7";
EOF

# Let's wait no longer for network than 60 seconds
# fuECHO "### Wait no longer for network than 60 seconds."
# sed -i.bak 's#sleep 60#sleep 30#' /etc/init/failsafe.conf

# Let's make sure to reboot the system after a kernel panic
fuECHO "### Reboot after kernel panic."
tee -a /etc/sysctl.conf <<EOF

# Reboot after kernel panic, check via /proc/sys/kernel/panic[_on_oops]
kernel.panic = 1
kernel.panic_on_oops = 1
EOF

# Let's add some conrjobs
fuECHO "### Adding cronjobs."
tee -a /etc/crontab <<EOF
# Determine running containers every 120s
*/2 * * * * 	root 	/usr/bin/status.sh > /home/$myuser/docker-status
# Check if containers and services are up
*/5 * * * * 	root 	/usr/bin/check.sh
# Check if updated images are available and download them
27 1 * * *  	root	for i in \$(cat /data/images.conf); do /usr/bin/docker pull dtagdevsec/\$i:latest1603; done
# Restart docker service and containers
27 3 * * * 	root 	/usr/bin/dcres.sh
# Delete elastic indices older than 90 days
27 4 * * *  root  /usr/bin/docker exec elk bash -c '/usr/local/bin/curator --host 127.0.0.1 delete indices --older-than 90 --time-unit days --timestring '%Y.%m.%d''
# Update IP and erase check.lock if it exists
27 15 * * * root /etc/rc.local
# Check for updated packages every sunday, upgrade and reboot
27 16 * * 0   root  apt-get autoclean -y; apt-get autoremove -y; apt-get update -y; apt-get upgrade -y; sleep 5; reboot
EOF

# Let's create some files and folders
fuECHO "### Creating some files and folders."
mkdir -p /data/conpot/log \
         /data/cowrie/log/tty/ /data/cowrie/downloads/ /data/cowrie/keys/ /data/cowrie/misc/ \
         /data/dionaea/log /data/dionaea/bistreams /data/dionaea/binaries /data/dionaea/rtp /data/dionaea/wwwroot \
         /data/elasticpot/log \
         /data/elk/data /data/elk/log /data/glastopf /data/honeytrap/log/ /data/honeytrap/attacks/ /data/honeytrap/downloads/ \
         /data/emobility/log \
         /data/ews/log /data/ews/conf /data/ews/dionaea /data/ews/emobility \
         /data/suricata/log /home/$myuser/.ssh/


# Let's take care of some files and permissions
chmod 500 $cwdir/bin/*
chmod 600 $cwdir/data/*
chmod 644 $cwdir/etc/issue
chmod 755 $cwdir/etc/rc.local
chmod 700 $cwdir/home/*
chown $myuser:$myuser $cwdir/home/*
chmod 644 $cwdir/data/upstart/*


# Let's copy some files
tar xvfz $cwdir/data/elkbase.tgz -C /
cp $cwdir/data/elkbase.tgz /data/
cp -R $cwdir/bin/* /usr/bin/
cp -R $cwdir/data/* /data/
cp -R $cwdir/etc/issue /etc/
cp -R $cwdir/home/* /home/$myuser/
for i in $(cat /data/images.conf);
  do
    cp /data/upstart/$i.conf /etc/init/;
done

# Let's turn persistence off by default
touch /data/persistence.off

# Let's take care of some files and permissions
chmod 760 -R /data
chown tpot:tpot -R /data
chmod 600 /home/$myuser/.ssh/authorized_keys
chown $myuser:$myuser /home/$myuser/*.sh /home/$myuser/.ssh /home/$myuser/.ssh/authorized_keys

# Let's clean up apt
apt-get autoclean -y
apt-get autoremove -y

# we already have ssh enabled. so we have to remove this option from ~/2fa_enable.sh.
sed -i '34,45d;16,18d' /home/$myuser/2fa_enable.sh

# Let's enable a color prompt
sed -i 's#\#force_color_prompt=yes#force_color_prompt=yes#' /home/$myuser/.bashrc
sed -i 's#\#force_color_prompt=yes#force_color_prompt=yes#' /root/.bashrc

# Let's create ews.ip before reboot and prevent race condition for first start
myLOCALIP=$(hostname -I | awk '{ print $1 }')
myEXTIP=$(curl myexternalip.com/raw)
sed -i "s#IP:.*#IP: $myLOCALIP, $myEXTIP#" /etc/issue
tee /data/ews/conf/ews.ip << EOF
[MAIN]
ip = $myEXTIP
EOF
chown $myuser:$myuser /data/ews/conf/ews.ip


# Final steps
fuECHO "### Thanks for your patience. Now rebooting. Remember to login on SSH port 64295 next time!"
mv $cwdir/etc/rc.local /etc/rc.local && rm -rf $cwdir && sleep 2 &&reboot
