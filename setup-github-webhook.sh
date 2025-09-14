#!/bin/bash

# GitHub Webhook Setup Script for SolarNexus Auto-Upgrade
# This script helps configure GitHub webhooks for automatic deployments

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REPO_OWNER="Reshigan"
REPO_NAME="SolarNexus"
WEBHOOK_PORT=9876
SERVER_IP=""
GITHUB_TOKEN=""

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

show_usage() {
    cat << EOF
GitHub Webhook Setup for SolarNexus Auto-Upgrade

Usage: $0 [OPTIONS]

Options:
    --server-ip IP      Server IP address for webhook URL
    --token TOKEN       GitHub personal access token
    --port PORT         Webhook port (default: 9876)
    --repo OWNER/REPO   Repository (default: Reshigan/SolarNexus)
    --help              Show this help message

Examples:
    $0 --server-ip 1.2.3.4 --token ghp_xxxxxxxxxxxx
    $0 --server-ip 1.2.3.4 --token ghp_xxxxxxxxxxxx --port 8080

Setup Steps:
    1. Create a GitHub Personal Access Token with 'repo' permissions
    2. Run this script with your server IP and token
    3. The webhook will be automatically configured

Manual Setup:
    If you prefer to set up the webhook manually:
    1. Go to https://github.com/$REPO_OWNER/$REPO_NAME/settings/hooks
    2. Click "Add webhook"
    3. Set Payload URL to: http://YOUR_SERVER_IP:$WEBHOOK_PORT
    4. Set Content type to: application/json
    5. Select "Just the push event"
    6. Click "Add webhook"

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --server-ip)
            SERVER_IP="$2"
            shift 2
            ;;
        --token)
            GITHUB_TOKEN="$2"
            shift 2
            ;;
        --port)
            WEBHOOK_PORT="$2"
            shift 2
            ;;
        --repo)
            IFS='/' read -r REPO_OWNER REPO_NAME <<< "$2"
            shift 2
            ;;
        --help)
            show_usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Validate inputs
if [ -z "$SERVER_IP" ]; then
    print_error "Server IP is required. Use --server-ip option."
    show_usage
    exit 1
fi

if [ -z "$GITHUB_TOKEN" ]; then
    print_error "GitHub token is required. Use --token option."
    show_usage
    exit 1
fi

# Validate IP format
if ! [[ $SERVER_IP =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    print_error "Invalid IP address format: $SERVER_IP"
    exit 1
fi

print_info "Setting up GitHub webhook for automatic deployments..."
print_info "Repository: $REPO_OWNER/$REPO_NAME"
print_info "Server IP: $SERVER_IP"
print_info "Webhook Port: $WEBHOOK_PORT"

# Create webhook payload
WEBHOOK_URL="http://$SERVER_IP:$WEBHOOK_PORT"
WEBHOOK_PAYLOAD=$(cat << EOF
{
  "name": "web",
  "active": true,
  "events": ["push"],
  "config": {
    "url": "$WEBHOOK_URL",
    "content_type": "json",
    "insecure_ssl": "1"
  }
}
EOF
)

print_info "Creating webhook with URL: $WEBHOOK_URL"

# Create the webhook using GitHub API
RESPONSE=$(curl -s -w "\n%{http_code}" \
  -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  -d "$WEBHOOK_PAYLOAD" \
  "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/hooks")

# Extract HTTP status code
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
RESPONSE_BODY=$(echo "$RESPONSE" | head -n -1)

if [ "$HTTP_CODE" = "201" ]; then
    print_success "Webhook created successfully!"
    
    # Extract webhook ID from response
    WEBHOOK_ID=$(echo "$RESPONSE_BODY" | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)
    print_info "Webhook ID: $WEBHOOK_ID"
    
    # Test the webhook
    print_info "Testing webhook connectivity..."
    if curl -f -s --max-time 5 "$WEBHOOK_URL" > /dev/null 2>&1; then
        print_success "Webhook endpoint is accessible"
    else
        print_warning "Webhook endpoint test failed - ensure the auto-updater service is running"
        print_info "Start the service with: systemctl start solarnexus-updater"
    fi
    
    print_success "Setup completed!"
    echo ""
    echo "🎉 GitHub webhook is now configured for automatic deployments!"
    echo ""
    echo "📋 Summary:"
    echo "  • Repository: https://github.com/$REPO_OWNER/$REPO_NAME"
    echo "  • Webhook URL: $WEBHOOK_URL"
    echo "  • Webhook ID: $WEBHOOK_ID"
    echo "  • Events: Push to any branch"
    echo ""
    echo "🔧 Next Steps:"
    echo "  • Ensure the auto-updater service is running: systemctl status solarnexus-updater"
    echo "  • Test by pushing a commit to the repository"
    echo "  • Monitor logs: journalctl -u solarnexus-updater -f"
    echo "  • Check webhook deliveries: https://github.com/$REPO_OWNER/$REPO_NAME/settings/hooks/$WEBHOOK_ID"
    echo ""
    echo "🔥 Firewall Note:"
    echo "  • Ensure port $WEBHOOK_PORT is open for incoming connections"
    echo "  • Run: ufw allow $WEBHOOK_PORT/tcp"
    
elif [ "$HTTP_CODE" = "422" ]; then
    if echo "$RESPONSE_BODY" | grep -q "Hook already exists"; then
        print_warning "Webhook already exists for this URL"
        print_info "You can manage existing webhooks at:"
        print_info "https://github.com/$REPO_OWNER/$REPO_NAME/settings/hooks"
    else
        print_error "Validation failed: $RESPONSE_BODY"
        exit 1
    fi
elif [ "$HTTP_CODE" = "401" ]; then
    print_error "Authentication failed. Please check your GitHub token."
    print_info "Ensure your token has 'repo' permissions."
    exit 1
elif [ "$HTTP_CODE" = "404" ]; then
    print_error "Repository not found: $REPO_OWNER/$REPO_NAME"
    print_info "Please check the repository name and your access permissions."
    exit 1
else
    print_error "Failed to create webhook. HTTP Code: $HTTP_CODE"
    print_error "Response: $RESPONSE_BODY"
    exit 1
fi