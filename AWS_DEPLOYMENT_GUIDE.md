# 🚀 NexusGreen AWS Deployment Guide

## 📋 Overview

This guide provides comprehensive instructions for deploying your NexusGreen multi-tenant solar energy management dashboard to AWS using multiple deployment strategies.

## 🏗️ AWS Deployment Options

### Option 1: EC2 with Docker (Recommended for Full Control)
### Option 2: ECS with Fargate (Managed Containers)
### Option 3: Elastic Beanstalk (Simplest Deployment)
### Option 4: EKS (Kubernetes - Enterprise Scale)

---

## 🎯 Option 1: EC2 with Docker Deployment (Recommended)

### Prerequisites
- AWS Account with appropriate permissions
- Domain name (e.g., nexus.yourdomain.com)
- SSH key pair for EC2 access

### Step 1: Launch EC2 Instance

```bash
# Launch Ubuntu 22.04 LTS instance
# Recommended: t3.medium or larger (2 vCPU, 4GB RAM)
# Storage: 20GB+ SSD
# Security Group: Allow ports 22, 80, 443
```

### Step 2: Connect and Setup Server

```bash
# Connect to your EC2 instance
ssh -i your-key.pem ubuntu@your-ec2-ip

# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker and Docker Compose
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker ubuntu
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Install additional tools
sudo apt install -y git nginx certbot python3-certbot-nginx ufw

# Configure firewall
sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow https
sudo ufw --force enable
```

### Step 3: Clone and Deploy Application

```bash
# Clone your repository
git clone https://github.com/Reshigan/NexusGreen.git
cd NexusGreen

# Create AWS-specific environment file
cat > .env.production << EOF
# Database Configuration
DATABASE_URL=postgresql://nexususer:$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)@nexus-db:5432/nexusgreen
POSTGRES_DB=nexusgreen
POSTGRES_USER=nexususer
POSTGRES_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)

# JWT Configuration
JWT_SECRET=$(openssl rand -base64 64 | tr -d "=+/" | cut -c1-50)

# Application Configuration
NODE_ENV=production
VITE_ENVIRONMENT=production
VITE_API_URL=https://nexus.yourdomain.com/api
CORS_ORIGIN=https://nexus.yourdomain.com

# Company Configuration
VITE_COMPANY_NAME=Your Company Name
VITE_COMPANY_REG=Your Registration Number
VITE_PPA_RATE=1.20

# Monitoring
SOLAX_SYNC_INTERVAL_MINUTES=60
EOF

# Make deployment script executable
chmod +x production-deploy.sh

# Run deployment (modify domain in script first)
sudo ./production-deploy.sh
```

### Step 4: Configure Domain and SSL

```bash
# Point your domain to EC2 public IP in DNS settings
# Then run SSL setup
sudo certbot --nginx -d nexus.yourdomain.com --email your-email@domain.com --agree-tos --non-interactive
```

---

## 🎯 Option 2: ECS with Fargate Deployment

### Step 1: Create ECS Infrastructure

```bash
# Create ECS cluster
aws ecs create-cluster --cluster-name nexusgreen-cluster

# Create task definition
cat > nexusgreen-task-definition.json << EOF
{
  "family": "nexusgreen",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "1024",
  "memory": "2048",
  "executionRoleArn": "arn:aws:iam::YOUR-ACCOUNT:role/ecsTaskExecutionRole",
  "containerDefinitions": [
    {
      "name": "nexusgreen-frontend",
      "image": "YOUR-ACCOUNT.dkr.ecr.YOUR-REGION.amazonaws.com/nexusgreen:latest",
      "portMappings": [
        {
          "containerPort": 80,
          "protocol": "tcp"
        }
      ],
      "environment": [
        {"name": "VITE_API_URL", "value": "https://nexus.yourdomain.com/api"},
        {"name": "VITE_ENVIRONMENT", "value": "production"}
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/nexusgreen",
          "awslogs-region": "YOUR-REGION",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ]
}
EOF

# Register task definition
aws ecs register-task-definition --cli-input-json file://nexusgreen-task-definition.json
```

### Step 2: Create ECS Service with Load Balancer

```bash
# Create Application Load Balancer
aws elbv2 create-load-balancer \
  --name nexusgreen-alb \
  --subnets subnet-12345 subnet-67890 \
  --security-groups sg-12345

# Create target group
aws elbv2 create-target-group \
  --name nexusgreen-targets \
  --protocol HTTP \
  --port 80 \
  --vpc-id vpc-12345 \
  --target-type ip \
  --health-check-path /health

# Create ECS service
aws ecs create-service \
  --cluster nexusgreen-cluster \
  --service-name nexusgreen-service \
  --task-definition nexusgreen:1 \
  --desired-count 2 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-12345,subnet-67890],securityGroups=[sg-12345],assignPublicIp=ENABLED}" \
  --load-balancers targetGroupArn=arn:aws:elasticloadbalancing:region:account:targetgroup/nexusgreen-targets/1234567890123456,containerName=nexusgreen-frontend,containerPort=80
```

---

## 🎯 Option 3: Elastic Beanstalk Deployment (Simplest)

### Step 1: Prepare Application

```bash
# Create Dockerrun.aws.json for multi-container deployment
cat > Dockerrun.aws.json << EOF
{
  "AWSEBDockerrunVersion": 2,
  "containerDefinitions": [
    {
      "name": "nexusgreen-frontend",
      "image": "nexusgreen:latest",
      "hostname": "frontend",
      "essential": true,
      "memory": 512,
      "portMappings": [
        {
          "hostPort": 80,
          "containerPort": 80
        }
      ],
      "environment": [
        {
          "name": "VITE_API_URL",
          "value": "https://nexus.yourdomain.com/api"
        },
        {
          "name": "VITE_ENVIRONMENT",
          "value": "production"
        }
      ]
    },
    {
      "name": "nexusgreen-api",
      "image": "nexusgreen-api:latest",
      "hostname": "api",
      "essential": true,
      "memory": 512,
      "portMappings": [
        {
          "hostPort": 3001,
          "containerPort": 3001
        }
      ],
      "environment": [
        {
          "name": "NODE_ENV",
          "value": "production"
        },
        {
          "name": "DATABASE_URL",
          "value": "postgresql://username:password@your-rds-endpoint:5432/nexusgreen"
        }
      ]
    }
  ]
}
EOF

# Create application zip
zip -r nexusgreen-app.zip . -x "node_modules/*" ".git/*" "*.log"
```

### Step 2: Deploy to Elastic Beanstalk

```bash
# Install EB CLI
pip install awsebcli

# Initialize EB application
eb init nexusgreen --region us-east-1 --platform "Multi-container Docker"

# Create environment
eb create nexusgreen-prod --instance-type t3.medium --min-instances 1 --max-instances 3

# Deploy application
eb deploy
```

---

## 🎯 Option 4: EKS Kubernetes Deployment

### Step 1: Create EKS Cluster

```bash
# Install eksctl
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin

# Create EKS cluster
eksctl create cluster \
  --name nexusgreen-cluster \
  --region us-east-1 \
  --nodegroup-name nexusgreen-nodes \
  --node-type t3.medium \
  --nodes 2 \
  --nodes-min 1 \
  --nodes-max 4 \
  --managed
```

### Step 2: Deploy Application to Kubernetes

```yaml
# Create nexusgreen-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nexusgreen-frontend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nexusgreen-frontend
  template:
    metadata:
      labels:
        app: nexusgreen-frontend
    spec:
      containers:
      - name: frontend
        image: YOUR-ACCOUNT.dkr.ecr.YOUR-REGION.amazonaws.com/nexusgreen:latest
        ports:
        - containerPort: 80
        env:
        - name: VITE_API_URL
          value: "https://nexus.yourdomain.com/api"
        - name: VITE_ENVIRONMENT
          value: "production"
---
apiVersion: v1
kind: Service
metadata:
  name: nexusgreen-service
spec:
  selector:
    app: nexusgreen-frontend
  ports:
  - port: 80
    targetPort: 80
  type: LoadBalancer
```

```bash
# Deploy to Kubernetes
kubectl apply -f nexusgreen-deployment.yaml

# Get load balancer URL
kubectl get services nexusgreen-service
```

---

## 🗄️ Database Options

### Option A: RDS PostgreSQL (Recommended)

```bash
# Create RDS instance
aws rds create-db-instance \
  --db-instance-identifier nexusgreen-db \
  --db-instance-class db.t3.micro \
  --engine postgres \
  --engine-version 15.4 \
  --master-username nexususer \
  --master-user-password YourSecurePassword123! \
  --allocated-storage 20 \
  --storage-type gp2 \
  --vpc-security-group-ids sg-12345 \
  --db-subnet-group-name your-db-subnet-group \
  --backup-retention-period 7 \
  --multi-az \
  --storage-encrypted
```

### Option B: Aurora Serverless (Cost-Effective)

```bash
# Create Aurora Serverless cluster
aws rds create-db-cluster \
  --db-cluster-identifier nexusgreen-aurora \
  --engine aurora-postgresql \
  --engine-mode serverless \
  --master-username nexususer \
  --master-user-password YourSecurePassword123! \
  --scaling-configuration MinCapacity=2,MaxCapacity=16,AutoPause=true,SecondsUntilAutoPause=300
```

---

## 🔒 Security Best Practices

### 1. IAM Roles and Policies

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*"
    }
  ]
}
```

### 2. Security Groups

```bash
# Web tier security group
aws ec2 create-security-group \
  --group-name nexusgreen-web \
  --description "NexusGreen Web Tier" \
  --vpc-id vpc-12345

# Allow HTTP/HTTPS from anywhere
aws ec2 authorize-security-group-ingress \
  --group-id sg-web123 \
  --protocol tcp \
  --port 80 \
  --cidr 0.0.0.0/0

aws ec2 authorize-security-group-ingress \
  --group-id sg-web123 \
  --protocol tcp \
  --port 443 \
  --cidr 0.0.0.0/0

# Database security group
aws ec2 create-security-group \
  --group-name nexusgreen-db \
  --description "NexusGreen Database Tier" \
  --vpc-id vpc-12345

# Allow PostgreSQL from web tier only
aws ec2 authorize-security-group-ingress \
  --group-id sg-db123 \
  --protocol tcp \
  --port 5432 \
  --source-group sg-web123
```

### 3. SSL/TLS Configuration

```bash
# Request SSL certificate from ACM
aws acm request-certificate \
  --domain-name nexus.yourdomain.com \
  --subject-alternative-names "*.yourdomain.com" \
  --validation-method DNS \
  --region us-east-1
```

---

## 📊 Monitoring and Logging

### CloudWatch Setup

```bash
# Create log group
aws logs create-log-group --log-group-name /aws/ecs/nexusgreen

# Create CloudWatch dashboard
cat > dashboard.json << EOF
{
  "widgets": [
    {
      "type": "metric",
      "properties": {
        "metrics": [
          ["AWS/ECS", "CPUUtilization", "ServiceName", "nexusgreen-service"],
          [".", "MemoryUtilization", ".", "."]
        ],
        "period": 300,
        "stat": "Average",
        "region": "us-east-1",
        "title": "ECS Service Metrics"
      }
    }
  ]
}
EOF

aws cloudwatch put-dashboard \
  --dashboard-name "NexusGreen" \
  --dashboard-body file://dashboard.json
```

---

## 🚀 Automated Deployment Scripts

### Complete EC2 Deployment Script

```bash
#!/bin/bash
# aws-deploy.sh - Complete AWS EC2 deployment script

set -e

# Configuration
DOMAIN="nexus.yourdomain.com"
EMAIL="your-email@domain.com"
REGION="us-east-1"
INSTANCE_TYPE="t3.medium"

echo "🚀 Starting NexusGreen AWS Deployment..."

# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker ubuntu

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Install additional tools
sudo apt install -y git nginx certbot python3-certbot-nginx ufw

# Configure firewall
sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow https
sudo ufw --force enable

# Clone repository
git clone https://github.com/Reshigan/NexusGreen.git
cd NexusGreen

# Generate secure passwords
DB_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
JWT_SECRET=$(openssl rand -base64 64 | tr -d "=+/" | cut -c1-50)

# Create production environment
cat > .env.production << EOF
DATABASE_URL=postgresql://nexususer:${DB_PASSWORD}@nexus-db:5432/nexusgreen
POSTGRES_DB=nexusgreen
POSTGRES_USER=nexususer
POSTGRES_PASSWORD=${DB_PASSWORD}
JWT_SECRET=${JWT_SECRET}
NODE_ENV=production
VITE_ENVIRONMENT=production
VITE_API_URL=https://${DOMAIN}/api
CORS_ORIGIN=https://${DOMAIN}
VITE_COMPANY_NAME=Your Company Name
VITE_COMPANY_REG=Your Registration Number
VITE_PPA_RATE=1.20
SOLAX_SYNC_INTERVAL_MINUTES=60
EOF

# Update docker-compose for production
sed -i "s/nexus.gonxt.tech/${DOMAIN}/g" docker-compose.yml

# Start services
sudo docker-compose up -d

# Wait for services to be ready
echo "⏳ Waiting for services to start..."
sleep 30

# Setup SSL certificate
sudo certbot --nginx -d ${DOMAIN} --email ${EMAIL} --agree-tos --non-interactive

# Setup auto-renewal
echo "0 12 * * * /usr/bin/certbot renew --quiet" | sudo crontab -

echo "✅ Deployment completed successfully!"
echo "🌐 Your application is available at: https://${DOMAIN}"
echo "👤 Demo credentials:"
echo "   Admin: admin@gonxt.tech / Demo2024!"
echo "   User: user@gonxt.tech / Demo2024!"
```

### Make it executable and run:

```bash
chmod +x aws-deploy.sh
sudo ./aws-deploy.sh
```

---

## 💰 Cost Optimization

### 1. EC2 Instance Sizing
- **Development**: t3.micro ($8/month)
- **Production**: t3.medium ($30/month)
- **High Traffic**: t3.large ($60/month)

### 2. RDS Optimization
- Use Aurora Serverless for variable workloads
- Enable automated backups with 7-day retention
- Use read replicas for read-heavy workloads

### 3. CloudFront CDN
```bash
# Create CloudFront distribution for static assets
aws cloudfront create-distribution \
  --distribution-config file://cloudfront-config.json
```

---

## 🔧 Troubleshooting

### Common Issues and Solutions

1. **SSL Certificate Issues**
   ```bash
   # Check certificate status
   sudo certbot certificates
   
   # Renew certificate manually
   sudo certbot renew --force-renewal
   ```

2. **Docker Container Issues**
   ```bash
   # Check container logs
   sudo docker-compose logs -f
   
   # Restart services
   sudo docker-compose restart
   ```

3. **Database Connection Issues**
   ```bash
   # Test database connection
   sudo docker-compose exec nexus-db psql -U nexususer -d nexusgreen
   ```

---

## 📞 Support and Maintenance

### Regular Maintenance Tasks

```bash
# Weekly maintenance script
#!/bin/bash
# maintenance.sh

# Update system packages
sudo apt update && sudo apt upgrade -y

# Update Docker images
cd ~/NexusGreen
sudo docker-compose pull
sudo docker-compose up -d

# Clean up old Docker images
sudo docker system prune -f

# Backup database
sudo docker-compose exec nexus-db pg_dump -U nexususer nexusgreen > backup_$(date +%Y%m%d).sql

# Check SSL certificate expiry
sudo certbot certificates
```

---

## 🎉 Deployment Complete!

Your NexusGreen application is now successfully deployed on AWS with:

✅ **High Availability** - Load balanced across multiple instances  
✅ **Security** - SSL certificates and security groups  
✅ **Scalability** - Auto-scaling based on demand  
✅ **Monitoring** - CloudWatch metrics and logging  
✅ **Backup** - Automated database backups  
✅ **Cost Optimization** - Right-sized resources  

**Your application is now live and ready for production use!** 🚀

---

*Deployment Guide Version: 1.0*  
*Last Updated: $(date)*  
*Status: Production Ready*