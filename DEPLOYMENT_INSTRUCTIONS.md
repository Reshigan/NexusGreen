# 🚀 NexusGreen Deployment Instructions

## Quick Deployment to Your Server

Your amazing new NexusGreen system is ready for deployment! Here's how to get it running on your server at **13.247.192.38**.

### Option 1: Automated Deployment (Recommended)

```bash
# SSH into your server
ssh ubuntu@13.247.192.38

# Navigate to your deployment directory
cd /home/ubuntu

# Remove old deployment if exists
rm -rf NexusGreen

# Clone the latest version
git clone https://github.com/Reshigan/NexusGreen.git
cd NexusGreen

# Run the automated deployment script
chmod +x server-deploy.sh
./server-deploy.sh
```

### Option 2: Manual Deployment

```bash
# SSH into your server
ssh ubuntu@13.247.192.38

# Update system
sudo apt update && sudo apt upgrade -y

# Install Node.js 20 (if not already installed)
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Clone the repository
cd /home/ubuntu
git clone https://github.com/Reshigan/NexusGreen.git
cd NexusGreen

# Install dependencies
npm install

# Build the application
npm run build

# Install PM2 for process management
sudo npm install -g pm2

# Start the application
pm2 start npm --name "nexusgreen" -- run preview -- --host 0.0.0.0 --port 3000

# Save PM2 configuration
pm2 save
pm2 startup

# Configure Nginx (if not already configured)
sudo nano /etc/nginx/sites-available/nexusgreen

# Add this configuration:
server {
    listen 80;
    server_name nexus.gonxt.tech 13.247.192.38;
    
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}

# Enable the site
sudo ln -s /etc/nginx/sites-available/nexusgreen /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

## 🎯 What You'll Get

### Amazing Login Experience
- **URL**: http://nexus.gonxt.tech or http://13.247.192.38
- **Demo Accounts**:
  - Super Admin: `admin@gonxt.tech` / `Demo2024!`
  - Manager: `manager@gonxt.tech` / `Demo2024!`
  - Operator: `operator@gonxt.tech` / `Demo2024!`
  - Viewer: `demo@nexusgreen.com` / `Demo2024!`

### Features You'll See
1. **Glassmorphism Login**: Beautiful glass-effect login screen with animations
2. **Real-time Dashboard**: Live updating solar energy metrics
3. **Interactive Charts**: Professional charts showing energy flow and performance
4. **Multi-site Management**: Overview of multiple solar installations
5. **Financial Analytics**: Revenue tracking and ROI calculations
6. **Environmental Impact**: CO₂ savings and sustainability metrics
7. **Alert System**: Real-time alerts and notifications
8. **Responsive Design**: Perfect on desktop, tablet, and mobile

## 🔧 Troubleshooting

### If the build fails:
```bash
# Clear npm cache
npm cache clean --force

# Delete node_modules and reinstall
rm -rf node_modules package-lock.json
npm install

# Try building again
npm run build
```

### If the application won't start:
```bash
# Check PM2 status
pm2 status

# View logs
pm2 logs nexusgreen

# Restart the application
pm2 restart nexusgreen
```

### If Nginx isn't working:
```bash
# Check Nginx status
sudo systemctl status nginx

# Check configuration
sudo nginx -t

# Restart Nginx
sudo systemctl restart nginx
```

## 📊 Performance Optimization

### For Production Use:
```bash
# Enable Nginx gzip compression
sudo nano /etc/nginx/nginx.conf

# Add to http block:
gzip on;
gzip_vary on;
gzip_min_length 1024;
gzip_proxied expired no-cache no-store private must-revalidate auth;
gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;

# Restart Nginx
sudo systemctl restart nginx
```

### SSL Certificate (Optional):
```bash
# Install Certbot
sudo apt install certbot python3-certbot-nginx

# Get SSL certificate
sudo certbot --nginx -d nexus.gonxt.tech

# Auto-renewal
sudo crontab -e
# Add: 0 12 * * * /usr/bin/certbot renew --quiet
```

## 🎨 Customization Options

### Branding:
- Update logo in `src/components/auth/ModernLogin.tsx`
- Modify colors in `src/styles/nexusTheme.ts`
- Change organization data in `src/data/nexusGreenData.ts`

### Data:
- Add your real sites in `src/data/nexusGreenData.ts`
- Integrate with your actual APIs in `src/services/api.ts`
- Customize metrics in dashboard components

## 🚀 Going Live Checklist

- [ ] Application builds successfully
- [ ] PM2 process is running
- [ ] Nginx is configured and running
- [ ] Domain points to your server
- [ ] SSL certificate is installed (optional)
- [ ] Demo accounts work correctly
- [ ] Dashboard loads with data
- [ ] Charts and animations work
- [ ] Mobile responsive design works
- [ ] All features are accessible

## 📱 Mobile Testing

Test on various devices:
- **iPhone**: Safari and Chrome
- **Android**: Chrome and Samsung Browser
- **Tablet**: iPad and Android tablets
- **Desktop**: Chrome, Firefox, Safari, Edge

## 🎯 Success Metrics

Your deployment is successful when:
1. ✅ Login page loads with beautiful glassmorphism effects
2. ✅ Demo accounts authenticate successfully
3. ✅ Dashboard shows real-time metrics and charts
4. ✅ Animations and transitions are smooth
5. ✅ Mobile responsive design works perfectly
6. ✅ All interactive elements respond correctly

## 🆘 Support

If you encounter any issues:
1. Check the browser console for errors
2. Review PM2 logs: `pm2 logs nexusgreen`
3. Check Nginx logs: `sudo tail -f /var/log/nginx/error.log`
4. Verify all dependencies are installed
5. Ensure ports 80/443 are open in firewall

## 🎉 Congratulations!

You now have a **world-class solar energy management platform** running on your server! The NexusGreen system provides:

- **Professional Interface**: Enterprise-grade design and user experience
- **Real-time Analytics**: Live monitoring and performance tracking
- **Multi-tenant Support**: Multiple organizations and user roles
- **Modern Technology**: Built with latest React, TypeScript, and design patterns
- **Scalable Architecture**: Ready for production use and future enhancements

**Your solar energy management platform is now live and ready to impress your clients and stakeholders!** 🌟

---

*For additional support or customization requests, the codebase is well-documented and modular for easy modifications.*