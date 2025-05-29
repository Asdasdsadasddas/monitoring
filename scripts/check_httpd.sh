#!/bin/bash

OUT_FILE="/var/lib/node_exporter/httpd.prom"

if systemctl is-active --quiet httpd; then
  echo 'httpd_status 1' > "$OUT_FILE"
else
  echo 'httpd_status 0' > "$OUT_FILE"
fi

