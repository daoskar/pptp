#!/bin/bash
#Tankibaj
#https://github.com/tankibaj

echo ""
echo ""
echo "What do you want to do?"
echo "	1) Setup PPTP sever"
echo "	2) Add User PPTP"
echo "	3) List User PPTP"
echo "	4) Edit User PPTP"
echo "	6) Restart PPTP"
echo "	7) Status PPTP"
echo "	8) Logs PPTP"
echo "	9) Uninstall PPTP"
echo "  0) Exit"
echo""

read -p "Select an option [0-9]: " option

	case $option in

		1) ##########################################################################
			# Checking Update and Upgrade
			echo "Checking out update and upgrade"
			apt-get update
			apt-get upgrade -y
			echo ""
			echo "Done....."
			echo ""

			# Installing PPTP VPN Tunnel
			echo "Install PPTP VPN Tunnel"
			apt-get -y install pptpd telnet iptables
			echo ""
			echo "Done....."
			echo ""

			# Setting up pptpd-options
			echo "Setting up pptpd-options"
cat > /etc/ppp/pptpd-options <<END
name pptpd
refuse-pap
refuse-chap
refuse-mschap
#require-mschap-v2
#require-mppe-128
ms-dns 8.8.8.8
ms-dns 8.8.4.4
proxyarp
nodefaultroute
lock
nobsdcomp
novj
novjccomp
nologfd
END
			echo ""
			echo "Done....."
			echo ""

			#Find out Public IP
			echo " Finding Public IP"
			PIP=`wget -q -O - http://api.ipify.org`
			echo "Your Public IP: $PIP"
			echo ""
			echo "Done....."
			echo ""

			# Setting up pptpd.conf
			echo "Setting up pptpd.conf"
cat >/etc/pptpd.conf <<END
option /etc/ppp/pptpd-options
logwtmp
bcrelay eth0
localip $PIP
remoteip 192.168.100.100-200
netmask 255.255.255.0
END
			echo ""
			echo "Done....."
			echo ""

			# Lets enable forwarding
			echo "Enable forwarding"
			echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
			# Apply forwarding change
			echo "Apply forwarding change"
			sysctl -p
			echo ""
			echo "Done....."
			echo ""

			# Setting up forwarding rules
			echo "Setting up forwarding rules"
			iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
			iptables -t nat -A POSTROUTING -s 192.168.100.0/24 -j SNAT --to $PIP
			iptables -I INPUT -p tcp --dport 1723 -j ACCEPT
			iptables -I INPUT -p udp --dport 1723 -j ACCEPT
			iptables -I FORWARD -s 192.168.100.0/24 -j ACCEPT
			iptables -I FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
			iptables -A INPUT -i eth0 -p gre -j ACCEPT
			iptables -A FORWARD -i ppp+ -o eth0 -j ACCEPT
			iptables -A FORWARD -i eth0 -o ppp+ -j ACCEPT
			echo ""
			echo "Done....."
			echo ""

			# Now we must save the rules and set them to restore on reboot
			echo "Saving the rules and set them to restore on reboot"
			sh -c "iptables-save > /etc/iptables.rules"
			echo ""
			echo "Done....."
			echo ""

			# Create new file /etc/network/if-pre-up.d/iptablesload
			echo "Create script file iptablesload"
cat >/etc/network/if-pre-up.d/iptablesload <<END
#!/bin/sh
iptables-restore < /etc/iptables.rules
exit 0
END
			echo ""
			echo "Done....."
			echo ""

			# Make your script executable
			echo "Make iptablesload executable"
			chmod +x /etc/network/if-pre-up.d/iptablesload
			echo ""
			echo "Done....."
			echo ""

			# User add 
			read -p "User name: " -e -i admin USER
			read -p "Password: " -e -i 123123 PASS
cat >/etc/ppp/chap-secrets <<END
$USER	pptpd	$PASS	*
END
			/etc/init.d/pptpd restart
			echo ""
			echo "Done....."
			echo ""


			# Addding on System Startup
			echo "Addding on System Startup"
			update-rc.d pptpd defaults
			update-rc.d pptpd enable
			echo ""
			echo "Done....."
			echo ""

			# Final Messsage
			echo ""
			echo ""
			echo ""
			echo ""
			echo ""
			echo ""
			echo "============================================================"
			echo "	Congrats... your PPTP server is ready :)"
			echo "============================================================"
			echo "		Server IP: $PIP"
			echo "		Username: $USER"
			echo "		Password: $PASS"
			echo "============================================================"
			echo ""
			echo ""
			echo ""
		exit;;


		2) ##########################################################################
			#Find out Public IP
			echo " Finding Public IP"
			PIP=`wget -q -O - http://api.ipify.org`
			echo "Your Public IP: $PIP"
			echo ""
			echo "Done....."
			echo ""
			
			# Add user
			read -p "User name: " -e -i admin USER
			read -p "Password: " -e -i 123123 PASS
			echo "$USER	pptpd	$PASS	*" >> /etc/ppp/chap-secrets
			/etc/init.d/pptpd restart
			echo ""
			echo ""
			echo ""
			echo "============================================================"
			echo "		Server IP: $PIP"
			echo "		Username: $USER"
			echo "		Password: $PASS"
			echo "============================================================"
			echo ""
			echo ""
			echo ""
			echo ""
		exit;;


		3) ##########################################################################
			# User list
			tail /etc/ppp/chap-secrets
		exit;;


		4) ##########################################################################
			# Edit chap-secrets
			nano /etc/ppp/chap-secrets
		exit;;


		5) ##########################################################################
			echo "case 2"
		exit;;


		6) ##########################################################################
			# Restart
			/etc/init.d/pptpd restart
		exit;;


		7) ##########################################################################
			# Status
			/etc/init.d/pptpd status
		exit;;


		8) ##########################################################################
			# Logs
			tail -f /var/log/syslog
		exit;;


		9) ##########################################################################
			# Remove Purge
			apt-get remove pptpd
			apt-get purge pptpd
		exit;;


		0) ##########################################################################
		exit;;

	esac

	exit