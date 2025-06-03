#!/bin/bash
#A.M

# Locatie fisier textfile collector
OUTPUT="/var/lib/node_exporter/sploader.prom"

# Rulam comanda ca utilizatorul depadmin
STATUS=$(sudo -u depadmin bash -l -c '/shared/spdep/bin/sploader status')

# Golim fisierul .prom ca nu cumva sa avem un status mai vechi
>"$OUTPUT"

# Parcurgem iesirea linie cu linie
echo "$STATUS" | while read -r serv; do
  # Extragem numele serviciului si statusul
  SERVICE=$(echo "$serv" | awk '{print $1}')
  if echo "$serv" | grep -q "is running"; then
    echo "sploader_process_status{process=\"${SERVICE}\"} 1" >> "$OUTPUT"
  else
    echo "sploader_process_status{process=\"${SERVICE}\"} 0" >> "$OUTPUT"
  fi
done

