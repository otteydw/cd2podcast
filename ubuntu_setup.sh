#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root.  Try: sudo $0" 
   exit 1
fi

echo "Running apt update."
apt update
echo
echo

echo "Running apt upgrade."
apt -y upgrade
echo
echo

echo "Installing required packages."
apt-get -y install sox lame ncftp
