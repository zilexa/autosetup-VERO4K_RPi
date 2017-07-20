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

# Please select which tasks to perform and fill in the user-specific settings.
# Tasks to perform
DynamicDNS=1 #schedules your Dynamic DNS update URL to be called every 4 hrs.
Transmission=1 #configures Transmission, needs to be installed first via MyOSMC
FlexGet=1 #installs Flexget
OpenVPN=0 #simply installs OpenVPN, nothing else
Spotify=0 # installs Spotify Connect (Premium users only) when selected, you only need to add your key to the folder and reboot.
SyncThing=0 # installs SyncThing
AddMediaToKodi=1 #Adds the path to your Movies/TV Shows/Music/Pictures to the Kodi library! Kodi>Settings>Video>Library "update on startup", reboot and your library will be filled!
DisableLEDS=1 #RPI2 or RPI3 only

#User-specific settings
MediaFolder='media/ChilleTV'
dyndnsurl="http://sync.afraid.org/u/your-url-id/"
TraktUsername=yourtraktusername
TransmissionUser=desiredusername
TransmissionPw=desiredpw
SpotifyUser=YourSpotifyPremiumUsername
SpotifyPw=YourSpotifyPremiumPassword
SpotifyDeviceName=ChilleTV # pick a name, it will show up in the Spotify app on your phone or tablet.


# Disable LEDs on RPi2 or RPi3 (Power and Activity LEDS, network leds cannot be disabled)
if [ "DisableLEDS" = "1" ] ; then
sudo bash -c 'cat >> /home/osmc/.kodi/userdata/sources.xml' << EOF
# Disable the ACT LED.
dtparam=act_led_trigger=none
dtparam=act_led_activelow=off
# Disable the PWR LED.
dtparam=pwr_led_trigger=none
dtparam=pwr_led_activelow=off
EOF
fi

# Add media to Kodi
if [ "$AddMediaToKodi" = "1" ] ; then
sudo bash -c 'cat > /home/osmc/.kodi/userdata/sources.xml' << EOF
<sources>
    <programs>
        <default pathversion="1"></default>
    </programs>
    <video>
        <default pathversion="1"></default>
        <source>
            <name>TV Shows</name>
            <path pathversion="1">$MediaFolder/TVshows/</path>
            <allowsharing>true</allowsharing>
        </source>
        <source>
            <name>Movies</name>
            <path pathversion="1">$MediaFolder/Movies/</path>
            <allowsharing>true</allowsharing>
        </source>
    </video>
    <music>
        <default pathversion="1"></default>
        <source>
            <name>Music</name>
            <path pathversion="1">$MediaFolder/Music/</path>
            <allowsharing>true</allowsharing>
        </source>
    </music>
    <pictures>
        <default pathversion="1"></default>
        <source>
            <name>Pictures</name>
            <path pathversion="1">$MediaFolder/Pictures/</path>
            <allowsharing>true</allowsharing>
        </source>
    </pictures>
    <files>
        <default pathversion="1"></default>
    </files>
</sources>
EOF
fi


# update system (required before installing anything)
sudo apt-get update


if [ "$DynamicDNS" = "1" ] ; then
# Reach your device via an easy URL when you are not at home (via freedns.afraid.org)
line="0 */4 * * * curl -s $dyndnsurl"
(crontab -u osmc -l; echo "$line" ) | crontab -u osmc -
ECHO "DynamicDNS has been set"
fi


# Configure Transmission and set it to send finished downloads to Kodi library
if [ "$Transmission" = "1" ] ; then
sudo service transmission stop
cd /home/osmc/.config/transmission-daemon
curl https://gist.githubusercontent.com/zilexa/b8193751ce4011154ed11fc0f597f73b/raw > settings.json
curl https://gist.githubusercontent.com/zilexa/e82211bbfe41de4274b44d0b48b14642/raw > scantokodi.sh
sed -i "s/osmc/$TransmissionUser/g" /home/osmc/.config/transmission-daemon/settings.json
sed -i "s/OSMC/$TransmissionPw/g" /home/osmc/.config/transmission-daemon/settings.json
sed -i 's|MediaFolder|'$MediaFolder'|g' /home/osmc/.config/transmission-daemon/settings.json
sudo chmod 755 settings.json
sudo chmod 755 scantokodi.sh
sudo chmod +x scantokodi.sh
sudo service transmission start
fi


# install OpenVPN
if [ "$OpenVPN" = "1" ] ; then
sudo apt-get --yes --force-yes install openvpn
fi


# install Spotify Connect
if [ "$Spotify" = "1" ] ; then
sudo curl -O http://spotify-connect-web.s3-website.eu-central-1.amazonaws.com/spotify-connect-web.sh
sudo chmod u+x spotify-connect-web.sh
mkdir -p spotify-connect-web-chroot
cd spotify-connect-web-chroot
curl http://spotify-connect-web.s3-website.eu-central-1.amazonaws.com/spotify-connect-web.tar.gz | sudo tar xz

# Run Spotify Connect at startup
sudo bash -c 'cat > /lib/systemd/system/scs1.service' << EOF
[Unit]
Description=Spotify Connect
After=network-online.target

[Service]
Type=idle
User=osmc
ExecStart=/home/osmc/spotify-connect-web.sh --username $SpotifyUser --password $SpotifyPw --bitrate 320 --name $SpotifyDeviceName
Restart=always
RestartSec=10
StartLimitInterval=30
StartLimitBurst=20

[Install]
WantedBy=multi-user.target

EOF

sudo chmod 755 /lib/systemd/system/scs1.service
sudo chmod a+u /lib/systemd/system/scs1.service
sudo systemctl daemon-reload
sudo systemctl enable scs1.service
sudo systemctl start scs1.service
sudo -s
echo -e "scs1\scs1.service" > /etc/osmc/apps.d/spotify-1
su - osmc
fi


# install SyncThing
if [ "$SycnThing" = "1" ] ; then
sudo curl -s https://syncthing.net/release-key.txt | sudo apt-key add -
echo "deb http://apt.syncthing.net/ syncthing release" | sudo tee /etc/apt/sources.list.d/syncthing.list
sudo apt-get install -y syncthing

# Run SyncThing at startup
sudo bash -c 'cat > /lib/systemd/system/syncthing.service' << EOF
[Unit]
Description=Syncthing - OSMC
Documentation=http://docs.syncthing.net/
After=network.target
Wants=syncthing-inotify@.service

[Service]
User=osmc
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
sudo -s
echo -e "syncthing\syncthing.service" > /etc/osmc/apps.d/syncthing
su - osmc
fi


# install FlEXGET with magnet, subtitles and transmission support
if [ "$FlexGet" = "1" ] ; then
cd /home/osmc
sudo apt-get install -y python-libtorrent
sudo apt-get install -y python-pip
sudo pip install --upgrade setuptools
sudo pip install virtualenv
virtualenv --system-site-packages ~/flexget/
cd ~/flexget/
sudo bin/pip install flexget
source ~/flexget/bin/activate
sudo pip install subliminal>=2.0
sudo pip install transmissionrpc
sudo pip install transmissionrpc --upgrade
wget https://gist.githubusercontent.com/zilexa/7d726e5b995a3f5248b0b0d464315481/raw/config.yml
wget https://gist.githubusercontent.com/zilexa/7d726e5b995a3f5248b0b0d464315481/raw/secrets.yml
wget https://gist.githubusercontent.com/zilexa/7d726e5b995a3f5248b0b0d464315481/raw/series.yml
sed -i "s/TraktUsername/$TraktUsername/g" /home/osmc/flexget/secrets.yml
sed -i "s/TransmissionUser/$TransmissionUser/g" /home/osmc/flexget/secrets.yml
sed -i "s/TransmissionPw/$TransmissionPw/g" /home/osmc/flexget/secrets.yml
sed -i 's|media/RootOfMedia/|'$MediaFolder/'|g' /home/osmc/flexget/secrets.yml
fi


# Run FLEXGET at startup
if [ "$FlexGet" = "1" ] ; then
sudo bash -c 'cat > /lib/systemd/system/flexget.service' << EOF
[Unit]
Description=Flexget Daemon
After=network.target

[Service]
Type=simple
User=osmc
UMask=000
WorkingDirectory=/home/osmc/flexget
ExecStart=/home/osmc/flexget/bin/flexget daemon start
ExecStop=/home/osmc/flexget/bin/flexget daemon stop
ExecReload=/home/osmc/flexget/bin/flexget daemon reload

[Install]
WantedBy=multi-user.target
EOF

sudo chmod 755 /lib/systemd/system/flexget.service
sudo systemctl enable flexget
sudo -s
echo -e "flexget\flexget.service" > /etc/osmc/apps.d/flexget
exit
/home/osmc/flexget/bin/flexget trakt auth $TraktUsername
fi
