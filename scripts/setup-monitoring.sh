#!/bin/bash

# SolarNexus Production Monitoring Setup Script
# Deploys Prometheus, Grafana, and alerting for comprehensive monitoring

set -e

echo "📊 SolarNexus Production Monitoring Setup"
echo "=========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}❌ This script must be run as root${NC}"
   exit 1
fi

# Configuration
MONITORING_DIR="/opt/solarnexus/monitoring"
GRAFANA_PASSWORD="$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-16)"

echo -e "${BLUE}📁 Creating monitoring directory structure...${NC}"
mkdir -p "$MONITORING_DIR"/{prometheus,grafana,alertmanager}
chmod 755 "$MONITORING_DIR"

# Create Prometheus configuration
echo -e "${BLUE}⚙️  Creating Prometheus configuration...${NC}"

cat > "$MONITORING_DIR/prometheus/prometheus.yml" << 'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - "alert_rules.yml"

alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - alertmanager:9093

scrape_configs:
  # SolarNexus Backend
  - job_name: 'solarnexus-backend'
    static_configs:
      - targets: ['solarnexus-backend:3000']
    metrics_path: '/metrics'
    scrape_interval: 30s

  # SolarNexus Frontend (Nginx)
  - job_name: 'solarnexus-frontend'
    static_configs:
      - targets: ['solarnexus-nginx:80']
    metrics_path: '/nginx_status'
    scrape_interval: 30s

  # PostgreSQL
  - job_name: 'postgres'
    static_configs:
      - targets: ['postgres-exporter:9187']
    scrape_interval: 30s

  # Redis
  - job_name: 'redis'
    static_configs:
      - targets: ['redis-exporter:9121']
    scrape_interval: 30s

  # Node Exporter (System metrics)
  - job_name: 'node'
    static_configs:
      - targets: ['node-exporter:9100']
    scrape_interval: 30s

  # Prometheus itself
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
EOF

# Create Prometheus alert rules
cat > "$MONITORING_DIR/prometheus/alert_rules.yml" << 'EOF'
groups:
  - name: solarnexus_alerts
    rules:
      # Service availability alerts
      - alert: ServiceDown
        expr: up == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Service {{ $labels.job }} is down"
          description: "{{ $labels.job }} has been down for more than 1 minute."

      # High CPU usage
      - alert: HighCPUUsage
        expr: 100 - (avg by(instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High CPU usage on {{ $labels.instance }}"
          description: "CPU usage is above 80% for more than 5 minutes."

      # High memory usage
      - alert: HighMemoryUsage
        expr: (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100 > 85
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High memory usage on {{ $labels.instance }}"
          description: "Memory usage is above 85% for more than 5 minutes."

      # Database connection issues
      - alert: DatabaseConnectionHigh
        expr: pg_stat_activity_count > 80
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "High number of database connections"
          description: "PostgreSQL has more than 80 active connections."

      # API response time
      - alert: HighAPIResponseTime
        expr: histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m])) > 2
        for: 3m
        labels:
          severity: warning
        annotations:
          summary: "High API response time"
          description: "95th percentile response time is above 2 seconds."

      # Solar data sync failure
      - alert: SolarDataSyncFailure
        expr: increase(solar_sync_errors_total[10m]) > 5
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Solar data synchronization failing"
          description: "More than 5 solar data sync errors in the last 10 minutes."

      # Disk space
      - alert: DiskSpaceLow
        expr: (node_filesystem_avail_bytes / node_filesystem_size_bytes) * 100 < 10
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Low disk space on {{ $labels.instance }}"
          description: "Disk space is below 10% on {{ $labels.mountpoint }}."
EOF

# Create Alertmanager configuration
echo -e "${BLUE}📧 Creating Alertmanager configuration...${NC}"

cat > "$MONITORING_DIR/alertmanager/alertmanager.yml" << 'EOF'
global:
  smtp_smarthost: 'smtp.gmail.com:587'
  smtp_from: 'alerts@nexus.gonxt.tech'
  smtp_auth_username: 'alerts@nexus.gonxt.tech'
  smtp_auth_password: 'YOUR_EMAIL_PASSWORD'

route:
  group_by: ['alertname']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 1h
  receiver: 'web.hook'

receivers:
  - name: 'web.hook'
    email_configs:
      - to: 'admin@nexus.gonxt.tech'
        subject: 'SolarNexus Alert: {{ .GroupLabels.alertname }}'
        body: |
          {{ range .Alerts }}
          Alert: {{ .Annotations.summary }}
          Description: {{ .Annotations.description }}
          Labels: {{ range .Labels.SortedPairs }}{{ .Name }}={{ .Value }} {{ end }}
          {{ end }}

inhibit_rules:
  - source_match:
      severity: 'critical'
    target_match:
      severity: 'warning'
    equal: ['alertname', 'dev', 'instance']
EOF

# Create Grafana provisioning
echo -e "${BLUE}📊 Creating Grafana configuration...${NC}"

mkdir -p "$MONITORING_DIR/grafana"/{dashboards,provisioning/{dashboards,datasources}}

# Grafana datasource configuration
cat > "$MONITORING_DIR/grafana/provisioning/datasources/prometheus.yml" << 'EOF'
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: true
EOF

# Grafana dashboard provisioning
cat > "$MONITORING_DIR/grafana/provisioning/dashboards/dashboard.yml" << 'EOF'
apiVersion: 1

providers:
  - name: 'default'
    orgId: 1
    folder: ''
    type: file
    disableDeletion: false
    updateIntervalSeconds: 10
    allowUiUpdates: true
    options:
      path: /var/lib/grafana/dashboards
EOF

# Create SolarNexus dashboard
cat > "$MONITORING_DIR/grafana/dashboards/solarnexus-dashboard.json" << 'EOF'
{
  "dashboard": {
    "id": null,
    "title": "SolarNexus Production Dashboard",
    "tags": ["solarnexus", "production"],
    "timezone": "browser",
    "panels": [
      {
        "id": 1,
        "title": "Service Status",
        "type": "stat",
        "targets": [
          {
            "expr": "up",
            "legendFormat": "{{ job }}"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "color": {
              "mode": "thresholds"
            },
            "thresholds": {
              "steps": [
                {"color": "red", "value": 0},
                {"color": "green", "value": 1}
              ]
            }
          }
        },
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": 0}
      },
      {
        "id": 2,
        "title": "API Response Time",
        "type": "graph",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))",
            "legendFormat": "95th percentile"
          }
        ],
        "gridPos": {"h": 8, "w": 12, "x": 12, "y": 0}
      },
      {
        "id": 3,
        "title": "System Resources",
        "type": "graph",
        "targets": [
          {
            "expr": "100 - (avg(irate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)",
            "legendFormat": "CPU Usage %"
          },
          {
            "expr": "(node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100",
            "legendFormat": "Memory Usage %"
          }
        ],
        "gridPos": {"h": 8, "w": 24, "x": 0, "y": 8}
      }
    ],
    "time": {
      "from": "now-1h",
      "to": "now"
    },
    "refresh": "30s"
  }
}
EOF

# Create Docker Compose for monitoring stack
echo -e "${BLUE}🐳 Creating monitoring Docker Compose...${NC}"

cat > "$MONITORING_DIR/docker-compose.monitoring.yml" << EOF
version: '3.8'

networks:
  solarnexus-network:
    external: true
    name: project_solarnexus-network

services:
  prometheus:
    image: prom/prometheus:latest
    container_name: solarnexus-prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--storage.tsdb.retention.time=200h'
      - '--web.enable-lifecycle'
    restart: unless-stopped
    ports:
      - "9090:9090"
    volumes:
      - $MONITORING_DIR/prometheus:/etc/prometheus
      - prometheus_data:/prometheus
    networks:
      - solarnexus-network
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.prometheus.rule=Host(\`prometheus.nexus.gonxt.tech\`)"

  alertmanager:
    image: prom/alertmanager:latest
    container_name: solarnexus-alertmanager
    restart: unless-stopped
    ports:
      - "9093:9093"
    volumes:
      - $MONITORING_DIR/alertmanager:/etc/alertmanager
    command:
      - '--config.file=/etc/alertmanager/alertmanager.yml'
      - '--storage.path=/alertmanager'
      - '--web.external-url=http://localhost:9093'
    networks:
      - solarnexus-network

  grafana:
    image: grafana/grafana:latest
    container_name: solarnexus-grafana
    restart: unless-stopped
    ports:
      - "3001:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=$GRAFANA_PASSWORD
      - GF_USERS_ALLOW_SIGN_UP=false
      - GF_INSTALL_PLUGINS=grafana-clock-panel,grafana-simple-json-datasource
    volumes:
      - grafana_data:/var/lib/grafana
      - $MONITORING_DIR/grafana/provisioning:/etc/grafana/provisioning
      - $MONITORING_DIR/grafana/dashboards:/var/lib/grafana/dashboards
    networks:
      - solarnexus-network
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.grafana.rule=Host(\`grafana.nexus.gonxt.tech\`)"

  node-exporter:
    image: prom/node-exporter:latest
    container_name: solarnexus-node-exporter
    restart: unless-stopped
    ports:
      - "9100:9100"
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    command:
      - '--path.procfs=/host/proc'
      - '--path.rootfs=/rootfs'
      - '--path.sysfs=/host/sys'
      - '--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)'
    networks:
      - solarnexus-network

  postgres-exporter:
    image: prometheuscommunity/postgres-exporter:latest
    container_name: solarnexus-postgres-exporter
    restart: unless-stopped
    ports:
      - "9187:9187"
    environment:
      - DATA_SOURCE_NAME=postgresql://solarnexus:solarnexus@solarnexus-postgres:5432/solarnexus?sslmode=disable
    networks:
      - solarnexus-network

  redis-exporter:
    image: oliver006/redis_exporter:latest
    container_name: solarnexus-redis-exporter
    restart: unless-stopped
    ports:
      - "9121:9121"
    environment:
      - REDIS_ADDR=redis://solarnexus-redis:6379
    networks:
      - solarnexus-network

volumes:
  prometheus_data:
  grafana_data:
EOF

# Create monitoring startup script
echo -e "${BLUE}🚀 Creating monitoring startup script...${NC}"

cat > "$MONITORING_DIR/start-monitoring.sh" << EOF
#!/bin/bash
# Start SolarNexus monitoring stack

cd $MONITORING_DIR

echo "🚀 Starting SolarNexus monitoring stack..."

# Start monitoring services
docker-compose -f docker-compose.monitoring.yml up -d

echo "⏳ Waiting for services to start..."
sleep 30

# Check service status
echo "📊 Monitoring services status:"
docker-compose -f docker-compose.monitoring.yml ps

echo "🌐 Access URLs:"
echo "  • Prometheus: http://localhost:9090"
echo "  • Grafana: http://localhost:3001 (admin/$GRAFANA_PASSWORD)"
echo "  • Alertmanager: http://localhost:9093"

echo "✅ Monitoring stack is ready!"
EOF

chmod +x "$MONITORING_DIR/start-monitoring.sh"

# Create monitoring health check script
cat > "$MONITORING_DIR/health-check.sh" << 'EOF'
#!/bin/bash
# SolarNexus monitoring health check

echo "🏥 SolarNexus Health Check Report"
echo "================================="

# Check core services
echo "📊 Core Services:"
services=("solarnexus-backend" "solarnexus-frontend" "solarnexus-postgres" "solarnexus-redis" "solarnexus-nginx")

for service in "${services[@]}"; do
    if docker ps --format "table {{.Names}}" | grep -q "$service"; then
        status="✅ Running"
    else
        status="❌ Down"
    fi
    printf "  %-20s %s\n" "$service" "$status"
done

# Check monitoring services
echo -e "\n📈 Monitoring Services:"
monitoring_services=("solarnexus-prometheus" "solarnexus-grafana" "solarnexus-alertmanager")

for service in "${monitoring_services[@]}"; do
    if docker ps --format "table {{.Names}}" | grep -q "$service"; then
        status="✅ Running"
    else
        status="❌ Down"
    fi
    printf "  %-25s %s\n" "$service" "$status"
done

# Check endpoints
echo -e "\n🌐 Endpoint Health:"
endpoints=(
    "Backend:http://localhost:3000/health"
    "Frontend:http://localhost:8080/health"
    "Prometheus:http://localhost:9090/-/healthy"
    "Grafana:http://localhost:3001/api/health"
)

for endpoint in "${endpoints[@]}"; do
    name="${endpoint%%:*}"
    url="${endpoint#*:}"
    
    if curl -s -f "$url" > /dev/null 2>&1; then
        status="✅ Healthy"
    else
        status="❌ Unhealthy"
    fi
    printf "  %-15s %s\n" "$name" "$status"
done

# System resources
echo -e "\n💻 System Resources:"
echo "  CPU Usage: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)%"
echo "  Memory Usage: $(free | grep Mem | awk '{printf("%.1f%%", $3/$2 * 100.0)}')"
echo "  Disk Usage: $(df -h / | awk 'NR==2{printf "%s", $5}')"

echo -e "\n📅 Report generated: $(date)"
EOF

chmod +x "$MONITORING_DIR/health-check.sh"

# Create systemd service for monitoring
echo -e "${BLUE}⚙️  Creating systemd service...${NC}"

cat > /etc/systemd/system/solarnexus-monitoring.service << EOF
[Unit]
Description=SolarNexus Monitoring Stack
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=$MONITORING_DIR
ExecStart=$MONITORING_DIR/start-monitoring.sh
ExecStop=/usr/bin/docker-compose -f $MONITORING_DIR/docker-compose.monitoring.yml down

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable solarnexus-monitoring.service

# Set up log rotation
echo -e "${BLUE}📝 Setting up log rotation...${NC}"

cat > /etc/logrotate.d/solarnexus << 'EOF'
/var/lib/docker/containers/*/*-json.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 644 root root
    postrotate
        docker kill --signal="USR1" $(docker ps -q) 2>/dev/null || true
    endscript
}
EOF

# Create monitoring summary
echo -e "\n${GREEN}✅ Monitoring Setup Complete!${NC}"
echo -e "${BLUE}📋 Summary:${NC}"
echo "   • Monitoring directory: $MONITORING_DIR"
echo "   • Grafana admin password: $GRAFANA_PASSWORD"
echo "   • Startup script: $MONITORING_DIR/start-monitoring.sh"
echo "   • Health check: $MONITORING_DIR/health-check.sh"

echo -e "\n${BLUE}🚀 Start monitoring stack:${NC}"
echo "   sudo systemctl start solarnexus-monitoring"
echo "   # OR"
echo "   sudo $MONITORING_DIR/start-monitoring.sh"

echo -e "\n${BLUE}🌐 Access URLs (after starting):${NC}"
echo "   • Prometheus: http://localhost:9090"
echo "   • Grafana: http://localhost:3001 (admin/$GRAFANA_PASSWORD)"
echo "   • Alertmanager: http://localhost:9093"

echo -e "\n${BLUE}📊 Monitoring Features:${NC}"
echo "   • Service availability monitoring"
echo "   • System resource tracking (CPU, Memory, Disk)"
echo "   • API performance metrics"
echo "   • Database connection monitoring"
echo "   • Solar data sync monitoring"
echo "   • Email alerts for critical issues"
echo "   • Custom SolarNexus dashboard"

echo -e "\n${YELLOW}⚠️  Next Steps:${NC}"
echo "   1. Update email credentials in alertmanager.yml"
echo "   2. Start the monitoring stack"
echo "   3. Access Grafana and customize dashboards"
echo "   4. Test alerting by stopping a service"
echo "   5. Set up external monitoring (optional)"

echo -e "\n${GREEN}🎉 Production monitoring is ready!${NC}"