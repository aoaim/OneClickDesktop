# OneClickDesktop
A one-click script that installs a remote desktop environment on a Linux server with browser/VNC/RDP access.

Please read the orginal note: https://github.com/Har-Kuun/OneClickDesktop/blob/master/README.md

Only maintain support for Debian 11 and Ubuntu 22.04 (planed).

## How to use
* Firstly, you need to find a spare VPS with at least 1 IPv4, and install Debian 11 64 bit (recommended) or Debian 11 64 bit Ubuntu 22.04 LTS 64 bit OS.
* You need a domain name (can be a subdomain) which points to the IP address of your server.
* Then, please run the following command as a sudo user in SSH.
```
wget https://raw.githubusercontent.com/Har-Kuun/OneClickDesktop/master/OneClickDesktop.sh && sudo bash OneClickDesktop.sh
```
* The script will guide you through the installation process.
* If you encounter any errors, please check the `OneClickDesktop.log` file that's located within the same directory where you download this script.
* Copy/paste between client and server should have been enabled by default.  If you have any problems with copy/paste when using VNC method, please try to run the EnableCopyPaste.sh file on your Desktop.

## Plugins
There is a few plugin scripts/addons available **but it has not been tested in this version**.
* A very simple guide to install Chrome browser.  Check out https://github.com/Har-Kuun/OneClickDesktop/blob/master/plugins/chrome/readme.md
* One-click change Guacamole login password.  Check out https://github.com/Har-Kuun/OneClickDesktop/blob/master/plugins/change-Guacamole-password.sh
* Tutorial to install Baiduyun Net Disk client.  Check out https://github.com/Har-Kuun/OneClickDesktop/blob/master/plugins/baiduyun.md
* A script to set up sound.  Check out https://github.com/Har-Kuun/OneClickDesktop/blob/master/plugins/Audio/readme.md
