#!/usr/bin/sh

DIR=/etc/openvpn
BESTAND=$DIR/qyncc.conf
if [ -f $BESTAND ] ;then
	echo Dit script slechts 1x uitvoeren!
	exit 
fi

zypper --non-interactive install openvpn
if [ ! -f /root/zetacert.p12 ] ;then
	echo "Bestand /root/zetacert.p12 bestaat niet kan script niet uitvoeren"
	exit
fi
mv /root/zetacert.p12 $DIR/
cd $DIR

#speciaal voor deze klant een cert klaar gemaakt met simple wachtwoord waarmee boel uitgepakt kan worden.
openssl pkcs12 -in zetacert.p12 -clcerts -nokeys -passin pass:geheim > zeta.crt
openssl pkcs12 -in zetacert.p12 -cacerts -nokeys -passin pass:geheim > ca.crt
openssl pkcs12 -in zetacert.p12 -nocerts -passin pass:geheim -passout pass:geheim | openssl rsa -passin pass:geheim > zeta.key

#openvpn config file weg schrijven
echo "##############################################" >> $BESTAND
echo "# Client-side OpenVPN 2.0 config file        #" >> $BESTAND
echo "# for connecting to multi-client server.     #" >> $BESTAND
echo "##############################################" >> $BESTAND
echo "client" >> $BESTAND
echo "dev tun" >> $BESTAND
echo "proto udp" >> $BESTAND
echo "#mtu-test" >> $BESTAND
echo "#tun-mtu 1500" >> $BESTAND
echo "remote 193.172.141.86 1195" >> $BESTAND
echo "resolv-retry infinite" >> $BESTAND
echo "nobind" >> $BESTAND
echo "persist-key" >> $BESTAND
echo "persist-tun" >> $BESTAND
echo "ca /etc/openvpn/ca.crt" >> $BESTAND
echo "cert /etc/openvpn/zeta.crt" >> $BESTAND
echo "key /etc/openvpn/zeta.key" >> $BESTAND
echo "cipher AES-128-CBC" >> $BESTAND
echo "pull" >> $BESTAND
echo "comp-lzo" >> $BESTAND
echo "verb 3" >> $BESTAND
echo "# start openvpn with --route-nopull and activate routes below to make default route to internet and only cc routes over VPN" >> $BESTAND
echo "route 10.33.0.1 255.255.255.255 vpn_gateway 1" >> $BESTAND
echo "route 10.213.16.0 255.255.240.0 vpn_gateway 1" >> $BESTAND
echo "route 0.0.0.0 192.0.0.0 net_gateway" >> $BESTAND
echo "route 64.0.0.0 192.0.0.0 net_gateway" >> $BESTAND
echo "route 128.0.0.0 192.0.0.0 net_gateway" >> $BESTAND
echo "route 192.0.0.0 192.0.0.0 net_gateway" >> $BESTAND

systemctl enable openvpn@qyncc
systemctl start openvpn@qyncc
