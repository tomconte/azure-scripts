#!/bin/bash
set -x
# Executed as root.

PARITY_URL='http://d1h4xl4cr1h0mo.cloudfront.net/beta/x86_64-unknown-linux-gnu/parity'
USER_SCRIPT='kovan-failover-user.sh'

AZUREUSER=$1
ARTIFACTS_URL=$2
ACCOUNT_WALLET="$3"
ACCOUNT_PASSWORD=$4

# Get the json from the parent process argument list.
PPID=$(ps aux | grep kovan-failover | head -1 | awk {'print $2'})
cat /proc/$PPID/cmdline | awk {'print $5'} |  sed 's:^.\(.*\).$:\1:' > /home/$AZUREUSER/key.json
chown ${AZUREUSER} /home/$AZUREUSER/key.json

HOMEDIR="/home/${AZUREUSER}"


curl -sL https://deb.nodesource.com/setup_6.x | sudo -E bash -

# Install Node.JS
apt-get update && apt-get -y install nodejs git

# Install PM2
npm install pm2 -g

# Install parity
bash <(curl https://get.parity.io -Lk)


# Download required files

cd ${HOMEDIR}
wget --no-verbose "${ARTIFACTS_URL}scripts/${USER_SCRIPT}"
wget --no-verbose "${ARTIFACTS_URL}scripts/parity.conf"
wget --no-verbose "${ARTIFACTS_URL}scripts/parity.service"

# Setup startup scripts
sed -i "s/USERNAME/${AZUREUSER}/" parity.conf
sed -i "s/USERNAME/${AZUREUSER}/" parity.service

cp parity.service /etc/systemd/system/
cp parity.conf /root/
systemctl --system enable parity

# Run script as regular user
chown ${AZUREUSER} ${USER_SCRIPT}
chmod +x ${USER_SCRIPT}
su -l ${AZUREUSER} -c "${HOMEDIR}/${USER_SCRIPT} \"${ACCOUNT_WALLET}\" \"${ACCOUNT_PASSWORD}\""
sleep 10
reboot
