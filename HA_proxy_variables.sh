#!/bin/bash
############################################################
#### File chua thong tin xac thuc variable cua HA_Proxy ####
############################################################
ip="${IP:-ip}"
service_port="${SERVICE_PORT:-8404}"
username="${USERNAME:-admin}"
password="${PASSWORD:-password}"
stats_uri="${STATS_URI:-/haproxy?stats}"
