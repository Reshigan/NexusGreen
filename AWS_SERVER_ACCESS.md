# AWS Server Access Information

## SSH Connection Details
- **Server IP**: 13.245.110.11
- **Username**: ec2-user
- **SSH Key**: NEXUSAI.pem
- **Connection Command**: `ssh -i "NEXUSAI.pem" ec2-user@13.245.110.11`

## Server Configuration
- **OS**: Amazon Linux 2
- **Kubernetes**: Installed and configured
- **Domain**: nexus.gonxt.tech (DNS configured to point to 13.245.110.11)
- **SSL**: Will be configured with Let's Encrypt via certbot

## Deployment Process
1. Connect via SSH using the provided key
2. Transfer updated application files
3. Build and deploy to Kubernetes
4. Configure SSL certificate with certbot
5. Update ingress for HTTPS access

## Important Notes
- Keep the NEXUSAI.pem key secure and with proper permissions (chmod 600)
- The server has existing Kubernetes infrastructure
- SSL certificate will be managed by certbot for nexus.gonxt.tech domain