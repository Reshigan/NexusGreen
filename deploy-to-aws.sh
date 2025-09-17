#!/bin/bash

# NexusGreen AWS Kubernetes Deployment Script
# This script deploys the updated NexusGreen application to AWS server
# Run this script on the AWS server (13.245.110.11)

set -e

echo "🚀 Starting NexusGreen deployment to AWS Kubernetes cluster..."

# Configuration
NAMESPACE="nexus-green"
FRONTEND_IMAGE="nexus-frontend:latest"
API_IMAGE="nexus-api:latest"
POSTGRES_IMAGE="postgres:15"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
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

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed or not in PATH"
    exit 1
fi

# Check if docker is available
if ! command -v docker &> /dev/null; then
    print_error "docker is not installed or not in PATH"
    exit 1
fi

print_status "Checking Kubernetes cluster connection..."
if ! kubectl cluster-info &> /dev/null; then
    print_error "Cannot connect to Kubernetes cluster"
    exit 1
fi
print_success "Connected to Kubernetes cluster"

# Create namespace if it doesn't exist
print_status "Creating namespace: $NAMESPACE"
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Build Docker images
print_status "Building Docker images..."

# Build frontend image
print_status "Building frontend image..."
cd /root/NexusGreen
docker build -t $FRONTEND_IMAGE -f Dockerfile.frontend .
print_success "Frontend image built successfully"

# Build API image
print_status "Building API image..."
docker build -t $API_IMAGE -f api/Dockerfile ./api
print_success "API image built successfully"

# Deploy PostgreSQL
print_status "Deploying PostgreSQL database..."
kubectl apply -f k8s/postgres.yaml
print_success "PostgreSQL deployed"

# Wait for PostgreSQL to be ready
print_status "Waiting for PostgreSQL to be ready..."
kubectl wait --for=condition=ready pod -l app=nexus-postgres -n $NAMESPACE --timeout=300s
print_success "PostgreSQL is ready"

# Run database schema initialization
print_status "Initializing database schema..."
kubectl apply -f k8s/schema-job.yaml
kubectl wait --for=condition=complete job/nexus-schema-init -n $NAMESPACE --timeout=300s
print_success "Database schema initialized"

# Run database seed job
print_status "Seeding database with demo data..."
kubectl apply -f k8s/seed-job.yaml
kubectl wait --for=condition=complete job/nexus-seed-data -n $NAMESPACE --timeout=300s
print_success "Database seeded with demo data"

# Deploy API
print_status "Deploying API service..."
kubectl apply -f k8s/api.yaml
print_success "API service deployed"

# Deploy Frontend
print_status "Deploying frontend service..."
kubectl apply -f k8s/frontend.yaml
print_success "Frontend service deployed"

# Deploy NodePort service for external access
print_status "Deploying NodePort service..."
kubectl apply -f k8s/nodeport.yaml
print_success "NodePort service deployed"

# Wait for deployments to be ready
print_status "Waiting for deployments to be ready..."
kubectl wait --for=condition=available deployment/nexus-api -n $NAMESPACE --timeout=300s
kubectl wait --for=condition=available deployment/nexus-frontend -n $NAMESPACE --timeout=300s
print_success "All deployments are ready"

# Get service information
print_status "Getting service information..."
echo ""
echo "=== Deployment Summary ==="
kubectl get pods -n $NAMESPACE
echo ""
kubectl get services -n $NAMESPACE
echo ""

# Get NodePort information
NODEPORT=$(kubectl get service nexus-nodeport -n $NAMESPACE -o jsonpath='{.spec.ports[0].nodePort}')
print_success "Application deployed successfully!"
echo ""
echo "=== Access Information ==="
echo "🌐 Application URL: http://13.245.110.11:$NODEPORT"
echo "🔗 API Health Check: http://13.245.110.11:$NODEPORT/api-health"
echo ""
echo "=== Demo Credentials ==="
echo "👤 Admin: admin@gonxt.tech / Demo2024!"
echo "👤 User: user@gonxt.tech / Demo2024!"
echo "👤 Funder: funder@gonxt.tech / Demo2024!"
echo "👤 OM Provider: om@gonxt.tech / Demo2024!"
echo ""

# Test the deployment
print_status "Testing deployment..."
sleep 10
if curl -f -s "http://13.245.110.11:$NODEPORT/api-health" > /dev/null; then
    print_success "API health check passed"
else
    print_warning "API health check failed - application may still be starting"
fi

print_success "Deployment completed successfully!"
echo ""
echo "🎉 NexusGreen is now running on AWS Kubernetes cluster"
echo "📊 The application includes comprehensive demo data with realistic solar installations"
echo "🔐 Use the demo credentials above to access different user portals"
echo ""
echo "Next steps:"
echo "1. Access the application at http://13.245.110.11:$NODEPORT"
echo "2. Login with demo credentials"
echo "3. Explore the solar energy management features"
echo "4. Configure SSL certificate (optional)"