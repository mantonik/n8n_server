#!/bin/bash 
. /etc/profile 
#update kernel without reboot
/sbin/uptrack-upgrade -y

#update packages
/bin/yum -y update

exit
