#!/bin/bash
# Install HA_proxy

#manually set up with https://www.lisenet.com/2021/monitor-haproxy-with-grafana-and-prometheus-haproxy_exporter/ and https://oguzhaninan.gitbook.io/haproxy/prometheus-metrics/haproxy-exporter
source HA_proxy_variables.sh

version="${VERSION:-0.12.0}"
arch="${ARCH:-linux-amd64}"
bin_dir="${BIN_DIR:-/usr/local/bin}"

#Download HA_proxy node_exporter 
wget -q "https://github.com/prometheus/haproxy_exporter/releases/download/v$version/haproxy_exporter-$version.$arch.tar.gz" \
    -O /etc/haproxy_exporter.tar.gz
echo "Downloaded HA_proxy node_exporter v$version"

#Check folder HA_proxy node_exporter
mkdir -p /etc/haproxy_exporter

#Move HA_proxy node_exporter to /usr/local/bin
cd /etc

tar xfz /etc/haproxy_exporter.tar.gz -C /usr/local/bin/ || { echo "Error extracting HA_proxy node_exporter tar"; exit 1;} 

chown -R root: /usr/local/bin/

if [ ! -f $bin_dir/haproxy_exporter ]; then
    cp "/etc/haproxy_exporter/haproxy_exporter-$version.$arch/haproxy_exporter" "$bin_dir";
fi

if [ ! -f /etc/systemd/haproxy_exporter ]; then
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
#ExecReload=/bin/kill -HUP $MAINPID
ExecStart=/usr/local/bin/haproxy_exporter \
  --haproxy.pid-file=/var/run/haproxy.pid \
  --haproxy.timeout=20s \
  --web.listen-address=0.0.0.0:9101 \
  --web.telemetry-path=/metrics \
  '--haproxy.scrape-uri=http://$ip:$service_port/stats;csv'
  

SyslogIdentifier=prometheus
Restart=always

[Install]
WantedBy=multi-user.target
EOF
fi

chown -R root: /etc/systemd/system/haproxy_exporter.service
chmod 0644 /etc/systemd/system/haproxy_exporter.service

systemctl restart haproxy_exporter.service
systemctl enable haproxy_exporter.service
systemctl status haproxy_exporter.service
echo "HA_proxy node_exporter service successfully installed"