# Autoinstall T-Pot on Ubuntu 14.04

This script will install T-Pot on a fresh Ubuntu 14.04. LTS. 

It is intended to be used on hosted servers, where a base image is given and there is no ability to install custom ISO images. 

Choose Ubuntu 14.04 as operating system. Make sure you have your SSH key added to your account (~/.ssh/authorized_keys). 

Clone the repository. Run as root. Enjoy.

    git clone https://github.com/dtag-dev-sec/t-pot-autoinstall.git
    cd t-pot-autoinstall/
    sudo su
    ./install.sh
    

