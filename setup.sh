#!/bin/bash
echo -n "Please input the Promotion Tag: "
read tag
echo "Processing..."
apt update
apt upgrade -y
apt install -y vim git curl build-essential libssl-dev zlib1g-dev
git clone https://github.com/TelegramMessenger/MTProxy
cd MTProxy
make
cd objs/bin
curl -s https://core.telegram.org/getProxySecret -o proxy-secret
curl -s https://core.telegram.org/getProxyConfig -o proxy-multi.conf
secret=`head -c 16 /dev/urandom | xxd -ps`
head="ee"
end="7777772e76756c74722e636f6d"
tls_secret=${head}${secret}${end}
cat>/etc/systemd/system/MTProxy.service<<EOF
[Unit]
Description=MTProxy
After=network.target

[Service]
Type=simple
WorkingDirectory=/root/MTProxy/objs/bin/
ExecStart=/root/MTProxy/objs/bin/mtproto-proxy -u nobody -p 8888 -H 443 -S ${secret} --aes-pwd /root/MTProxy/objs/bin/proxy-secret /root/MTProxy/objs/bin/proxy-multi.conf -M 1 -D www.vultr.com -P ${tag}
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
echo -e "2\n:wq\n" | crontab -e
crontab -l > /tmp/crontab.bak
echo "0 3 * * * /usr/bin/curl -s https://core.telegram.org/getProxyConfig -o /root/MTProxy/objs/bin/proxy-multi.conf" >> /tmp/crontab.bak
echo "0 4 * * * reboot" >> /tmp/crontab.bak
crontab /tmp/crontab.bak
systemctl daemon-reload
systemctl enable MTProxy.service
ipv4=`curl ifconfig.me`
echo "IP Address: ${ipv4}"
echo "Port: 443"
echo "Secret: ${secret}"
echo "TLS-Secret: ${tls_secret}"
echo -e "Direct Link:\ntg://proxy?server=${ipv4}&port=443&secret=${tls_secret}"
echo "Please reboot before connecting the MTProxy."
