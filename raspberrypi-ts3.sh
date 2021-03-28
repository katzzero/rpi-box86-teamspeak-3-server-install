#!/bin/bash -x
# This script installs and configures Box86 and then Teamspeak 3 server on Raspberry Pi 2,3 and 4.

# Clone and Install box86
sudo apt-get update  || exit 1
sudo apt install git build-essential cmake jq  || exit 1
cd ~/ && git clone https://github.com/ptitSeb/box86  || exit 1
cd ~/box86 && mkdir build && cd build  || exit 1


# configuring RPI model target
PS3="Select the Raspberry Pi Model: "

select opt in RPi2 RPi3 RPi4; do

  case $opt in
    RPi2)
      cmake .. -DRPI2=1 -DCMAKE_BUILD_TYPE=RelWithDebInfo
      ;;
    RPi3)
      cmake .. -DRPI3=1 -DCMAKE_BUILD_TYPE=RelWithDebInfo
      ;;
    RPi4)
      cmake .. -DRPI4=1 -DCMAKE_BUILD_TYPE=RelWithDebInfo
      ;;
    
    *) 
      echo "Invalid option $REPLY"
      ;;
  esac
done

# Make Box86 and install
make -j$(nproc)  || exit 1
sudo make install  || exit 1

# Restarting the service after installing box86 allows it to be aware of additional binary formats that it can now support.
sudo systemctl restart systemd-binfmt  || exit 1
cd ~/  || exit 1

# Install and configure TS3 server in the guest x86 system
sudo adduser --disabled-password --gecos "" teamspeak
sudo mkdir /usr/local/ts3
sudo chown teamspeak /usr/local/ts3 
sudo su teamspeak  || exit 1
cd /usr/local/ts3 || exit 1

wget $(curl -Ls 'https://www.teamspeak.com/versions/server.json' | jq -r '.linux.x86.mirrors | values[]')  || exit 1
tar xvf teamspeak3-server_linux_x86-*  || exit 1
rm teamspeak3-server_linux_x86-*  || exit 1
cd teamspeak3-server_linux_x86  || exit 1
sudo touch .ts3server_license_accepted  || exit 1
ts3server_startscript.sh start > ts3-credentials.txt 2>&1  || exit 1
echo "Important credentials information stored on /usr/local/ts3/ts3-credentials.txt." 
sudo mv ts3.service /etc/systemd/system/ts3.service   || exit 1
systemctl daemon-reload  || exit 1
exit 0
