#!/bin/bash
# Install HA_proxy

#manually set up with https://www.lisenet.com/2021/monitor-haproxy-with-grafana-and-prometheus-haproxy_exporter/ and https://oguzhaninan.gitbook.io/haproxy/prometheus-metrics/haproxy-exporter

#Add repository HAProxy ver 1.8
add-apt-repository ppa:vbernat/haproxy-1.8

#Update the required packages to install HAProxy
apt-get update
echo "Up-to-date HAProxy packages"

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
EOF
fi

systemctl restart haproxy.service
systemctl enable haproxy.service
systemctl status haproxy.service

echo "HAproxy service successfully installed"


#version="${VERSION:-0.18.0}"
#arch="${ARCH:-linux-amd64}"
#bin_dir="${BIN_DIR:-/usr/local/bin}"