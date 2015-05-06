# Autoinstall T-Pot on Ubuntu 14.04.x 
This script will install [T-Pot](http://dtag-dev-sec.github.io/mediator/feature/2015/03/17/concept.html) on a fresh Ubuntu 14.04.x LTS (64bit). 

It is intended to be used on hosted servers, where an Ubuntu base image is given and there is no ability to install custom ISO images. 
Successfully tested on Amazon's EC2 Ubuntu 14.04.2 x64 as well as on vanilla Ubuntu 14.04.x in VMware.

Choose Ubuntu 14.04.x as operating system. Make sure you have your SSH key added to your account (~/.ssh/authorized_keys). 
and meet the [system requirements](http://dtag-dev-sec.github.io/mediator/feature/2015/03/17/concept.html#requirements) (>=2GB RAM, 40GB disk, network exposure) for a full T-Pot instance. 

In case you have limited ressources, you can choose a "honeypot only"-mode during install, which will install T-Pot without suricata and ELK dashboard (>=1GB RAM required).

So, clone the repository. Run as root. Enjoy.

    git clone https://github.com/dtag-dev-sec/t-pot-autoinstall.git
    cd t-pot-autoinstall/
    sudo su
    ./install.sh
    
The docker container status is periodically written to ~/docker-status, so you can check if everything is running. 

If you run into problems during installation it might be related to your hoster's custom Ubuntu update repositories. So far, we do not have a solution for this. 
