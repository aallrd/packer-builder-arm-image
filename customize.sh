#!/bin/bash
set -ex

whoami

NEW_HOSTNAME="${NODE_NAME:?The NODE_NAME environment variable is not set}"
CURRENT_HOSTNAME=$(tr -d " \t\n\r" < /etc/hostname)
echo "New hostname: ${NEW_HOSTNAME}"
echo "Current hostname: ${CURRENT_HOSTNAME}"
echo "${NEW_HOSTNAME}" > /etc/hostname
sed -i "s/127.0.1.1.*${CURRENT_HOSTNAME}/127.0.1.1\t${NEW_HOSTNAME}/g" /etc/hosts
hostname

# Locales
export LANGUAGE=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
locale-gen en_US.UTF-8

# Set locale to en_US.UTF-8
cp /etc/locale.gen /etc/locale.gen.dist
sed -i -e "/^[^#]/s/^/#/" -e "/en_US.UTF-8/s/^#//" /etc/locale.gen
cp /var/cache/debconf/config.dat /var/cache/debconf/config.dat.dist
sed -i -e "s/Value: en_GB.UTF-8/Value: en_US.UTF-8/" \
       -e "s/ locales = en_GB.UTF-8/ locales = en_US.UTF-8/" /var/cache/debconf/config.dat
locale-gen
update-locale LANG=en_US.UTF-8

exec "$BASH" <<- EOF
set -x
# Updates
export DEBIAN_FRONTEND=noninteractive
apt-get dist-upgrade -qy \
  --allow-downgrades \
  --allow-remove-essential \
  --allow-change-held-packages
apt-get update

# Install packages
apt-get install -qy \
    vim \
    git \
    wget \
    curl \
    unzip \
    avahi-daemon \
    netatalk

# Docker install
curl -sSL get.docker.com | sh && \
  usermod pi -aG docker

# Enable ssh for remote access
touch /boot/ssh
systemctl enable ssh
#sed '/PasswordAuthentication/d' -i /etc/ssh/ssh_config
#echo  >> /etc/ssh/ssh_config
#echo 'PasswordAuthentication no' >> /etc/ssh/ssh_config
EOF
