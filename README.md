# autosetup
Automatically installs and configures a Vero 4K or RPi device running OSMC or Debian to get a "Netflix-like" experience.

Requirements:
- A VERO 4K or Raspberry Pi 3, HDMI cable, network cable, 16GB or 32GB fast SD card.
- If you use a RPi3 instead of a Vero 4K, I highly recommend installing OSMC.tv on your RPi3, but it should work on most Debian based systems. 

**MAKE SURE YOU FOLLOW OSMC INSTALLATION INSTRUCTIONS FIRST: https://osmc.tv/download/**

Prepare your device:
1. On first boot, follow the install wizard on your TV.
2. Go to MyOSMC > Apps and install Transmission.
3. Go to MyOSMC > Services, enable SSH and Cron.
4. Go back to the homescreen, find Settings and select System Information. Find the "IP Address" and write it down. For example 192.168.1.1

Get a laptop and login to your device via SSH:
1. Get the tool Putty and open it. 
2. Enter your device IP address like this: osmc@192.168.1.1 and select SSH. Now hit connect.
3. Enter the default password (osmc) and hit enter. 
4. Change the password by typing: passwd and hit enter.

Now you are set, here we go!
1. Download autosetup.sh by copy pasting this command (you can paste by simply right-clicking in the black Putty window):
wget https://raw.githubusercontent.com/zilexa/autosetup/master/autosetup.sh
2. Now you can edit the file to select the features you need and fill in the required details. Run this command to edit the file:
sudo nano autosetup.sh
(save the file with CTRL+O, exit the editor with CTRL+X)
3. Now run the script:
sudo bash OSMCautosetup.sh

Make sure you go through the features, by default everything except OpenVPN, SyncThing and Spotify are selected. If you don't need those, leave it. Do go through all user-specific settings, you need change them correctly.

### FEATURES (1 = will be installed, 0= will be skipped):

DynamicDNS=1 # schedules your Dynamic DNS update URL to be called every 4 hrs.
Transmission=1 # configures Transmission, needs to be installed first via MyOSMC!
OpenVPN=0 # simply installs OpenVPN, nothing else
FlexGet=1 # installs Flexget and downloads my config https://github.com/zilexa/flexget_config
Spotify=0 # installs Spotify Connect (Premium users only) when selected, you only need to add your key to the folder.
SyncThing=0 # installs SyncThing
AddMediaToKodi=1 #the folders containing your media will be added as library sources!
DisableLEDS=1 #RPI2 or RPI3 only, disables the blinking LED. The powerled on the RPI3 cannot be disabled.

# User-specific settings, required for some of the stuff above
Location of your connected USB drive. Connect it to your laptop to figure out it's name. Make sure you create the following folders: TVshows, Movies, Music, Pictures. The first two are required and case sensitive!
MediaFolder='/media/HarddriveLabel' 

### DYNAMIC DNS 
Want to access files/see download progress or manually download when not at home? you can create a nice domain (like zilexa.funstuff.com) otherwise you need to know your IP address given by your ISP. Go to https://freedns.afraid.org/, register for free and go to the  DynamicDNS. Create a nice domain name and then get the url by electing 'cron example'. 
dnsurl="http://test.nl" 

### TRAKT username
For the system to know what series and movies you want to watch, you need a free account on trakt.tv. Go to trakt.tv, create an account, go to your profile, create a list called "TVshows". 
Now search the tvshows you like to watch and add them to the "TVshows" list. 
Search for movies and add them to the "watchlist".
TraktUsername=mytraktusername

### TRANSMISSION: 
Fill in a desired user/password. This will be configured for you. Transmission is the tool to download stuff. Default is osmc/osmc.
TransmissionUser=PickYourUsernameForTransmissionWebUI
TransmissionPw=PickYourPasswordForTransmissionWebUI

#### SPOTIFY CONNECT
Your device will show up in the Spotify app when you are connected to your home network. You can playback music on the device!
Fill in your Spotify Premium username and password. 
SpotifyUser=YourSpotifyPremiumUsername
SpotifyPw=YourSpotifyPremiumPassword
SpotifyDeviceName=GiveYourDeviceAname

