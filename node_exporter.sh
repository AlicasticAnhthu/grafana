#!/bin/bash
# Install node_exporter
version="${VERSION:-0.18.0}"
arch="${ARCH:-linux-amd64}"
bin_dir="${BIN_DIR:-/usr/local/bin}"

# Check folder opt
mkdir -p /opt;

# Download node_exporter
wget "https://github.com/prometheus/node_exporter/releases/download/v$version/node_exporter-$version.linux-amd64.tar.gz"