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
DynamicDNS=0   #schedules your Dynamic DNS update URL to be called every 4 hrs.
Transmission=0   #configures Transmission, needs to be installed first via MyOSMC
FlexGet=0 #installs Flexget
SpotifyRPi=0    # installs Spotify Connect for RASPBERRY PI (Premium users only, )..
SpotifyVero=0    # installs Spotify Connect for VERO devices (Premium users only, )..
SyncThing=0    # installs SyncThing
AddMediaToKodi=0    #Adds the path to your Movies/TV Shows/Music/Pictures to the Kodi library! Kodi>Settings>Video>Library "update on startup", reboot and your library will be filled!
DisableLEDS=0    #RPI2 or RPI3 only


##########################################
##                                      ##
##  PERSONALISE YOUR CONFIGURATION      ##
##                                      ##
##########################################
#User-specific settings
HomeFolder='/home/osmc'    #make sure you enter your correct homefolder here!
MediaFolder='/media/yourusbdrive'    #enter the path+root of your USB drive or location of your NFS mount ('/mnt/name') 
dyndnsurl="http://sync.afraid.org/u/your-url-id/"
TraktUser=yourtraktusername
TransmissionUser=desiredusername
TransmissionPw=desiredpw
SpotifyDeviceName=YourDeviceName   # pick a name, it will show up in the Spotify app on your phone or computer.


##########################################
##                TASKS                 ##
##  DO NOT TOUCH BELOW THIS LINE!       ##
##                                      ##
##########################################
# Disable LEDs on RPi2 or RPi3 (Power and Activity LEDS, network leds cannot be disabled)
if [ "DisableLEDS" = "1" ] ; then
sudo bash -c 'cat >> $HomeFolder/.kodi/userdata/sources.xml' << EOF
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
sudo bash -c 'cat > $HomeFolder/.kodi/userdata/sources.xml' << EOF
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



if [ "$DynamicDNS" = "1" ] ; then
# Reach your device via an easy URL when you are not at home (via freedns.afraid.org)
line="0 */4 * * * curl -s $dyndnsurl"
(crontab -u osmc -l; echo "$line" ) | crontab -u osmc -
echo "DynamicDNS has been set"
fi



# Configure Transmission and set it to send finished downloads to Kodi library
if [ "$Transmission" = "1" ] ; then
sudo service transmission stop
cd $HomeFolder/.config/transmission-daemon
curl -O https://rawgit.com/zilexa/transmission/master/settings.json
sed -i "s/osmc/$TransmissionUser/g" $HomeFolder/.config/transmission-daemon/settings.json
sed -i "s/OSMC/$TransmissionPw/g" $HomeFolder/.config/transmission-daemon/settings.json
sed -i 's|MediaFolder|'$MediaFolder'|g' $HomeFolder/.config/transmission-daemon/settings.json
sudo chmod 755 settings.json
sudo service transmission start
fi



# install Spotify Connect by installing Raspotify for RPi devices
if [ "$SpotifyRPi" = "1" ] ; then
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
fi 

# install Spotify Connect by installing Raspotify for VERO devices
if [ "$SpotifyVero" = "1" ] ; then
wget https://dtcooper.github.io/raspotify/raspotify-latest.deb
sudo dpkg -i /home/osmc/raspotify-latest.deb
sudo apt-get install -f 
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
sudo echo -e "syncthing\syncthing.service" > /etc/osmc/apps.d/syncthing
fi



# install FlEXGET with magnet, subtitles and transmission support
if [ "$FlexGet" = "1" ] ; then
cd $HomeFolder/
sudo apt-get -y install python3
sudo apt-get -y install python3-pip
sudo apt-get -y install 
sudo apt-get install -y python3-libtorrent
sudo pip3 install --upgrade setuptools
sudo pip3 install virtualenv
virtualenv --system-site-packages -p python3 $HomeFolder/flexget/
cd $HomeFolder/flexget/
bin/pip install flexget
source ~/flexget/bin/activate
pip3 install subliminal>=2.0
pip3 install transmissionrpc
pip3 install transmissionrpc --upgrade
wget -O config.yml https://rawgit.com/zilexa/flexget_config/master/config.yml
wget -O secrets.yml https://rawgit.com/zilexa/flexget_config/master/secrets.yml
sed -i "s/TraktUser/$TraktUser/g" $HomeFolder/flexget/secrets.yml
sed -i "s/TransmissionUser/$TransmissionUser/g" $HomeFolder/flexget/secrets.yml
sed -i "s/TransmissionPw/$TransmissionPw/g" $HomeFolder/flexget/secrets.yml
sed -i 's|media/RootOfMedia/|'$MediaFolder/'|g' $HomeFolder/flexget/secrets.yml
sudo mkdir $HomeFolder/flexget/plugins/
cd $HomeFolder/flexget/plugins/
sudo wget -O log_filter.py https://rawgit.com/zilexa/flexget_config/master/plugins/log_filter.py
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
WorkingDirectory=$HomeFolder/flexget
ExecStart=$HomeFolder/flexget/bin/flexget daemon start --autoreload-config
ExecStop=/$HomeFolder/flexget/bin/flexget daemon stop
ExecReload=$HomeFolder/flexget/bin/flexget daemon reload

[Install]
WantedBy=multi-user.target
EOF

sudo chmod 755 /lib/systemd/system/flexget.service
sudo systemctl enable flexget
$HomeFolder/flexget/bin/flexget trakt auth $TraktUser
fi



sudo -s
if [ "$SpotifyRPi" = "1" ] ; then
# Add the service to MyOSMC so you can easily start/stop it in Kodi with your TV remote
echo -e "raspotify\raspotify.service" > /etc/osmc/apps.d/spotify-connect
fi

if [ "$SpotifyVero" = "1" ] ; then
# Add the service to MyOSMC so you can easily start/stop it in Kodi with your TV remote
echo -e "raspotify\raspotify.service" > /etc/osmc/apps.d/spotify-connect
fi

if [ "$FlexGet" = "1" ] ; then
echo -e "flexget\flexget.service" > /etc/osmc/apps.d/flexget
fi
exit
