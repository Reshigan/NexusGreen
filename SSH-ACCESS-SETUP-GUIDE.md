# 🔑 NexusGreen SSH Access Setup Guide

This guide helps you set up secure SSH access for direct remote production deployment assistance.

## 🚀 Quick Setup (3 minutes)

### On your AWS Ubuntu server:

```bash
# 1. Navigate to your NexusGreen directory
cd ~/NexusGreen

# 2. Pull the latest scripts
git pull origin main

# 3. Run the SSH access setup script
sudo ./setup-ssh-access.sh
```

## 🔑 What You'll Get

After running the script, you'll receive:

- **🔐 SSH Key Pair**: Secure key-based authentication
- **📋 Connection Info**: Complete access details in `~/nexus-ssh-access-info.txt`
- **🛡️ Security Features**: Fail2ban, firewall, and secure SSH config
- **📞 Multiple Access Methods**: Key-based, password, or AWS key pair

## 🛡️ Security Features

- ✅ **Key-Based Authentication**: More secure than passwords
- ✅ **Fail2ban Protection**: Blocks brute force attacks
- ✅ **Firewall Configured**: Only necessary ports opened
- ✅ **SSH Hardening**: Secure SSH server configuration
- ✅ **Easy Revocation**: One command to remove access

## 🔧 Access Methods

### Method 1: SSH Key (Most Secure)
```bash
# Copy private key from server to your local machine
# Set permissions: chmod 600 nexus-support-key
ssh -i nexus-support-key ubuntu@YOUR-SERVER-IP
```

### Method 2: Password Authentication
```bash
ssh ubuntu@YOUR-SERVER-IP
# Enter password when prompted
```

### Method 3: AWS EC2 Key Pair
```bash
ssh -i your-aws-key.pem ubuntu@YOUR-SERVER-IP
```

## 📱 SSH Configuration for Easy Access

Add to your local `~/.ssh/config`:

```bash
Host nexus-production
    HostName YOUR-SERVER-IP
    User ubuntu
    IdentityFile ~/.ssh/nexus-support-key
    Port 22
    ServerAliveInterval 60
```

Then connect with: `ssh nexus-production`

## 🎯 What Remote Support Can Do

With SSH access, remote support can:

- ✅ Run the `ultimate-clean-install.sh` script directly
- ✅ Debug Docker and container issues in real-time
- ✅ Fix SSL certificate problems with certbot
- ✅ Monitor application logs with `docker-compose logs -f`
- ✅ Troubleshoot API and frontend issues
- ✅ Configure Nginx and reverse proxy settings
- ✅ Check system resources and performance
- ✅ Access all system administration tools

## 🔒 Security Best Practices

### During Support:
- Monitor SSH access logs: `sudo tail -f /var/log/auth.log`
- Keep the private key secure and encrypted
- Only share access with trusted support personnel
- Monitor system activity during support session

### After Support:
```bash
# Immediately revoke SSH access
sudo ./disable-ssh-access.sh
```

## 📋 Troubleshooting

### If SSH connection fails:

```bash
# Check SSH service status
sudo systemctl status sshd

# Check firewall rules
sudo ufw status

# Check if SSH port is listening
sudo netstat -tlnp | grep :22

# Test SSH configuration
sudo sshd -t

# Restart SSH service
sudo systemctl restart sshd
```

### Debug connection issues:
```bash
# Verbose SSH connection for debugging
ssh -vvv ubuntu@YOUR-SERVER-IP
```

### Check fail2ban status:
```bash
# View fail2ban status
sudo fail2ban-client status sshd

# Unban an IP if needed
sudo fail2ban-client set sshd unbanip IP-ADDRESS
```

## 🚨 Emergency Access Recovery

If you get locked out:

1. **AWS Console**: Use EC2 Instance Connect or Session Manager
2. **AWS Key Pair**: Use your original AWS key pair
3. **Console Access**: Use AWS EC2 console's "Connect" feature

## 📞 Support Workflow

1. **Setup**: Run `sudo ./setup-ssh-access.sh`
2. **Share**: Provide SSH connection details to support
3. **Connect**: Support connects via SSH using provided methods
4. **Deploy**: Run deployment scripts and troubleshoot issues
5. **Monitor**: Watch the deployment process in real-time
6. **Verify**: Test your NexusGreen application
7. **Secure**: Run `sudo ./disable-ssh-access.sh`

## 🎉 Expected Results

After setup, remote support can:

- Connect directly to your server via SSH
- Run deployment scripts with full system access
- Fix Docker multi-platform build errors
- Resolve SSL certificate configuration issues
- Debug API startup and health check problems
- Fix frontend rendering issues
- Monitor real-time application and system logs
- Configure and optimize server performance

## 📁 Files Created

- `setup-ssh-access.sh` - Main SSH setup script
- `disable-ssh-access.sh` - Security cleanup script
- `~/nexus-ssh-access-info.txt` - Your complete access information
- `~/.ssh/nexus-support-key` - Private key for remote access
- `~/.ssh/nexus-support-key.pub` - Public key (added to authorized_keys)

## 🔐 Key Management

### Private Key Location:
```
~/.ssh/nexus-support-key
```

### Public Key Location:
```
~/.ssh/nexus-support-key.pub
```

### Authorized Keys:
```
~/.ssh/authorized_keys (contains the public key)
```

## 🛡️ Security Cleanup

After support is complete:

```bash
# Run the disable script
sudo ./disable-ssh-access.sh

# Options available:
# - Remove support SSH keys
# - Restore original SSH configuration
# - Disable password authentication
# - Remove access information files
# - Maintain fail2ban protection
```

---

**🔐 Remember**: SSH access provides full system control. Always revoke access after support is complete!