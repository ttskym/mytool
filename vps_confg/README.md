###vps 初始化配置

###Shadowsocks Server配置

[shadowsocks github 主页](https://github.com/shadowsocks),包含了client和Sever众多版本，这里是我们需要的已经编译好的python版本[Server版本](https://github.com/shadowsocks/shadowsocks)

安装shadowsocks Server
  
	git clone https://github.com/shadowsocks/shadowsocks.git && python setup.py install
	
在/etc目录*(此目录非强制，放在该目录下只是遵循惯例)*创建配置文件(shadowsocks.json)或将准备好的配置文件拷贝此处。配置参数请参考[基本配置范例](http://shadowsocks.org/en/config/quick-guide.html)

以后台守护进程模式指定配置文件启动程序。

	ssserver -c /etc/shadowsocks.json -d start
		
	-c CONFIG              path to config file`<br>
	-d start/stop/restart  daemon mode`

执行`ps -ef|grep shadowsocks`，可见后台进程。

将ssserver启动脚本添加进/etc/rc.local，重启后可自动启动。

###PPTP Server配置

安装pptpd后，配置/etc/ppp/pptpd-options(options.pptpd)，/etc/pptpd.conf及/etc/ppp/chap-secrets三个文件。

pptpd-options 配置清单

	name pptpd
	refuse-pap
	refuse-chap
	refuse-mschap
	require-mschap-v2
	require-mppe-128
	proxyarp
	lock
	nobsdcomp 
	novj
	novjccomp
	nologfd
	ms-dns 8.8.8.8
	ms-dns 8.8.4.4
	
pptpd是服务器的名字，默认拒绝使用pap、chap和mschap认证，而采用mschap-v2进行认证，加密采用128位的mppe方式加密。ms-dns配置的是VPN client连接上VPN服务器之后获得的DNS，需要配置自己所在地的运营商的DNS也可以是第三方的DNS。ms—dns是需要我们手动添加的，其他的参数为配置文件默认。

pptpd.conf文件主要配置localip和remoteip。localip为服务器VPN虚拟接口将分配的IP地址，可设置为与VPN服务器内网地址相同网段的IP，也可以设置为另一网段的IP；remoteip为客户端VPN连接成功后将分配的IP地址段，同样可设置为与VPN服务器内网地址相同网段的IP地址段，也可以设置为另一网段的IP地址段。

/etc/ppp/chap-secrets 进行配置，内容如下：client对应客户端登录用户名，secret为密码，ip为随机分配刚才remoteip池中的地址，也可以自己指定用户连接VPN之后获取的IP地址，server则为服务名。


sysctl.conf中设置net.ipv4.ip_forward = 1 开启系统路由模式。其他的设置为安全设置。

最后，配置iptables。

	iptables -F //将默认的防火墙策略清空，否则往往配置正确却无法试用！！！！

	iptables -t nat -A POSTROUTING -j SNAT --to-source $myIP -o eth+ //配置防火墙NAT转发

	iptables -A INPUT -p tcp -m tcp --dport 1723 -j ACCEPT  //为PPTPD的1723端口开启策略

	service iptables save  //将上述防火墙策略保存，重启后自动载入，否则重启后策略清空。
