#!/bin/bash

###########################################################################################
#    One-click Desktop & Browser Access Setup Script v0.2.0                               #
#    Written by shc, modified by aoaim                                                    #
#    Original Github link: https://github.com/Har-Kuun/OneClickDesktop                    #
#                                                                                         #
#    This script is distributed in the hope that it will be                               #
#    useful, but ABSOLUTELY WITHOUT ANY WARRANTY.                                         #
#                                                                                         #
#    The author thanks LinuxBabe for providing detailed                                   #
#    instructions on Guacamole setup.                                                     #
#    https://www.linuxbabe.com/debian/apache-guacamole-remote-desktop-debian-10-buster    #
#                                                                                         #
#    Thank you for using this script.                                                     #
###########################################################################################


## 您可以在这里修改 Guacamole 源码下载链接。
## 访问 https://guacamole.apache.org/releases/ 获取最新源码。

GUACAMOLE_DOWNLOAD_LINK="https://mirrors.ocf.berkeley.edu/apache/guacamole/1.4.0/source/guacamole-server-1.4.0.tar.gz"
GUACAMOLE_VERSION="1.4.0"

## 此脚本仅支持Ubuntu 22.04 和 Debian 11。
## 请注意，在其他操作系统上安装此脚本可能会导致不可预料的错误。请在安装前做好备份。

OS_CHECK_ENABLED=ON

#########################################################################
#    Functions start here.                                              #
#    Do not change anything below unless you know what you are doing.   #
#########################################################################

exec > >(tee -i OneClickDesktop.log)
exec 2>&1

function check_OS
{
	if [ -f /etc/lsb-release ] ; then
		cat /etc/lsb-release | grep "DISTRIB_RELEASE=22.04" >/dev/null
		say "注意！！！由于 Ubuntu 22.04 使用了 OpenSSL 3.0.2，暂时无法编译 Guacamole 1.4.0。" red
		say "此问题应该会在 Guacamole 1.5.0 中得到解决。" red
		say "请使用 Ctrl+C 退出此安装进程，否则将不会安装成功。" red
		say "请更换 Debian 11 使用。" red
		echo
		if [ $? = 0 ] ; then
			OS=UBUNTU2204
		else
			say "很抱歉，此脚本仅支持 Ubuntu 22.04 和 Debian 11。" red
			echo 
			exit 1
		fi
	elif [ -f /etc/debian_version ] ; then
		cat /etc/debian_version | grep "^11." >/dev/null
		if [ $? = 0 ] ; then
			OS=DEBIAN11
		else
			say "很抱歉，此脚本仅支持 Ubuntu 22.04 和 Debian 11。" red
			echo 
			exit 1
		fi
	else
		say "很抱歉，此脚本仅支持 Ubuntu 22.04 和 Debian 11。" red
		echo 
		exit 1
	fi
}

function say
{
#This function is a colored version of the built-in "echo."
#https://github.com/Har-Kuun/useful-shell-functions/blob/master/colored-echo.sh
	echo_content=$1
	case $2 in
		black | k ) colorf=0 ;;
		red | r ) colorf=1 ;;
		green | g ) colorf=2 ;;
		yellow | y ) colorf=3 ;;
		blue | b ) colorf=4 ;;
		magenta | m ) colorf=5 ;;
		cyan | c ) colorf=6 ;;
		white | w ) colorf=7 ;;
		* ) colorf=N ;;
	esac
	case $3 in
		black | k ) colorb=0 ;;
		red | r ) colorb=1 ;;
		green | g ) colorb=2 ;;
		yellow | y ) colorb=3 ;;
		blue | b ) colorb=4 ;;
		magenta | m ) colorb=5 ;;
		cyan | c ) colorb=6 ;;
		white | w ) colorb=7 ;;
		* ) colorb=N ;;
	esac
	if [ "x${colorf}" != "xN" ] ; then
		tput setaf $colorf
	fi
	if [ "x${colorb}" != "xN" ] ; then
		tput setab $colorb
	fi
	printf "${echo_content}" | sed -e "s/@B/$(tput bold)/g"
	tput sgr 0
	printf "\n"
}

function determine_system_variables
{
	CurrentUser="$(id -u -n)"
	CurrentDir=$(pwd)
	HomeDir=$HOME
}

function get_user_options
{
	echo 
	say @B"请输入您的 Guacamole 用户名:" yellow
	read guacamole_username
	echo 
	say @B"请输入您的 Guacamole 密码:" yellow
	read guacamole_password_prehash
	read guacamole_password_md5 <<< $(echo -n $guacamole_password_prehash | md5sum | awk '{print $1}')
	echo 
	if [ "x$OS" != "xCENTOS8" ] && [ "x$OS" != "xCENTOS7" ] ; then
		say @B"您想让 Guacamole 通过 RDP 还是 VNC 连接 Linux 桌面？" yellow
		say @B"RDP请输入 1, VNC请输入 2. 如果您不清楚这是什么，请输入 1。" yellow
		read choice_rdpvnc
	else 
		say @B"Guacamole 将通过 RDP 与桌面环境通信。" yellow
		choice_rdpvnc=1
	fi
	echo 
	if [ $choice_rdpvnc = 1 ] ; then
		say @B"请选择屏幕分辨率。" yellow
		echo "默认分辨率 1280x800 请输入 1, 自适应分辨率请输入 2, 手动设置分辨率请输入 3。"
		read rdp_resolution_options
		if [ $rdp_resolution_options = 2 ] ; then
			set_rdp_resolution=0;
		else
			set_rdp_resolution=1;
			if [ $rdp_resolution_options = 3 ] ; then
				echo 
				echo "请输入屏幕宽度（默认为 1280）:"
				read rdp_screen_width_input
				echo "请输入屏幕高度（默认为 800）:"
				read rdp_screen_height_input
				if [ $rdp_screen_width_input -gt 1 ] && [ $rdp_screen_height_input -gt 1 ] ; then
					rdp_screen_width=$rdp_screen_width_input
					rdp_screen_height=$rdp_screen_height_input
				else
					say "屏幕分辨率设置无效。" red
					echo 
					exit 1
				fi
			else
				rdp_screen_width=1280
				rdp_screen_height=800
			fi
		fi
		say @B"屏幕分辨率设置成功。" green
	else
		echo 
		while [ ${#vnc_password} != 8 ] ; do
			say @B"请输入一个长度为 8 位的 VNC 密码:" yellow
		read vnc_password
		done
		say @B"VNC 密码成功设置." green
		echo "通过浏览器方式访问远程桌面时，您将无需使用此 VNC 密码。"
		sleep 1
	fi
	echo 
	say @B"请问您是否想要设置 Nginx 反代？" yellow
	say @B"请注意，如果您想在本地电脑和服务器之间复制粘贴文本，您必须启用反代并设置 SSL. 不过，您也可以暂时先不设置反代，以后再手动设置。" yellow
	echo "请输入 [Y/n]:"
	read install_nginx
	if [ "x$install_nginx" != "xn" ] && [ "x$install_nginx" != "xN" ] ; then
		echo 
		say @B"请输入您的域名（比如desktop.qing.su）:" yellow
		read guacamole_hostname
		echo 
		echo 
		echo "是否为域名${guacamole_hostname}申请免费的 Let's Encrypt SSL 证书？ [Y/N]"
		say @B"设置证书之前，您必须将您的域名指向本服务器的 IP 地址！" yellow
		echo "如果您确认了您的域名已经指向了本服务器的 IP 地址，请输入 Y 开始证书申请。"
		read confirm_letsencrypt
		echo 
		if [ "x$confirm_letsencrypt" = "xY" ] || [ "x$confirm_letsencrypt" = "xy" ] ; then
			echo "请输入一个邮箱地址:"
			read le_email
		fi
	else
		say @B"好的，将跳过 Nginx 安装。" yellow
	fi
	echo 
	say @B"开始安装桌面环境，请稍后。" green
	sleep 3
}	

function install_guacamole_ubuntu_debian
{
	echo 
	say @B"安装依赖环境..." yellow
	echo 
	apt-get update && apt-get upgrade -y
	apt-get install wget curl sudo zip unzip tar perl expect build-essential libcairo2-dev libpng-dev libtool-bin libossp-uuid-dev libvncserver-dev freerdp2-dev libssh2-1-dev libtelnet-dev libwebsockets-dev libpulse-dev libvorbis-dev libwebp-dev libssl-dev libpango1.0-dev libswscale-dev libavcodec-dev libavutil-dev libavformat-dev tomcat9 tomcat9-admin tomcat9-common tomcat9-user japan* chinese* korean* fonts-arphic-ukai fonts-arphic-uming fonts-ipafont-mincho fonts-ipafont-gothic fonts-unfonts-core -y
	if [ "$OS" = "DEBIAN11" ] ; then
		apt-get install libjpeg62-turbo-dev -y
	else
		apt-get install libjpeg-turbo8-dev language-pack-ja language-pack-zh* language-pack-ko -y
	fi
	wget $GUACAMOLE_DOWNLOAD_LINK
	tar zxf guacamole-server-${GUACAMOLE_VERSION}.tar.gz
	rm -f guacamole-server-${GUACAMOLE_VERSION}.tar.gz
	cd $CurrentDir/guacamole-server-$GUACAMOLE_VERSION
	echo "开始安装 Guacamole 服务器..."
	./configure --with-init-dir=/etc/init.d
	if [ -f $CurrentDir/guacamole-server-$GUACAMOLE_VERSION/config.status ] ; then
		say @B"编译条件已满足！" green
		say @B"开始编译源码..." green
		echo
	else
		echo 
		say "依赖环境缺失。" red
		echo "请核查日志，安装必要的依赖环境，并再次运行此脚本。"
		echo 
		exit 1
	fi
	sleep 2
	make
	make install
	ldconfig
	echo "第一次启动 Guacamole 服务器可能需要较长时间..."
	echo "请耐心等待..."
	echo 
	systemctl daemon-reload
	systemctl start guacd
	systemctl enable guacd
	ss -lnpt | grep guacd >/dev/null
	if [ $? = 0 ] ; then
		say @B"Guacamole 服务器安装成功！" green
		echo 
	else 
		say "Guacamole 服务器安装失败。" red
		say @B"请检查上面的日志。" yellow
		exit 1
	fi
}
	
function install_guacamole_web
{
	echo 
	echo "开始安装 Guacamole Web 应用..."
	cd $CurrentDir
	wget https://downloads.apache.org/guacamole/$GUACAMOLE_VERSION/binary/guacamole-$GUACAMOLE_VERSION.war
	mv guacamole-$GUACAMOLE_VERSION.war /var/lib/tomcat9/webapps/guacamole.war
	systemctl restart tomcat9 guacd
	echo 
	say @B"Guacamole Web 应用成功安装！" green
	echo 
}

function configure_guacamole_ubuntu_debian
{
	echo 
	mkdir /etc/guacamole/
	cat >> /etc/guacamole/guacd.conf << EOF
[daemon]
pid_file = /var/run/guacd.pid
#log_level = debug

[server]
#bind_host = localhost
bind_host = 127.0.0.1
bind_port = 4822

#[ssl]
#server_certificate = /etc/ssl/certs/guacd.crt
#server_key = /etc/ssl/private/guacd.key
EOF
	cat > /etc/guacamole/guacamole.properties <<END
guacd-hostname: localhost
guacd-port: 4822
auth-provider: net.sourceforge.guacamole.net.basic.BasicFileAuthenticationProvider
basic-user-mapping: /etc/guacamole/user-mapping.xml
END
	if [ $choice_rdpvnc = 1 ] ; then
		if [ $set_rdp_resolution = 0 ] ; then
			cat > /etc/guacamole/user-mapping.xml <<END
<user-mapping>
    <authorize
         username="$guacamole_username"
         password="$guacamole_password_md5"
         encoding="md5">      
       <connection name="default">
         <protocol>rdp</protocol>
         <param name="hostname">localhost</param>
         <param name="port">3389</param>
       </connection>
    </authorize>
</user-mapping>
END
		else
			cat > /etc/guacamole/user-mapping.xml <<END
<user-mapping>
    <authorize
         username="$guacamole_username"
         password="$guacamole_password_md5"
         encoding="md5">      
       <connection name="default">
         <protocol>rdp</protocol>
         <param name="hostname">localhost</param>
         <param name="port">3389</param>
		 <param name="width">$rdp_screen_width</param>
		 <param name="height">$rdp_screen_height</param>
       </connection>
    </authorize>
</user-mapping>
END
		fi
	else
		cat > /etc/guacamole/user-mapping.xml <<END
<user-mapping>
    <authorize
         username="$guacamole_username"
         password="$guacamole_password_md5"
         encoding="md5">      
       <connection name="default">
         <protocol>vnc</protocol>
         <param name="hostname">localhost</param>
         <param name="port">5901</param>
         <param name="password">$vnc_password</param>
       </connection>
    </authorize>
</user-mapping>
END
	fi
	systemctl restart tomcat9 guacd
	say @B"Guacamole 配置成功！" green
	echo 
}

function install_vnc
{
	echo 
	echo "开始安装桌面环境，Firefox 浏览器，以及 VNC 服务器..."
	say @B"如果系统提示您配置 LightDM，您可以直接按回车键。" yellow
	echo 
	echo "请按回车键继续。"
	read catch_all
	echo 
	if [ "$OS" = "DEBIAN11" ]; then
		apt-get install xfce4 xfce4-goodies firefox-esr tigervnc-standalone-server tigervnc-common -y
	else 
		apt-get install xfce4 xfce4-goodies firefox tigervnc-standalone-server tigervnc-common -y
	fi
	say @B"桌面环境，浏览器，以及 VNC 服务器安装成功。" green
	echo "开始配置 VNC 服务器..."
	sleep 2
	echo 
	mkdir $HomeDir/.vnc
	cat > $HomeDir/.vnc/xstartup <<END
#!/bin/bash

xrdb $HomeDir/.Xresources
startxfce4 &
END
	cat > /etc/systemd/system/vncserver@.service <<END
[Unit]
Description=a wrapper to launch an X server for VNC
After=syslog.target network.target

[Service]
Type=forking
User=$CurrentUser
Group=$CurrentUser
WorkingDirectory=$HomeDir

ExecStartPre=-/usr/bin/vncserver -kill :%i > /dev/null 2>&1
ExecStart=/usr/bin/vncserver -depth 24 -geometry 1280x800 -localhost :%i
ExecStop=/usr/bin/vncserver -kill :%i

[Install]
WantedBy=multi-user.target
END
	vncpassbinpath=/usr/bin/vncpasswd
	/usr/bin/expect <<END
spawn "$vncpassbinpath"
expect "Password:"
send "$vnc_password\r"
expect "Verify:"
send "$vnc_password\r"
expect "Would you like to enter a view-only password (y/n)?"
send "n\r"
expect eof
exit
END
	vncserver
	sleep 2
	vncserver -kill :1
	systemctl start vncserver@1.service
	systemctl enable vncserver@1.service
	/usr/bin/vncconfig -display :1 &
	cat > $HomeDir/Desktop/EnableCopyPaste.sh <<END
#!/bin/bash
/usr/bin/vncconfig -display :1 &
END
	chmod +x $HomeDir/Desktop/EnableCopyPaste.sh
	echo 
	ss -lnpt | grep vnc > /dev/null
	if [ $? = 0 ] ; then
		say @B"VNC 与远程桌面配置成功！" green
		echo 
	else
		say "VNC 安装失败！" red
		say @B"请检查上面的日志。" yellow
		exit 1
	fi
}

function install_rdp
{
	echo 
	echo "开始安装桌面环境，Firefox 浏览器，以及 XRDP 服务器..."
	if [ "$OS" = "UBUNTU2204" ] ; then
		say @B"如果系统提示您配置 LightDM，您可以直接按回车键。" yellow
		echo 
		echo "请按回车键继续。"
		read catch_all
		echo
	else
		apt-get install xfce4 xfce4-goodies firefox-esr xrdp dbus-x11 -y
	fi
	say @B"桌面环境，浏览器，以及 XRDP 服务器安装成功。" green
	echo "开始配置 XRDP 服务器..."
	sleep 2
	echo 
	systemctl enable xrdp
	systemctl restart xrdp
	sleep 5
	echo "等待启动 XRDP 服务器..."
	systemctl restart guacd
	cat > /etc/systemd/system/restartguacd.service <<END
[Unit]
Descript=Restart GUACD

[Service]
ExecStart=/etc/init.d/guacd start
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target

END
	systemctl daemon-reload
	systemctl enable restartguacd
	ss -lnpt | grep xrdp > /dev/null
	if [ $? = 0 ] ; then
		ss -lnpt | grep guacd > /dev/null
		if [ $? = 0 ] ; then
			say @B"XRDP 与桌面环境配置成功!" green
		else 
			say @B"XRDP 与桌面环境配置成功!" green
			sleep 3
			systemctl start guacd
		fi
		echo 
	else
		say "XRDP 安装失败!" red
		say @B"请检查上面的日志。" yellow
		exit 1
	fi
}

function display_license
{
	echo 
	echo '*******************************************************************'
	echo '*       One-click Desktop & Browser Access Setup Script           *'
	echo '*       Version 0.2.0                                             *'
	echo '*       Author: shc (Har-Kuun) https://qing.su                    *'
	echo '*       https://github.com/Har-Kuun/OneClickDesktop               *'
	echo '*       Thank you for using this script.  E-mail: hi@qing.su      *'
	echo '*******************************************************************'
	echo 
}

function install_reverse_proxy
{
	echo 
	say @B"安装 Nginx 反代..." yellow
	sleep 2
	apt install gnupg2 -y
	wget https://nginx.org/keys/nginx_signing.key
	apt-key add nginx_signing.key
	rm nginx_signing.key
	if [ "$OS" = "UBUNTU2204" ] ; then
		cat >> /etc/apt/sources.list.d/nginx.list << EOF
deb https://nginx.org/packages/ubuntu/ jammy nginx
deb-src https://nginx.org/packages/ubuntu/ jammy nginx
EOF
		apt update && apt install nginx certbot python3-certbot-nginx -y
		systemctl enable nginx
		systemctl start nginx
	else
		cat >> /etc/apt/sources.list.d/nginx.list << EOF
deb https://nginx.org/packages/mainline/debian/ bullseye nginx
deb-src https://nginx.org/packages/mainline/debian bullseye nginx
EOF
		apt update && apt install nginx certbot python3-certbot-nginx -y
		systemctl enable nginx
		systemctl start nginx
	fi
		say @B"Nginx 安装成功！" green
	cat > /etc/nginx/conf.d/guacamole.conf <<END
server {
        listen 80;
        listen [::]:80;
        server_name $guacamole_hostname;

        access_log  /var/log/nginx/guac_access.log;
        error_log  /var/log/nginx/guac_error.log;

        location / {
                    proxy_pass http://127.0.0.1:8080/guacamole/;
                    proxy_buffering off;
                    proxy_http_version 1.1;
                    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
                    proxy_set_header Upgrade \$http_upgrade;
                    proxy_set_header Connection \$http_connection;
                    proxy_cookie_path /guacamole/ /;
        }
}
END
	systemctl reload nginx
	if [ "x$confirm_letsencrypt" = "xY" ] || [ "x$confirm_letsencrypt" = "xy" ] ; then
		certbot --nginx --agree-tos --redirect --hsts --staple-ocsp --email $le_email -d $guacamole_hostname
		echo 
		if [ -f /etc/letsencrypt/live/$guacamole_hostname/fullchain.pem ] ; then
			say @B"恭喜！Let's Encrypt SSL证书安装成功！" green
			say @B"开始使用您的远程桌面，请在浏览器中访问 https://${guacamole_hostname}!" green
		else
			say "Let's Encrypt SSL 证书安装失败。" red
			say @B"您可以请手动执行 \"certbot --nginx --agree-tos --redirect --hsts --staple-ocsp --email $le_email -d $guacamole_hostname\"." yellow
			say @B"开始使用您的远程桌面，请在浏览器中访问 http://${guacamole_hostname} ！" green
		fi
	else
		say @B"Let's Encrypt 证书未安装，如果您之后需要安装 Let's Encrypt 证书，请手动执行 \"certbot --nginx --agree-tos --redirect --hsts --staple-ocsp -d $guacamole_hostname\"." yellow
		say @B"开始使用您的远程桌面，请在浏览器中访问 http://${guacamole_hostname}!" green
	fi
	say @B"您的Guacamole用户名是 $guacamole_username，您的Guacamole密码是 $guacamole_password_prehash。" green
}

function main
{
	display_license
	if [ "x$OS_CHECK_ENABLED" != "xOFF" ] ; then
		check_OS
	fi
	echo "此脚本将在本服务器上安装一个桌面环境。您可以随时随地在浏览器上使用这个桌面环境。"
	echo 
	say @B"此桌面环境需要至少 1.5 GB内存。" yellow
	echo 
	echo "请问是否继续？ [Y/N]"
	read confirm_installation
	if [ "x$confirm_installation" = "xY" ] || [ "x$confirm_installation" = "xy" ] ; then
		determine_system_variables
		get_user_options
		install_guacamole_ubuntu_debian
		install_guacamole_web
		configure_guacamole_ubuntu_debian
		if [ $choice_rdpvnc = 1 ] ; then
			install_rdp
		else
			install_vnc
		fi
		if [ "x$install_nginx" != "xn" ] && [ "x$install_nginx" != "xN" ] ; then
			install_reverse_proxy
		else
			say @B"开始使用您的远程桌面，请在浏览器中访问 http://$(curl -s icanhazip.com):8080/guacamole ！" green
			say @B"您的 Guacamole 用户名是 $guacamole_username，密码是 $guacamole_password_prehash 。" green
		fi
		if [ $choice_rdpvnc = 1 ] ; then
			echo 
			say @B"请注意，使用上述用户名与密码登录 Guacamole 后，您还会需要在 XRDP 登录界面输入 Linux 系统用户名与密码。Session Type请选择默认的Xorg." yellow
		fi
	fi
	echo 
	echo "感谢使用！"
}

###############################################################
#                                                             #
#               The main function starts here.                #
#                                                             #
###############################################################

main
exit 0
