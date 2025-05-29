#!/bin/bash

OUT_FILE="/var/lib/node_exporter/php.prom"

if systemctl is-active --quiet php-fpm; then
  echo 'php_status 1' > "$OUT_FILE"
else
  echo 'php_status 0' > "$OUT_FILE"
fi

