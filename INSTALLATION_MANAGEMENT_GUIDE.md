# 🛠️ Nexus Green Installation Management Guide

## 📋 Overview

The `manage-installations.sh` script provides comprehensive management of SolarNexus/Nexus Green installations on your system. It can:

- **Scan** for existing installations across the entire system
- **Remove** all existing installations completely
- **Install** fresh Nexus Green v4.0.0 production version
- **Backup** existing installations before changes
- **Clean** system resources and caches

---

## 🚀 Quick Start

### Make Script Executable
```bash
chmod +x manage-installations.sh
```

### Basic Commands

#### 1. Scan for Existing Installations
```bash
./manage-installations.sh scan
```
This will check your entire system for any SolarNexus or Nexus Green installations.

#### 2. Complete Clean Installation (Recommended)
```bash
./manage-installations.sh clean-install
```
This will:
- Scan for existing installations
- Create a backup (optional)
- Remove all existing installations
- Install fresh Nexus Green v4.0.0
- Clean up system resources

#### 3. Remove All Existing Installations
```bash
./manage-installations.sh remove
```
⚠️ **Warning**: This will completely remove all SolarNexus/Nexus Green installations!

#### 4. Install Fresh Copy Only
```bash
./manage-installations.sh install
# Or specify custom path:
./manage-installations.sh install /var/www/nexus-green
```

---

## 🔍 What the Script Checks

### 📁 File System Locations
- `/opt/solarnexus`, `/opt/nexus-green`
- `/var/www/solarnexus`, `/var/www/nexus-green`
- `/home/*/solarnexus`, `/home/*/nexus-green`
- `/usr/local/solarnexus`, `/usr/local/nexus-green`
- User home directories (`~/solarnexus`, `~/nexus-green`)

### 🐳 Docker Resources
- **Containers**: `solarnexus*`, `nexus-green*`
- **Images**: `solarnexus*`, `nexus-green*`
- **Volumes**: Related Docker volumes
- **Networks**: Related Docker networks

### ⚙️ System Services
- **Systemd Services**: `solarnexus.service`, `nexus-green.service`
- **Running Processes**: Any processes containing "solarnexus" or "nexus-green"
- **Network Ports**: Common ports (3000, 8080, 5432, 6379, 80, 443)

### 🌐 Web Server Configurations
- **Nginx**: `/etc/nginx/sites-*/solarnexus*`, `/etc/nginx/sites-*/nexus-green*`
- **SSL Certificates**: `/etc/letsencrypt/live/nexus.gonxt.tech`

### 🗄️ Databases
- **PostgreSQL**: `solarnexus`, `nexus_green`, `nexusgreen`
- **Redis**: Related Redis data

---

## 📖 Detailed Usage Examples

### Example 1: First-Time Clean Installation
```bash
# Download the script
wget https://raw.githubusercontent.com/Reshigan/SolarNexus/main/manage-installations.sh
chmod +x manage-installations.sh

# Run clean installation
./manage-installations.sh clean-install
```

### Example 2: Check What's Installed
```bash
# Scan system
./manage-installations.sh scan

# Example output:
# Found 3 existing installation(s):
#   • DIR: /opt/solarnexus
#   • DOCKER_CONTAINER: solarnexus-frontend
#   • SERVICE: solarnexus
```

### Example 3: Backup Before Changes
```bash
# Create backup first
./manage-installations.sh backup

# Then proceed with changes
./manage-installations.sh remove
```

### Example 4: Custom Installation Path
```bash
# Install to custom location
./manage-installations.sh install /home/user/nexus-green

# Or clean install to custom location
./manage-installations.sh clean-install /var/www/nexus-green
```

---

## 🔧 Advanced Options

### Command Line Flags
```bash
# Skip confirmation prompts (use with caution!)
./manage-installations.sh remove --force

# Skip backup creation
./manage-installations.sh clean-install --no-backup

# Verbose output
./manage-installations.sh scan --verbose
```

### Manual Cleanup Steps
If you need to clean specific components manually:

```bash
# Clean only Docker resources
docker stop $(docker ps -q --filter "name=solarnexus")
docker rm $(docker ps -aq --filter "name=solarnexus")
docker rmi $(docker images -q --filter "reference=solarnexus*")

# Clean only system services
sudo systemctl stop solarnexus
sudo systemctl disable solarnexus
sudo rm /etc/systemd/system/solarnexus.service

# Clean only directories
sudo rm -rf /opt/solarnexus /opt/nexus-green
```

---

## ⚠️ Important Warnings

### Data Loss Prevention
- **Always backup** before running removal commands
- **Database removal** is optional and requires confirmation
- **SSL certificates** removal is optional and requires confirmation

### What Gets Removed
✅ **Safe to Remove:**
- Application files and directories
- Docker containers and images
- System services
- Nginx configurations
- Log files
- Temporary files

⚠️ **Requires Confirmation:**
- SSL certificates
- Databases (all data will be lost!)
- User configurations

### Recovery
If you need to recover after accidental removal:
1. Check backup directory: `/opt/nexus-green-backups/`
2. Restore from backup: `sudo cp -r /opt/nexus-green-backups/latest/* /opt/nexus-green/`
3. Restore databases from SQL dumps in backup directory

---

## 🎯 Common Use Cases

### Scenario 1: Upgrading to Latest Version
```bash
# Backup current installation
./manage-installations.sh backup

# Clean install latest version
./manage-installations.sh clean-install

# Restore custom configurations if needed
```

### Scenario 2: Moving Installation Location
```bash
# Backup current installation
./manage-installations.sh backup

# Remove old installation
./manage-installations.sh remove

# Install to new location
./manage-installations.sh install /new/path/nexus-green
```

### Scenario 3: Troubleshooting Installation Issues
```bash
# Check what's currently installed
./manage-installations.sh scan

# Clean everything and start fresh
./manage-installations.sh clean-install

# Check system resources
./manage-installations.sh cleanup
```

### Scenario 4: Complete System Cleanup
```bash
# Remove everything
./manage-installations.sh remove

# Clean system resources
./manage-installations.sh cleanup

# Fresh start
./manage-installations.sh install
```

---

## 🆘 Troubleshooting

### Script Won't Run
```bash
# Make sure it's executable
chmod +x manage-installations.sh

# Check if bash is available
which bash

# Run with explicit bash
bash manage-installations.sh scan
```

### Permission Issues
```bash
# Some operations require sudo
sudo ./manage-installations.sh remove

# Or run as root (not recommended)
sudo su
./manage-installations.sh clean-install
```

### Docker Issues
```bash
# If Docker commands fail
sudo usermod -aG docker $USER
# Then logout and login again

# Or use sudo for Docker commands
sudo docker ps -a
```

### Database Issues
```bash
# Check PostgreSQL status
sudo systemctl status postgresql

# Check databases manually
sudo -u postgres psql -l
```

---

## 📞 Support

If you encounter issues:

1. **Check the logs**: Script provides detailed output
2. **Run scan first**: `./manage-installations.sh scan`
3. **Try manual cleanup**: Use individual commands from the script
4. **Check system resources**: `./manage-installations.sh cleanup`

### Contact Information
- **Technical Support**: reshigan@gonxt.tech
- **Repository**: https://github.com/Reshigan/SolarNexus
- **Documentation**: Check repository README and wiki

---

## 🎉 Success!

After successful installation, you should have:
- ✅ Clean Nexus Green v4.0.0 installation
- ✅ All dependencies installed
- ✅ Production build ready
- ✅ Environment configured
- ✅ System cleaned up

**Next Steps:**
1. Configure your `.env` file
2. Set up your database
3. Configure Nginx
4. Run the deployment script: `./deploy-production.sh`

---

*Installation Management Guide for Nexus Green v4.0.0*  
*Last Updated: September 14, 2024*