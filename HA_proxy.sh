#!/bin/bash
# Install HA_proxy

#manually set up with https://www.lisenet.com/2021/monitor-haproxy-with-grafana-and-prometheus-haproxy_exporter/ and https://oguzhaninan.gitbook.io/haproxy/prometheus-metrics/haproxy-exporter

#Add repository HAProxy ver 1.8
add-apt-repository ppa:vbernat/haproxy-1.8

#Update the required packages to install HAProxy
apt-get update
echo "Up-to-date local packages index"

#Install HAProxy
apt-get install haproxy
echo "Downloaded HAProxy version 1.8"

#Configure HAProxy
if [ ! -f /etc/haproxy/haproxy.cfg ]; then
cat <<EOF > /etc/haproxy/haproxy.cfg
global
	log /dev/log	local0
	log /dev/log	local1 notice
	chroot /var/lib/haproxy
	stats socket /run/haproxy/admin.sock mode 660 level admin
	stats timeout 30s
	user haproxy
	group haproxy
	daemon

	# Default SSL material locations
	ca-base /etc/ssl/certs
	crt-base /etc/ssl/private

	# Default ciphers to use on SSL-enabled listening sockets.
	# For more information, see ciphers(1SSL). This list is from:
	#  https://hynek.me/articles/hardening-your-web-servers-ssl-ciphers/
	ssl-default-bind-ciphers ECDH+AESGCM:DH+AESGCM:ECDH+AES256::RSA+AES:RSA+3DES:!aNULL:!MD5:!DSS
	ssl-default-bind-options no-sslv3

defaults
	log	global
	mode	http
	option	httplog
	option	dontlognull
        timeout connect 5000
        timeout client  50000
        timeout server  50000
	errorfile 400 /etc/haproxy/errors/400.http
	errorfile 403 /etc/haproxy/errors/403.http
	errorfile 408 /etc/haproxy/errors/408.http
	errorfile 500 /etc/haproxy/errors/500.http
	errorfile 502 /etc/haproxy/errors/502.http
	errorfile 503 /etc/haproxy/errors/503.http
	errorfile 504 /etc/haproxy/errors/504.http

frontend stats
  bind *:8404
  stats enable
  stats uri /
  stats refresh 10s
EOF
fi

systemctl start haproxy.service
systemctl enable haproxy.service
systemctl status haproxy.service

echo "HAproxy service successfully installed"

version="${VERSION:-0.12.0}"
arch="${ARCH:-linux-amd64}"
bin_dir="${BIN_DIR:-/usr/local/bin}"

#Download HA_proxy node_exporter 
wget -q "https://github.com/prometheus/haproxy_exporter/releases/download/v$version/haproxy_exporter-$version.$arch.tar.gz" \
    -O /etc/haproxy_exporter.tar.gz
echo "Downloaded HA_proxy node_exporter v$version"

#Check folder HA_proxy node_exporter
mkdir -p /etc/haproxy_exporter;

#Move HA_proxy node_exporter to /usr/local/bin
cd /etc

tar xfz /etc/haproxy_exporter.tar.gz -C /etc/haproxy_exporter || { echo "Error extracting HA_proxy node_exporter tar"; exit 1;} 

chown -R root: /usr/local/bin/

if [ ! -f $bin_dir/haproxy_exporter ]; then
    cp "/etc/haproxy_exporter/haproxy_exporter-$version.$arch/haproxy_exporter" "$bin_dir";
fi

if [ ! -f $bin_dir/haproxy_exporter ]; then
cat <<EOF > /etc/systemd/system/haproxy_exporter.service   
[Unit]
Description=Prometheus
Documentation=https://github.com/prometheus/haproxy_exporter
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=root
Group=root
ExecReload=/bin/kill -HUP $MAINPID
ExecStart=/usr/local/bin/haproxy_exporter \
  --haproxy.pid-file=/var/run/haproxy.pid \
  --haproxy.timeout=20s \
  --web.listen-address=0.0.0.0:9101 \
  --web.telemetry-path=/metrics \
  '--haproxy.scrape-uri=http://10.0.0.10:8404/stats;csv'

SyslogIdentifier=prometheus
Restart=always

[Install]
WantedBy=multi-user.target
EOF
fi

chown -R root: /etc/systemd/system/haproxy_exporter.service

systemctl restart haproxy_exporter.service
systemctl enable haproxy_exporter.service
systemctl status haproxy_exporter.service
echo "HA_proxy node_exporter service successfully installed"