pipeline {
  agent any

  parameters {
    string(name: 'TARGET_IP', description: 'IP-ul serverului de monitorizat')
  }

  environment {
    TARGET_USER = 'root'
    PROMETHEUS_HOST = '192.168.60.169'
    PROMETHEUS_USER = 'root'
    PROMETHEUS_NODE_JSON = '/etc/prometheus/targets/nodes.json'
    EXPORTER_PORT = '9100'
  }

  stages {
    stage('Setup pe serverul tinta') {
      steps {
        withCredentials([string(credentialsId: 'ssh-root-password', variable: 'SSH_PASS')]) {
          script {
            sh """
              echo "[INFO] Setup initial pe \$TARGET_IP"

              sshpass -p "\$SSH_PASS" ssh -o StrictHostKeyChecking=no \$TARGET_USER@\$TARGET_IP '
                useradd --no-create-home --shell /bin/false node_exporter || true
                mkdir -p /var/lib/node_exporter/textfile_collector
                chown -R node_exporter:node_exporter /var/lib/node_exporter
                mkdir -p /usr/local/bin
                systemctl daemon-reexec || true
              '

              echo "[INFO] Copiere scripturi de monitorizare"
              sshpass -p "\$SSH_PASS" scp -o StrictHostKeyChecking=no scripts/*.sh \$TARGET_USER@\$TARGET_IP:/var/lib/node_exporter/

              echo "[INFO] Oprire temporara node_exporter pentru update binar"
              sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no $TARGET_USER@$TARGET_IP 'systemctl stop node_exporter || true'

              echo "[INFO] Copiere binar node_exporter"
              sshpass -p "\$SSH_PASS" scp -o StrictHostKeyChecking=no node_exporter \$TARGET_USER@\$TARGET_IP:/usr/local/bin/

              echo "[INFO] Setare permisiuni si creare serviciu node_exporter"
              sshpass -p "\$SSH_PASS" ssh -o StrictHostKeyChecking=no \$TARGET_USER@\$TARGET_IP '
                chmod +x /usr/local/bin/node_exporter
                chown node_exporter:node_exporter /usr/local/bin/node_exporter

                cat <<EOF > /etc/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter
Description=Node Exporter
After=network.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter --collector.textfile.directory=/var/lib/node_exporter --collector.systemd

[Install]
WantedBy=multi-user.target
EOF

                systemctl daemon-reexec
                systemctl enable node_exporter
                systemctl restart node_exporter
                iptables -C INPUT -p tcp --dport 9100 -j ACCEPT 2>/dev/null || iptables -A INPUT -p tcp --dport 9100 -j ACCEPT

              '

              echo "[INFO] Configurare crontab pentru scripturi"
              sshpass -p "\$SSH_PASS" ssh -o StrictHostKeyChecking=no \$TARGET_USER@\$TARGET_IP '
                chmod +x /var/lib/node_exporter/*.sh
                crontab -l > tempcron || true
                for script in /var/lib/node_exporter/*.sh; do
                  name=\$(basename "\$script" .sh)
                  line="*/1 * * * * \$script > /var/lib/node_exporter/textfile_collector/\$name.prom"
                  grep -qF "\$line" tempcron || echo "\$line" >> tempcron
                done
                crontab tempcron && rm tempcron
              '
            """
          }
        }
      }
    }


      stage('Inregistrare in Prometheus') {
        steps {
          withCredentials([string(credentialsId: 'ssh-root-password', variable: 'SSH_PASS')]) {
            script {
              def ip = params.TARGET_IP
              def port = env.EXPORTER_PORT
              def nodeFile = env.PROMETHEUS_NODE_JSON
              def sshProm = "sshpass -p '${SSH_PASS}' ssh -o StrictHostKeyChecking=no ${env.PROMETHEUS_USER}@${env.PROMETHEUS_HOST}"
              sh """
                ${sshProm} bash -s <<'EOF'
              jq --arg ip "${ip}" --arg port "${port}" '
                if any(.[]; .targets[] == "\\\\(\$ip):\\\\(\$port)")
                then .
                else . + [{ "targets": ["\\\\(\$ip):\\\\(\$port)"], "labels": { "job": "node_exporter" } }]
                end
              ' ${nodeFile} > temp.json &&
              mv temp.json ${nodeFile} &&
              systemctl reload prometheus
EOF
              """
            }
          }
        }
      }


    stage('Verificare metrica') {
      steps {
        script {
          def status = sh(script: "curl -s http://${params.TARGET_IP}:9100/metrics | grep -q 'node_time_seconds'", returnStatus: true)
          if (status != 0) {
            error("Metrica 'node_time_seconds' nu a fost gasita pe ${params.TARGET_IP}")
          } else {
            echo "Metrica detectata cu succes pe ${params.TARGET_IP}"
          }
        }
      }
    }
  }

  post {
    success {
      echo "✅ Serverul ${params.TARGET_IP} a fost configurat complet pentru monitorizare."
    }
    failure {
      echo "❌ Eroare in procesul de configurare pentru ${params.TARGET_IP}."
    }
  }
}
