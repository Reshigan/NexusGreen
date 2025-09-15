#!/bin/bash
# Comprehensive React app fix - addresses most common mounting issues

echo "🚀 Applying comprehensive React app fix..."

# Stop containers first
echo "=== Stopping containers ==="
sudo docker-compose -f docker-compose.public.yml down

# Fix 1: Update the main React app to handle potential mounting issues
echo "=== Fix 1: Creating robust React app entry point ==="
cat > src/main.tsx << 'EOF'
import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App.tsx'
import './index.css'

// Debug logging
console.log('🚀 NexusGreen: Starting React app...')
console.log('🔍 Environment:', {
  NODE_ENV: import.meta.env.NODE_ENV,
  VITE_API_URL: import.meta.env.VITE_API_URL,
  VITE_APP_NAME: import.meta.env.VITE_APP_NAME
})

// Ensure DOM is ready
function initializeApp() {
  const rootElement = document.getElementById('root')
  
  if (!rootElement) {
    console.error('❌ Root element not found!')
    return
  }
  
  console.log('✅ Root element found:', rootElement)
  
  try {
    const root = ReactDOM.createRoot(rootElement)
    console.log('✅ React root created')
    
    root.render(
      <React.StrictMode>
        <App />
      </React.StrictMode>
    )
    
    console.log('✅ React app rendered successfully')
  } catch (error) {
    console.error('❌ Error rendering React app:', error)
    
    // Fallback: Show error message
    rootElement.innerHTML = `
      <div style="padding: 20px; text-align: center; font-family: Arial, sans-serif;">
        <h1 style="color: #ef4444;">⚠️ Application Error</h1>
        <p>Failed to load the NexusGreen application.</p>
        <p style="font-size: 12px; color: #666;">Check browser console for details.</p>
        <button onclick="window.location.reload()" style="padding: 10px 20px; margin-top: 10px;">
          Reload Page
        </button>
      </div>
    `
  }
}

// Initialize when DOM is ready
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initializeApp)
} else {
  initializeApp()
}
EOF

# Fix 2: Update index.html to be more robust
echo "=== Fix 2: Creating robust HTML template ==="
cat > index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>NexusGreen - Solar Energy Management Platform</title>
    <meta name="description" content="Professional solar energy management platform with real-time analytics, advanced monitoring, AI-powered insights, and comprehensive installation management for enterprise solar operations." />
    
    <!-- Favicon -->
    <link rel="icon" type="image/svg+xml" href="/nexus-green-icon.svg" />
    <link rel="icon" type="image/x-icon" href="/favicon.ico" />
    
    <!-- Preconnect for performance -->
    <link rel="preconnect" href="https://fonts.googleapis.com" />
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
    
    <!-- Critical CSS for loading state -->
    <style>
      * {
        box-sizing: border-box;
      }
      
      body {
        margin: 0;
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Oxygen', 'Ubuntu', 'Cantarell', 'Fira Sans', 'Droid Sans', 'Helvetica Neue', sans-serif;
        -webkit-font-smoothing: antialiased;
        -moz-osx-font-smoothing: grayscale;
        background: linear-gradient(135deg, #f9fafb 0%, #ffffff 50%, #f0f9ff 100%);
        min-height: 100vh;
      }
      
      #root {
        min-height: 100vh;
        display: flex;
        align-items: center;
        justify-content: center;
      }
      
      /* Loading spinner */
      .loading-container {
        text-align: center;
        padding: 2rem;
      }
      
      .loading-spinner {
        display: inline-block;
        width: 40px;
        height: 40px;
        border: 3px solid #f3f3f3;
        border-top: 3px solid #10B981;
        border-radius: 50%;
        animation: spin 1s linear infinite;
        margin-bottom: 1rem;
      }
      
      @keyframes spin {
        0% { transform: rotate(0deg); }
        100% { transform: rotate(360deg); }
      }
      
      .loading-text {
        color: #374151;
        font-size: 1.1rem;
        font-weight: 500;
      }
      
      .loading-subtext {
        color: #6B7280;
        font-size: 0.9rem;
        margin-top: 0.5rem;
      }
    </style>
  </head>

  <body>
    <div id="root">
      <div class="loading-container">
        <div class="loading-spinner"></div>
        <div class="loading-text">Loading NexusGreen</div>
        <div class="loading-subtext">Solar Energy Management Platform</div>
      </div>
    </div>
    
    <!-- Error handling script -->
    <script>
      // Global error handler
      window.addEventListener('error', function(e) {
        console.error('Global error:', e.error);
      });
      
      window.addEventListener('unhandledrejection', function(e) {
        console.error('Unhandled promise rejection:', e.reason);
      });
      
      // Timeout fallback
      setTimeout(function() {
        const root = document.getElementById('root');
        if (root && root.innerHTML.includes('loading-container')) {
          console.warn('⚠️ App took too long to load, showing fallback');
          root.innerHTML = `
            <div style="text-align: center; padding: 2rem; font-family: Arial, sans-serif;">
              <h1 style="color: #ef4444;">⚠️ Loading Timeout</h1>
              <p>The application is taking longer than expected to load.</p>
              <button onclick="window.location.reload()" style="padding: 10px 20px; margin: 10px; background: #10B981; color: white; border: none; border-radius: 4px; cursor: pointer;">
                Reload Page
              </button>
              <p style="font-size: 12px; color: #666; margin-top: 20px;">
                If this problem persists, please check your internet connection or contact support.
              </p>
            </div>
          `;
        }
      }, 10000); // 10 second timeout
    </script>
  </body>
</html>
EOF

# Fix 3: Update Dockerfile to ensure proper build
echo "=== Fix 3: Updating Dockerfile for robust build ==="
cat > Dockerfile << 'EOF'
# Multi-stage build for production
FROM node:18-alpine as builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install ALL dependencies (including dev dependencies for build)
RUN npm ci --verbose

# Copy source code
COPY . .

# Set build environment variables
ARG VITE_API_URL=http://13.245.181.202/api
ARG VITE_APP_NAME=NexusGreen
ARG VITE_APP_VERSION=6.1.0
ARG VITE_COMPANY_REG=2024/123456/07
ARG VITE_PPA_RATE=1.20

ENV VITE_API_URL=$VITE_API_URL
ENV VITE_APP_NAME=$VITE_APP_NAME
ENV VITE_APP_VERSION=$VITE_APP_VERSION
ENV VITE_COMPANY_REG=$VITE_COMPANY_REG
ENV VITE_PPA_RATE=$VITE_PPA_RATE

# Debug: Show environment
RUN echo "Build environment:" && env | grep VITE

# Verify vite is available
RUN echo "Checking vite installation:" && npx vite --version

# Build the application
RUN npm run build

# Verify build output
RUN echo "Build completed. Contents:" && ls -la dist/ && echo "Assets:" && ls -la dist/assets/

# Production stage
FROM nginx:alpine as production

# Install curl for health checks
RUN apk add --no-cache curl openssl

# Copy nginx configuration
COPY docker/nginx.conf /etc/nginx/nginx.conf

# Create SSL directory
RUN mkdir -p /etc/nginx/ssl

# Copy built application
COPY --from=builder /app/dist /usr/share/nginx/html

# Verify files were copied
RUN echo "Files in nginx html:" && ls -la /usr/share/nginx/html && echo "Assets:" && ls -la /usr/share/nginx/html/assets/

# Create necessary directories for nginx
RUN mkdir -p /tmp/client_temp /tmp/proxy_temp /var/cache/nginx/client_temp /var/cache/nginx/proxy_temp /var/cache/nginx/fastcgi_temp /var/cache/nginx/uwsgi_temp /var/cache/nginx/scgi_temp

# Health check endpoint
RUN echo "healthy" > /usr/share/nginx/html/health

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
EOF

# Fix 4: Rebuild with the fixes
echo "=== Fix 4: Rebuilding with comprehensive fixes ==="
sudo docker-compose -f docker-compose.public.yml build --no-cache nexus-green

# Fix 5: Start containers
echo "=== Fix 5: Starting containers ==="
sudo docker-compose -f docker-compose.public.yml up -d

# Wait for containers to be ready
echo "=== Waiting for containers to be ready ==="
sleep 10

# Fix 6: Test the fixes
echo "=== Fix 6: Testing the fixes ==="
echo "Health check:"
curl -s http://localhost/health && echo " ✅"

echo "Frontend check:"
curl -s http://localhost | head -10

echo "API check:"
curl -s http://localhost/api/health && echo " ✅"

echo -e "\n🎉 Comprehensive React fix applied!"
echo -e "\n🌐 Test your application:"
echo "Main app: http://13.245.181.202"
echo "Health: http://13.245.181.202/health"
echo "API: http://13.245.181.202/api/health"

echo -e "\n📋 What was fixed:"
echo "✅ Robust React app initialization with error handling"
echo "✅ Improved HTML template with loading states and fallbacks"
echo "✅ Enhanced Dockerfile with proper build verification"
echo "✅ Global error handling and timeout fallbacks"
echo "✅ Debug logging for troubleshooting"

echo -e "\n🔍 If still having issues:"
echo "1. Check browser console (F12) for detailed error messages"
echo "2. Try hard refresh (Ctrl+F5 or Cmd+Shift+R)"
echo "3. Check Network tab to verify all assets load with 200 status"
EOF