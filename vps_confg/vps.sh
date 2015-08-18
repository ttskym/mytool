#! /bin/bash

while getopts sp name #参数处理，s为配置shadowsocks server，p为PPTP
do
    case $name in
        s)sopt=1;;
        p)popt=1;;
    esac
done

if [[ ! -z $sopt ]]
then
## shadowsocks configuration
git version || yum -y install git
git clone https://github.com/shadowsocks/shadowsocks.git && cd shadowsocks && python setup.py install
if [[ ! -f /etc/shadowsocks.json ]]
then
    su -c "mv ~/shadowsocks.json /etc/shadowsocks.json" #以root身份执行该条命
fi

ssserver -c /etc/shadowsocks.json -d start  #以守护进程开启后台运行
rclocal=/etc/rc.local
grep '^ssserver' /etc/rc.local
if [[ $? -ne 0  ]]  #$?为上条命令的执行结果，0表示成功，否则失败。
then
echo 'ssserver -c /etc/shadowsocks.json -d start' |tee -a $rclocal #自定义开启启动
fi
iptables -F
fi

if [[ ! -z $popt ]]
then
## PPTP configuration

yum -y install pptpd || apt-get -y install pptpd

ppp_pptp=/etc/ppp/pptpd-options   #不同发行版的该文件名称不同
if [[ ! -z $ppp_pptp ]]
then
    ppp_pptp="/etc/ppp/options.pptpd"
fi

grep '^localip' /etc/pptpd.conf
if [[ $? -ne 0 ]]
then
echo "localip 10.100.0.18" | tee -a /etc/pptpd.conf
echo "remoteip 10.100.0.2-150" | tee -a /etc/pptpd.conf
fi

grep '^ms-dns' $ppp_pptp
if [[ $? -ne 0  ]]
then
echo "ms-dns 8.8.8.8" | tee -a $ppp_pptp
echo "ms-dns 8.8.4.4" | tee -a $ppp_pptp
fi

sed -i 's/^net.ipv4.ip_forward.*/net.ipv4.ip_forward = 1/g' /etc/sysctl.conf
sed -i 's/^net.ipv4.conf.all.accept_redirects.*/net.ipv4.conf.all.accept_redirects = 0/g' /etc/sysctl.conf
sed -i 's/^net.ipv4.conf.all.send_redirects.*/net.ipv4.conf.all.send_redirects = 0/g' /etc/sysctl.conf
sed -i 's/^net.ipv4.conf.default.rp_filter.*/net.ipv4.conf.default.rp_filter = 0/g' /etc/sysctl.conf
sed -i 's/^net.ipv4.conf.default.accept_source_route.*/net.ipv4.conf.default.accept_source_route = 0/g' /etc/sysctl.conf
sed -i 's/^net.ipv4.conf.default.send_redirects.*/net.ipv4.conf.default.send_redirects = 0/g' /etc/sysctl.conf
sed -i 's/^net.ipv4.icmp_ignore_bogus_error_responses.*/net.ipv4.icmp_ignore_bogus_error_responses = 1/g' /etc/sysctl.conf


echo "lion pptpd lion123 *" |tee -a /etc/ppp/chap-secrets
myIP=$(hostname -I)
iptables -F 
iptables -t nat -A POSTROUTING -j SNAT --to-source $myIP -o eth+
iptables -A INPUT -p tcp -m tcp --dport 1723 -j ACCEPT
service iptables save

for vpn in /proc/sys/net/ipv4/conf/*; do echo 0 > $vpn/accept_redirects; echo 0 > $vpn/send_redirects; done
sysctl -p

service pptpd start
echo 'for vpn in /proc/sys/net/ipv4/conf/*; do echo 0 > $vpn/accept_redirects; echo 0 > $vpn/send_redirects; done' |tee -a /etc/rc.local
echo 'service pptpd start'|tee -a /etc/rc.local 
fi


