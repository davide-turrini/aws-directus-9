#!/bin/bash
echo "Setting up swap memory"
sudo dd if=/dev/zero of=/swapfile bs=128M count=8
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
sudo swapon -s
sudo sh -c "echo /swapfile swap swap defaults 0 0 >> /etc/fstab"
free