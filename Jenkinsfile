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
            sh '''
              echo "[INFO] Setup initial pe $TARGET_IP"

              /usr/bin/sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no $TARGET_USER@$TARGET_IP '
                useradd --no-create-home --shell /bin/false node_exporter || true
                mkdir -p /var/lib/node_exporter/
                chown -R node_exporter:node_exporter /var/lib/node_exporter
                systemctl daemon-reexec || true
              '

              echo "[INFO] Copiere scripturi"
              /usr/bin/sshpass -p "$SSH_PASS" scp -o StrictHostKeyChecking=no scripts/*.sh $TARGET_USER@$TARGET_IP:/var/lib/node_exporter/

              echo "[INFO] Setare permisiuni si crontab"
              /usr/bin/sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no $TARGET_USER@$TARGET_IP '
                chmod +x /var/lib/node_exporter/*.sh
                crontab -l > tempcron || true
                for script in /var/lib/node_exporter/*.sh; do
                  name=$(basename "$script" .sh)
                  line="*/1 * * * * $script"
                  grep -qF "$line" tempcron || echo "$line" >> tempcron
                done
                crontab tempcron && rm tempcron
              '
            '''
          }
        }
      }
    }

    stage('Inregistrare in Prometheus') {
      steps {
        withCredentials([string(credentialsId: 'ssh-root-password', variable: 'SSH_PASS')]) {
          script {
            sh '''
              echo "[INFO] Adaugare IP in Prometheus"

              /usr/bin/sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no $PROMETHEUS_USER@$PROMETHEUS_HOST '
                ip="$TARGET_IP"
                port="$EXPORTER_PORT"
                node_file="$PROMETHEUS_NODE_JSON"

                jq --arg ip "$ip" --arg port "$port" '
                  if any(.[]; .targets[] == "\\($ip):\\($port)") then .
                  else . + [{ "targets": ["\\($ip):\\($port)"], "labels": { "job": "node_exporter" } }]
                  end
                ' "$node_file" > temp.json &&
                mv temp.json "$node_file" &&
                systemctl reload prometheus
              '
            '''
          }
        }
      }
    }

    stage('Verificare metrica') {
      steps {
        script {
          def status = sh(script: "curl -s http://${params.TARGET_IP}:9100/metrics | grep -q 'service_up'", returnStatus: true)
          if (status != 0) {
            error("Metrica 'service_up' nu a fost gasita pe ${params.TARGET_IP}")
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
