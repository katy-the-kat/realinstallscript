#!/bin/sh

apt install qemu-system libvirt-clients libvirt-daemon-system cockpit cockpit-machines neofetch virt-manager -y
apt install --no-install-recommends xfce4 xfce4-terminal -y
wget https://dl.google.com/linux/direct/chrome-remote-desktop_current_amd64.deb
wget -O /var/lib/libvirt/images/alpine.iso https://dl-cdn.alpinelinux.org/alpine/v3.20/releases/x86_64/alpine-virt-3.20.3-x86_64.iso
apt install -y ./chrom*
sudo fallocate -l 192G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
adduser user
usermod -aG sudo user
usermod -aG kvm user
usermod -aG libvirt user
