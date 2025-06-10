**Automated Monitoring Setup Pipeline – Jenkins + Prometheus + Grafana**


1. Trigger the Jenkins Pipeline
The user triggers a Jenkins job via “Build with Parameters”
Enters the target server’s IP address
Selects monitoring scripts (e.g., check_httpd.sh, check_php.sh) from a dropdown

2. SSH Connection to Target Server
Jenkins uses sshpass and stored credentials
Connects to the target server as root

3. Prepare the Target Server
Creates the node_exporter user (if not already present)
Creates and configures /var/lib/node_exporter/
Copies the node_exporter binary
Installs a systemd service to manage it
Opens port 9100 in the firewall (iptables)

4. Deploy Monitoring Scripts
Only the selected .sh scripts from /var/lib/jenkins/scripts/ are copied
Jenkins places them in /var/lib/node_exporter/ on the target server
Adds them to crontab to run every minute

5. Register Target in Prometheus
Jenkins connects to the Prometheus server
Adds the new server’s IP:9100 and hostname to nodes.json
Reloads Prometheus (systemctl reload prometheus) to detect the new target

6. Validate Metric Exposure
Jenkins queries the exporter via HTTP: curl $TARGET_IP:9100/metrics
Verifies the presence of a key metric (e.g., node_time_seconds)

7. Grafana Integration (Auto)
Grafana already has global alert rules and dashboards
The new server appears automatically (based on instance, hostname, job labels)
Alerting and visualization are instantly applied

8. Completion
Jenkins prints a success or failure message
The entire process is automated — no manual configuration is needed
