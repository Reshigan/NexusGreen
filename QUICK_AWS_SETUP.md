# ⚡ Quick AWS Setup Guide for NexusGreen

## 🚀 Option 1: Single EC2 Instance (Recommended for Start)

### Step 1: Launch EC2 Instance
1. **Go to AWS Console** → EC2 → Launch Instance
2. **Choose AMI**: Ubuntu Server 22.04 LTS
3. **Instance Type**: t3.medium (2 vCPU, 4GB RAM) - minimum recommended
4. **Storage**: 20GB GP3 SSD
5. **Security Group**: Create new with these rules:
   - SSH (22) - Your IP only
   - HTTP (80) - Anywhere (0.0.0.0/0)
   - HTTPS (443) - Anywhere (0.0.0.0/0)
6. **Key Pair**: Create new or use existing
7. **Launch Instance**

### Step 2: Connect and Deploy
```bash
# Connect to your instance
ssh -i your-key.pem ubuntu@your-ec2-public-ip

# Download and run deployment script
wget https://raw.githubusercontent.com/Reshigan/NexusGreen/main/aws-deploy.sh
chmod +x aws-deploy.sh

# Edit the script to set your domain and email
nano aws-deploy.sh
# Change these lines:
# DOMAIN="your-domain.com"
# EMAIL="your-email@domain.com"
# COMPANY_NAME="Your Company Name"

# Run deployment
sudo ./aws-deploy.sh
```

### Step 3: Configure DNS
1. **Point your domain** to the EC2 public IP address
2. **Wait 5-30 minutes** for DNS propagation
3. **Access your app** at https://your-domain.com

---

## 🚀 Option 2: Load Balanced Setup (Production)

### Step 1: Create Application Load Balancer
```bash
# Create target group
aws elbv2 create-target-group \
  --name nexusgreen-targets \
  --protocol HTTP \
  --port 80 \
  --vpc-id vpc-xxxxxxxx \
  --health-check-path /health

# Create load balancer
aws elbv2 create-load-balancer \
  --name nexusgreen-alb \
  --subnets subnet-xxxxxxxx subnet-yyyyyyyy \
  --security-groups sg-xxxxxxxx
```

### Step 2: Launch Multiple EC2 Instances
- Launch 2-3 instances using the same process as Option 1
- Register them with the target group
- Use the load balancer DNS name for your domain

---

## 🚀 Option 3: Using AWS Lightsail (Simplest)

### Step 1: Create Lightsail Instance
1. **Go to AWS Lightsail Console**
2. **Create Instance**:
   - Platform: Linux/Unix
   - Blueprint: Ubuntu 22.04 LTS
   - Instance Plan: $20/month (2GB RAM, 1 vCPU)
3. **Add Launch Script**:
```bash
#!/bin/bash
apt update && apt upgrade -y
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
usermod -aG docker ubuntu
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
```

### Step 2: Deploy Application
```bash
# SSH into Lightsail instance
ssh ubuntu@your-lightsail-ip

# Clone and deploy
git clone https://github.com/Reshigan/NexusGreen.git
cd NexusGreen
chmod +x aws-deploy.sh
# Edit domain settings
nano aws-deploy.sh
# Run deployment
sudo ./aws-deploy.sh
```

---

## 🗄️ Database Options

### Option A: Use Built-in PostgreSQL (Included in deployment)
- **Pros**: Simple, included in docker-compose
- **Cons**: Data stored on instance, not highly available
- **Best for**: Development, small deployments

### Option B: Amazon RDS PostgreSQL
```bash
# Create RDS instance
aws rds create-db-instance \
  --db-instance-identifier nexusgreen-db \
  --db-instance-class db.t3.micro \
  --engine postgres \
  --master-username nexususer \
  --master-user-password YourSecurePassword123! \
  --allocated-storage 20 \
  --vpc-security-group-ids sg-xxxxxxxx
```

Then update your `.env.production`:
```bash
DATABASE_URL=postgresql://nexususer:YourSecurePassword123!@your-rds-endpoint:5432/nexusgreen
```

---

## 💰 Cost Estimates

### Single EC2 Instance
- **t3.medium**: ~$30/month
- **20GB Storage**: ~$2/month
- **Data Transfer**: ~$5-10/month
- **Total**: ~$37-42/month

### Load Balanced Setup
- **2x t3.medium**: ~$60/month
- **Application Load Balancer**: ~$16/month
- **Storage & Transfer**: ~$10/month
- **Total**: ~$86/month

### With RDS Database
- **Add db.t3.micro**: ~$13/month
- **20GB RDS Storage**: ~$2/month

---

## 🔧 Quick Commands Reference

### After Deployment
```bash
# Check application status
sudo docker-compose ps

# View logs
sudo docker-compose logs -f

# Restart services
sudo docker-compose restart

# Update application
cd ~/NexusGreen
git pull
sudo docker-compose up -d --build

# Check SSL certificate
sudo certbot certificates

# Backup database
sudo docker-compose exec nexus-db pg_dump -U nexususer nexusgreen > backup.sql
```

### Troubleshooting
```bash
# If services won't start
sudo docker-compose down
sudo docker system prune -f
sudo docker-compose up -d --build

# If SSL fails
sudo certbot --nginx -d your-domain.com --email your-email@domain.com

# Check firewall
sudo ufw status

# Check nginx
sudo nginx -t
sudo systemctl status nginx
```

---

## 🎯 Demo Credentials

After deployment, use these credentials to test:

**Admin User:**
- Email: `admin@gonxt.tech`
- Password: `Demo2024!`

**Regular User:**
- Email: `user@gonxt.tech`
- Password: `Demo2024!`

---

## 📞 Support Checklist

Before asking for help, check:

1. ✅ **DNS**: Does your domain point to the server IP?
2. ✅ **Firewall**: Are ports 80 and 443 open?
3. ✅ **Services**: Are all Docker containers running?
4. ✅ **Logs**: Any errors in `sudo docker-compose logs`?
5. ✅ **SSL**: Is the certificate valid?
6. ✅ **Health**: Does `/health` endpoint respond?

---

## 🎉 Success Indicators

Your deployment is successful when:

✅ All Docker containers show "Up" status  
✅ Application loads at your domain  
✅ SSL certificate is valid (green lock)  
✅ Demo login works  
✅ Dashboard displays solar data  
✅ No errors in application logs  

**Your NexusGreen application is now live on AWS!** 🚀