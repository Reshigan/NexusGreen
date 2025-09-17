#!/bin/bash

# NexusGreen Production Deployment Script
# This script deploys NexusGreen to a production AWS server using K3s

set -e

echo "🚀 Starting NexusGreen Production Deployment..."

# Configuration
NAMESPACE="nexus-green-prod"
DOMAIN="${DOMAIN:-nexusgreen.com}"  # Set your domain here
SERVER_IP="${SERVER_IP:-}"  # Will be set during deployment

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if we're running on the server or need to SSH
if [ -z "$SERVER_IP" ]; then
    echo "Running deployment locally on server..."
    LOCAL_DEPLOY=true
else
    echo "Deploying to remote server: $SERVER_IP"
    LOCAL_DEPLOY=false
fi

# Function to run commands (local or remote)
run_cmd() {
    if [ "$LOCAL_DEPLOY" = true ]; then
        eval "$1"
    else
        ssh -o StrictHostKeyChecking=no "$SSH_USER@$SERVER_IP" "$1"
    fi
}

# Function to copy files (local or remote)
copy_files() {
    if [ "$LOCAL_DEPLOY" = true ]; then
        cp -r "$1" "$2"
    else
        scp -o StrictHostKeyChecking=no -r "$1" "$SSH_USER@$SERVER_IP:$2"
    fi
}

# Step 1: Install K3s if not already installed
install_k3s() {
    print_status "Installing K3s..."
    run_cmd "curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644"
    run_cmd "sudo systemctl enable k3s"
    run_cmd "sudo systemctl start k3s"
    
    # Wait for K3s to be ready
    print_status "Waiting for K3s to be ready..."
    run_cmd "sudo k3s kubectl wait --for=condition=Ready nodes --all --timeout=300s"
}

# Step 2: Install cert-manager for SSL
install_cert_manager() {
    print_status "Installing cert-manager..."
    run_cmd "sudo k3s kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml"
    
    # Wait for cert-manager to be ready
    print_status "Waiting for cert-manager to be ready..."
    run_cmd "sudo k3s kubectl wait --for=condition=Available deployment --all -n cert-manager --timeout=300s"
}

# Step 3: Create ClusterIssuer for Let's Encrypt
create_cluster_issuer() {
    print_status "Creating Let's Encrypt ClusterIssuer..."
    
    cat > /tmp/cluster-issuer.yaml << EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@${DOMAIN}
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: traefik
EOF
    
    if [ "$LOCAL_DEPLOY" = false ]; then
        scp -o StrictHostKeyChecking=no /tmp/cluster-issuer.yaml "$SSH_USER@$SERVER_IP:/tmp/"
    fi
    
    run_cmd "sudo k3s kubectl apply -f /tmp/cluster-issuer.yaml"
}

# Step 4: Build and load Docker images
build_and_load_images() {
    print_status "Building Docker images..."
    
    # Build API image
    docker build -t nexus-green-api:latest ./backend/
    
    # Build Frontend image (using our working v2)
    docker build -t nexus-green-frontend:v2 ./frontend/
    
    if [ "$LOCAL_DEPLOY" = false ]; then
        # Save images and transfer to server
        print_status "Transferring images to server..."
        docker save nexus-green-api:latest | gzip > /tmp/nexus-api.tar.gz
        docker save nexus-green-frontend:v2 | gzip > /tmp/nexus-frontend.tar.gz
        
        scp -o StrictHostKeyChecking=no /tmp/nexus-api.tar.gz "$SSH_USER@$SERVER_IP:/tmp/"
        scp -o StrictHostKeyChecking=no /tmp/nexus-frontend.tar.gz "$SSH_USER@$SERVER_IP:/tmp/"
        
        # Load images on server
        run_cmd "sudo k3s ctr images import /tmp/nexus-api.tar.gz"
        run_cmd "sudo k3s ctr images import /tmp/nexus-frontend.tar.gz"
    else
        # Load images directly
        docker save nexus-green-api:latest | sudo k3s ctr images import -
        docker save nexus-green-frontend:v2 | sudo k3s ctr images import -
    fi
}

# Step 5: Deploy application
deploy_application() {
    print_status "Deploying NexusGreen application..."
    
    # Copy Kubernetes manifests
    if [ "$LOCAL_DEPLOY" = false ]; then
        scp -o StrictHostKeyChecking=no -r ./k8s/production/ "$SSH_USER@$SERVER_IP:/tmp/"
        MANIFEST_PATH="/tmp/production"
    else
        MANIFEST_PATH="./k8s/production"
    fi
    
    # Apply manifests in order
    run_cmd "sudo k3s kubectl apply -f $MANIFEST_PATH/namespace.yaml"
    run_cmd "sudo k3s kubectl apply -f $MANIFEST_PATH/postgres.yaml"
    
    # Wait for postgres to be ready
    print_status "Waiting for PostgreSQL to be ready..."
    run_cmd "sudo k3s kubectl wait --for=condition=Available deployment/postgres -n $NAMESPACE --timeout=300s"
    
    # Run database initialization
    print_status "Initializing database..."
    run_cmd "sudo k3s kubectl apply -f $MANIFEST_PATH/../db-init.yaml"
    
    # Deploy backend
    run_cmd "sudo k3s kubectl apply -f $MANIFEST_PATH/backend.yaml"
    
    # Wait for backend to be ready
    print_status "Waiting for API backend to be ready..."
    run_cmd "sudo k3s kubectl wait --for=condition=Available deployment/nexus-api -n $NAMESPACE --timeout=300s"
    
    # Deploy frontend
    run_cmd "sudo k3s kubectl apply -f $MANIFEST_PATH/frontend.yaml"
    
    # Wait for frontend to be ready
    print_status "Waiting for frontend to be ready..."
    run_cmd "sudo k3s kubectl wait --for=condition=Available deployment/nexus-frontend -n $NAMESPACE --timeout=300s"
    
    # Deploy ingress
    run_cmd "sudo k3s kubectl apply -f $MANIFEST_PATH/ingress.yaml"
}

# Step 6: Verify deployment
verify_deployment() {
    print_status "Verifying deployment..."
    
    # Check pod status
    run_cmd "sudo k3s kubectl get pods -n $NAMESPACE"
    
    # Check services
    run_cmd "sudo k3s kubectl get services -n $NAMESPACE"
    
    # Check ingress
    run_cmd "sudo k3s kubectl get ingress -n $NAMESPACE"
    
    # Get external IP
    if [ "$LOCAL_DEPLOY" = true ]; then
        EXTERNAL_IP=$(curl -s ifconfig.me)
        print_status "Application should be accessible at: http://$EXTERNAL_IP"
        if [ -n "$DOMAIN" ]; then
            print_status "Once DNS is configured: https://$DOMAIN"
        fi
    fi
}

# Main deployment flow
main() {
    print_status "Starting deployment process..."
    
    # Check prerequisites
    if ! command -v docker &> /dev/null; then
        print_error "Docker is required but not installed"
        exit 1
    fi
    
    # Run deployment steps
    install_k3s
    install_cert_manager
    create_cluster_issuer
    build_and_load_images
    deploy_application
    verify_deployment
    
    print_status "🎉 NexusGreen deployment completed successfully!"
    print_warning "Don't forget to:"
    echo "  1. Point your domain DNS to this server's IP"
    echo "  2. Update the domain in ingress.yaml if different"
    echo "  3. Monitor the SSL certificate creation"
}

# Run main function
main "$@"