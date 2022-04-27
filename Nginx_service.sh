#!/bin/bash
#Install Nginx
#manually set up with https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-ubuntu-18-04 and https://bugs.launchpad.net/ubuntu/+source/nginx/+bug/1581864
source Nginx_variables.sh

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

#Enable port 81 metrics listener
cat <<EOF >> /etc/nginx/sites-available/default
server {
    listen $port_metrics;
    location /metrics {
        stub_status on;
    }
}
EOF
fi

systemctl restart nginx.service
systemctl status nginx.service

#Check if nginx port is running
curl localhost:$port_metrics/metrics
