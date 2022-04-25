#!/bin/bash
#Install Nginx
#manually set up with https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-ubuntu-18-04 and https://bugs.launchpad.net/ubuntu/+source/nginx/+bug/1581864

#Install Nginx service
apt update
echo "Up-to-date local packages index"
apt install nginx
echo "Installed Nginx"
#Check listed configu ufw files
ufw app list

#Allow traffic on port 80
ufw allow 'Nginx HTTP'

#Check changes
ufw status

#Workaround when nginx.service: Failed to read PID from file /run/nginx.pid: Invalid argument
mkdir /etc/systemd/system/nginx.service.d
printf "[Service]\nExecStartPost=/bin/sleep 0.1\n" | \
    tee /etc/systemd/system/nginx.service.d/override.conf

systemctl daemon-reload
systemctl restart nginx
systemctl status nginx

#Manually set up with https://www.observability.blog/nginx-monitoring-with-prometheus/

#Enable port 81 metrics listener
if [ ! -f /etc/nginx/sites-available/default ]; then
cat <<EOF > /etc/nginx/sites-available/default
server {
    listen 81;
    location /metrics {
        stub_status on;
    }
}
EOF
fi

systemctl restart nginx.service
systemctl status nginx.service

#Check if nginx port is running
curl localhost:81/metrics

version="${VERSION:-0.7.0}"
arch="${ARCH:-linux-amd64}"
bin_dir="${BIN_DIR:-/usr/local/bin}"

#Change directory to /etc
mkdir -p /opt

#Download Nginx node_exporter
wget -q "https://github.com/nginxinc/nginx-prometheus-exporter/releases/download/v$version/nginx-prometheus-exporter-$version-$arch.tar.gz" \
    -O /opt/nginx_exporter.tar.gz

echo "Downloaded nginx_exporter v$version"

#Check folder nginx_exporter

mkdir -p /opt/nginx_exporter

#cd/opt

tar xfz /opt/nginx_exporter.tar.gz -C /opt/nginx_exporter || { echo "Error extracting nginx_exporter tar"; exit 1;}

if [ ! -f $bin_dir/nginx_exporter ]; then
    cp "/opt/nginx_exporter/nginx-prometheus-exporter-$version-$arch/nginx_exporter" "$bin_dir";
fi

if [ ! -f $etc/system/nginx_exporter.service ]; then
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

useradd -M -r -s nginx_exporter

systemctl daemon-reload
systemctl restart nginx_exporter.service
systemctl enable nginx_exporter.service

echo "Nginx_exporter successfully installed"

systemctl status nginx_exporter.service
