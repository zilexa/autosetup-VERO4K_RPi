
#!/bin/sh
# This script will automatically perform all tasks I usually have to perform manually when setting up a Raspberry
# as mediacenter.
# 1) Schedule the device to check your IP and register it with a DynamicDNS service (such as afraid.freedns.org).
# This allows you to access your device via a easy url (instead of IP address) when not at home.
# 2) Install tools to download media (Transmission) fully automatically (Flexget) and anonymously (OpenVPN).
# 3) Install SpotifyConnect for Spotify Premium users, you can use Spotify app on your phone, tablet, desktop or web
# and select this device to play back on.
# 4) Install SyncThing which allows you to sync files (Photos) from devices like phones and
# computers (documents backup) automatically to this device, a private cloud storage.

##########################################
##                                      ##
##  CHOOSE APPS AND ACTIONS TO PERFORM  ##
##                                      ##
##########################################
# Please select which tasks to perform and don't forget to fill in the user-specific settings in the second part.
# Tasks to perform
DynamicDNS=0 #schedules your Dynamic DNS update URL to be called every 4 hrs.
Transmission=1 #configures Transmission, needs to be installed first via DietPi
FlexGet=1 #installs Flexget
OpenVPN=1 #simply installs OpenVPN, nothing else
Spotify=0 # installs Spotify Connect for RASPBERRY PI (Premium users only, )..
SyncThing=1 # installs SyncThing
DisableLEDS=1 #RPI2 or RPI3 only


##########################################
##                                      ##
##  PERSONALISE YOUR CONFIGURATION      ##
##                                      ##
##########################################
#User-specific settings
MediaFolder='media/ChilleTV'
dyndnsurl="http://sync.afraid.org/u/your-url-id/"
TraktUsername=yourtraktusername
TransmissionUser=desiredusername
TransmissionPw=desiredpw
SpotifyDeviceName=YourDeviceName # pick a name, it will show up in the Spotify app on your phone or computer.




if [ "$DynamicDNS" = "1" ] ; then
# Reach your device via an easy URL when you are not at home (via freedns.afraid.org)
line="0 */4 * * * curl -s $dyndnsurl"
(crontab -u root -l; echo "$line" ) | crontab -u root -
ECHO "DynamicDNS has been set"
fi



# Configure Transmission and set it to send finished downloads to Kodi library
if [ "$Transmission" = "1" ] ; then
sudo service transmission stop
cd /etc/transmission-daemon
curl -O https://rawgit.com/zilexa/transmission/master/settings.json
sed -i "s/osmc/$TransmissionUser/g" /etc/transmission-daemon/settings.json
sed -i "s/OSMC/$TransmissionPw/g" /etc/transmission-daemon/settings.json
sed -i 's|MediaFolder|'$MediaFolder'|g' /etc/.config/transmission-daemon/settings.json
sudo chmod 755 settings.json
sudo service transmission start
fi



# install OpenVPN
if [ "$OpenVPN" = "1" ] ; then
sudo apt-get update
sudo apt-get --yes --force-yes install openvpn
fi



# install Spotify Connect by installing Raspotify, which is a wrapper for LibreSpot
if [ "$Spotify" = "1" ] ; then
sudo apt-get -y install apt-transport-https
curl -sSL https://dtcooper.github.io/raspotify/key.asc | sudo apt-key add -v -
echo 'deb https://dtcooper.github.io/raspotify jessie main' | sudo tee /etc/apt/sources.list.d/raspotify.list
sudo apt-get update
sudo apt-get install apt-transport-https
sudo apt-get -y install raspotify

# Edit the configuration file to set quality to highest (Spotify 320 = Ogg Vorbis -q6) and change the device name
sudo sed -i "s/#BITRATE=\"160\"/BITRATE=\"320\"/g" /etc/default/raspotify
sudo sed -i "s/#DEVICE_NAME=\"raspotify\"/DEVICE_NAME=\"$SpotifyDeviceName\"/g" /etc/default/raspotify
sudo systemctl restart raspotify

exit
fi



# install SyncThing
if [ "$SycnThing" = "1" ] ; then
sudo curl -s https://syncthing.net/release-key.txt | sudo apt-key add -
echo "deb http://apt.syncthing.net/ syncthing release" | sudo tee /etc/apt/sources.list.d/syncthing.list
sudo apt-get update
sudo apt-get install -y syncthing

# Run SyncThing at startup
sudo bash -c 'cat > /lib/systemd/system/syncthing.service' << EOF
[Unit]
Description=Syncthing
Documentation=http://docs.syncthing.net/
After=network.target
Wants=syncthing-inotify@.service
[Service]
User=root
Nice=7
Environment=STNORESTART=yes
ExecStart=/usr/bin/syncthing -no-browser -logflags=0
Restart=on-failure
SuccessExitStatus=2 3 4
RestartForceExitStatus=3 4
[Install]
WantedBy=multi-user.target
EOF

sudo chmod 755 /lib/systemd/system/syncthing.service
sudo chmod a+u /lib/systemd/system/syncthing.service
sudo systemctl daemon-reload
sudo systemctl enable syncthing.service
fi



# install FlEXGET with magnet, subtitles and transmission support
if [ "$FlexGet" = "1" ] ; then
sudo pip install virtualenv
virtualenv --system-site-packages -p python3 /etc/flexget/
cd /etc/flexget/
bin/pip install flexget
source /etc/flexget/bin/activate
pip install subliminal>=2.0
pip install transmissionrpc
pip install transmissionrpc --upgrade
wget https://rawgit.com/zilexa/flexget_config/master/plugins/log_filter.py -P /etc/flexget/plugins/
curl -O https://rawgit.com/zilexa/flexget_config/master/config.yml
curl -O https://rawgit.com/zilexa/flexget_config/master/secrets.yml
sed -i "s/TraktUsername/$TraktUsername/g" /etc/flexget/secrets.yml
sed -i "s/TransmissionUser/$TransmissionUser/g" /etc/flexget/secrets.yml
sed -i "s/TransmissionPw/$TransmissionPw/g" /etc/flexget/secrets.yml
sed -i 's|media/RootOfMedia/|'$MediaFolder/'|g' /etc/flexget/secrets.yml
fi

# Run FLEXGET at startup
if [ "$FlexGet" = "1" ] ; then
sudo bash -c 'cat > /lib/systemd/system/flexget.service' << EOF
[Unit]
Description=Flexget Daemon
After=network.target
[Service]
Type=simple
User=root
UMask=000
WorkingDirectory=/etc/flexget
ExecStart=/etc/flexget/bin/flexget daemon start --autoreload-config
ExecStop=/etc/flexget/bin/flexget daemon stop
ExecReload=/etc/flexget/bin/flexget daemon reload
[Install]
WantedBy=multi-user.target
EOF

sudo chmod 755 /lib/systemd/system/flexget.service
sudo systemctl enable flexget
exit
/etc/flexget/bin/flexget trakt auth $TraktUsername
fi
