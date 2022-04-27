#!/bin/bash
#Manually set up with https://www.observability.blog/nginx-monitoring-with-prometheus/

source Nginx_variables.sh

version="${VERSION:-0.7.0}"
arch="${ARCH:-linux-amd64}"
bin_dir="${BIN_DIR:-/usr/local/bin}"

#Download Nginx node_exporter
wget -q "https://github.com/nginxinc/nginx-prometheus-exporter/releases/download/v$version/nginx-prometheus-exporter-$version-$arch.tar.gz" \
    -O /etc/nginx_exporter.tar.gz

echo "Downloaded nginx_exporter v$version"

#Check folder nginx_exporter
mkdir -p /etc/nginx_exporter

#cd/etc
cd /etc

tar xfz /etc/nginx_exporter.tar.gz -C /usr/local/bin || { echo "Error extracting nginx_exporter tar"; exit 1;}

if [ ! -f $bin_dir/nginx_exporter ]; then
    cp "/etc/nginx_exporter.tar.gz" "$bin_dir";
fi

if [ ! -f /etc/systemd/system/nginx_exporter.service ]; then
cat <<EOF > /etc/systemd/system/nginx_exporter.service
[Unit]
Description=NGINX Prometheus Exporter
After=network.target

[Service]
Type=simple
User=nginx_exporter
Group=nginx_exporter
ExecStart=/usr/local/bin/nginx-prometheus-exporter \
    -web.listen-address=$ip:9113 \
    -nginx.scrape-uri http://127.0.0.1:81/metrics

SyslogIdentifier=nginx_prometheus_exporter
Restart=always

[Install]
WantedBy=multi-user.target
EOF
fi

useradd -r nginx_exporter

systemctl daemon-reload
systemctl restart nginx_exporter.service
systemctl enable nginx_exporter.service

echo "Nginx_exporter successfully installed"

systemctl status nginx_exporter.service
