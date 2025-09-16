# 🌐 NexusGreen Web Access Setup Guide

This guide helps you set up secure web access for remote production deployment assistance.

## 🚀 Quick Setup (5 minutes)

### On your AWS Ubuntu server:

```bash
# 1. Navigate to your NexusGreen directory
cd ~/NexusGreen

# 2. Pull the latest scripts
git pull origin main

# 3. Run the web access setup script
sudo ./setup-web-access.sh
```

## 🔑 What You'll Get

After running the script, you'll receive:

- **🌐 Web Terminal URL**: Direct browser access to your server
- **🔒 Secure Credentials**: Username and password for access
- **📋 Full Access Info**: Saved to `~/nexus-web-access-info.txt`

## 🛡️ Security Features

- ✅ **Password Protected**: Secure authentication required
- ✅ **Firewall Configured**: Only necessary ports opened
- ✅ **Session Timeout**: Automatic logout after inactivity
- ✅ **Root Access**: For deployment and troubleshooting
- ✅ **Easy Disable**: One command to remove access

## 📱 How It Works

1. **ttyd Web Terminal**: Browser-based terminal access
2. **Nginx Reverse Proxy**: Professional web interface
3. **Systemd Service**: Reliable service management
4. **UFW Firewall**: Secure port management

## 🔧 Access Methods

### Direct Access:
```
http://YOUR-SERVER-IP:7681
```

### Via Nginx (Recommended):
```
http://YOUR-SERVER-IP/terminal
```

## 🎯 What Remote Support Can Do

With web access, remote support can:

- ✅ Run the `ultimate-clean-install.sh` script
- ✅ Debug Docker and container issues
- ✅ Fix SSL certificate problems
- ✅ Monitor application logs in real-time
- ✅ Troubleshoot API and frontend issues
- ✅ Configure Nginx and reverse proxy
- ✅ Check system resources and performance

## 🔒 Security Best Practices

### During Support:
- Monitor the session for security
- Keep the credentials private
- Only share with trusted support personnel

### After Support:
```bash
# Disable web access immediately after support
sudo ./disable-web-access.sh
```

## 📋 Troubleshooting

### If web access doesn't work:

```bash
# Check service status
sudo systemctl status nexus-web-access

# Check firewall
sudo ufw status

# Check if port is listening
sudo netstat -tlnp | grep 7681

# Restart service
sudo systemctl restart nexus-web-access
```

### View logs:
```bash
sudo journalctl -u nexus-web-access -f
```

## 🚨 Emergency Access

If you need to quickly disable access:

```bash
# Stop the service immediately
sudo systemctl stop nexus-web-access

# Block the port
sudo ufw delete allow 7681
```

## 📞 Support Workflow

1. **Setup**: Run `sudo ./setup-web-access.sh`
2. **Share**: Provide URL and credentials to support
3. **Monitor**: Watch the deployment process
4. **Verify**: Test your NexusGreen application
5. **Secure**: Run `sudo ./disable-web-access.sh`

## 🎉 Expected Results

After setup, remote support can:

- Access your server via web browser
- Run deployment scripts with full privileges
- Fix Docker multi-platform build errors
- Resolve SSL certificate issues
- Debug API and frontend problems
- Monitor real-time application logs

## 📁 Files Created

- `setup-web-access.sh` - Main setup script
- `disable-web-access.sh` - Security cleanup script
- `~/nexus-web-access-info.txt` - Your access credentials
- `/etc/ttyd-credentials` - Secure credentials storage

---

**🔐 Remember**: Always disable web access after support is complete for maximum security!