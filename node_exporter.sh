#!/bin/bash
# Install node_exporter

#manually set up with https://kifarunix.com/monitor-linux-system-metrics-with-prometheus-node-exporter/

version="${VERSION:-0.18.0}"
arch="${ARCH:-linux-amd64}"
bin_dir="${BIN_DIR:-/usr/local/bin}"

# Check folder opt
mkdir -p /opt;

# Download node_exporter
wget "https://github.com/prometheus/node_exporter/releases/download/v$version/node_exporter-$version.$arch.tar.gz" \
    -O /opt/node_exporter.tar.gz
echo "Downloaded node_exporter v$version"

# Check folder node_exporter
mkdir -p /opt/node_exporter;

# move node_exporter to /usr/local/bin
cd /opt

tar xfz /opt/node_exporter.tar.gz -C /opt/node_exporter || { echo "Error extracting node_exporter tar"; exit 1;}

if [ ! -f $bin_dir/node_exporter ]; then
    cp "/opt/node_exporter/node_exporter-$version.$arch/node_exporter" "$bin_dir";
fi 

if [ ! -f /etc/systemd/system/node_exporter.service ]; then
cat <<EOF > /etc/systemd/system/node_exporter.service
[Unit]
Description=Prometheus Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF
fi

useradd -M -r -s /bin/false node_exporter

chown node_exporter:node_exporter /usr/local/bin/node_exporter

systemctl daemon-reload
systemctl start node_exporter.service
systemctl enable node_exporter.service

echo "Node_exporter successfully installed"

systemctl status node_exporter.service