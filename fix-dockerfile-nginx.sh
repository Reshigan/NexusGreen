#!/bin/bash

# Fix for Dockerfile nginx configuration issues
# This script fixes the common "server {" Docker parsing error

set -e

echo "🔧 SolarNexus Dockerfile Nginx Configuration Fix"
echo "================================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 Checking for problematic Dockerfile patterns...${NC}"

# Function to fix heredoc issues in Dockerfiles
fix_dockerfile_heredoc() {
    local dockerfile=$1
    local backup_file="${dockerfile}.backup.$(date +%s)"
    
    if [[ -f "$dockerfile" ]]; then
        echo -e "${BLUE}📝 Checking $dockerfile...${NC}"
        
        # Check if file contains problematic heredoc pattern
        if grep -q "RUN cat > .* << 'EOF'" "$dockerfile"; then
            echo -e "${YELLOW}⚠️  Found heredoc pattern in $dockerfile${NC}"
            
            # Create backup
            cp "$dockerfile" "$backup_file"
            echo -e "${GREEN}✅ Backup created: $backup_file${NC}"
            
            # Fix the heredoc by converting to echo statements
            python3 << 'PYTHON_SCRIPT'
import re
import sys

dockerfile_path = sys.argv[1] if len(sys.argv) > 1 else 'Dockerfile'

try:
    with open(dockerfile_path, 'r') as f:
        content = f.read()
    
    # Pattern to match RUN cat > file << 'EOF' ... EOF
    pattern = r"RUN cat > ([^\s]+) << 'EOF'\n(.*?)\nEOF"
    
    def replace_heredoc(match):
        file_path = match.group(1)
        content_lines = match.group(2).split('\n')
        
        # Convert to echo statements
        echo_commands = []
        for i, line in enumerate(content_lines):
            # Escape single quotes in the line
            escaped_line = line.replace("'", "'\"'\"'")
            if i == 0:
                echo_commands.append(f"RUN echo '{escaped_line}' > {file_path}")
            else:
                echo_commands.append(f"    echo '{escaped_line}' >> {file_path}")
        
        return ' && \\\n'.join(echo_commands)
    
    # Apply the fix
    fixed_content = re.sub(pattern, replace_heredoc, content, flags=re.DOTALL)
    
    if fixed_content != content:
        with open(dockerfile_path, 'w') as f:
            f.write(fixed_content)
        print(f"✅ Fixed heredoc issues in {dockerfile_path}")
    else:
        print(f"ℹ️  No heredoc issues found in {dockerfile_path}")
        
except Exception as e:
    print(f"❌ Error processing {dockerfile_path}: {e}")
    sys.exit(1)
PYTHON_SCRIPT
        else
            echo -e "${GREEN}✅ No heredoc issues found in $dockerfile${NC}"
        fi
    fi
}

# Check common Dockerfile locations
DOCKERFILES=(
    "Dockerfile"
    "Dockerfile.production"
    "frontend/Dockerfile"
    "frontend/Dockerfile.production"
    "solarnexus-frontend/Dockerfile"
    "solarnexus-frontend/Dockerfile.production"
)

for dockerfile in "${DOCKERFILES[@]}"; do
    if [[ -f "$dockerfile" ]]; then
        fix_dockerfile_heredoc "$dockerfile"
    fi
done

echo -e "\n${BLUE}🔧 Creating alternative nginx configuration method...${NC}"

# Create a helper script for nginx configuration
cat > create-nginx-config.sh << 'EOF'
#!/bin/bash
# Helper script to create nginx configuration without heredoc issues

CONFIG_FILE="/etc/nginx/conf.d/default.conf"

# Remove default config
rm -f "$CONFIG_FILE"

# Create new configuration using echo statements
echo 'server {' > "$CONFIG_FILE"
echo '    listen 80;' >> "$CONFIG_FILE"
echo '    server_name _;' >> "$CONFIG_FILE"
echo '    root /usr/share/nginx/html;' >> "$CONFIG_FILE"
echo '    index index.html index.htm;' >> "$CONFIG_FILE"
echo '' >> "$CONFIG_FILE"
echo '    # Handle client-side routing' >> "$CONFIG_FILE"
echo '    location / {' >> "$CONFIG_FILE"
echo '        try_files $uri $uri/ /index.html;' >> "$CONFIG_FILE"
echo '    }' >> "$CONFIG_FILE"
echo '' >> "$CONFIG_FILE"
echo '    # Cache static assets' >> "$CONFIG_FILE"
echo '    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {' >> "$CONFIG_FILE"
echo '        expires 1y;' >> "$CONFIG_FILE"
echo '        add_header Cache-Control "public, immutable";' >> "$CONFIG_FILE"
echo '    }' >> "$CONFIG_FILE"
echo '' >> "$CONFIG_FILE"
echo '    # Health check' >> "$CONFIG_FILE"
echo '    location /health {' >> "$CONFIG_FILE"
echo '        access_log off;' >> "$CONFIG_FILE"
echo '        return 200 "healthy\n";' >> "$CONFIG_FILE"
echo '        add_header Content-Type text/plain;' >> "$CONFIG_FILE"
echo '    }' >> "$CONFIG_FILE"
echo '}' >> "$CONFIG_FILE"

echo "✅ Nginx configuration created successfully"
EOF

chmod +x create-nginx-config.sh

echo -e "${GREEN}✅ Created create-nginx-config.sh helper script${NC}"

echo -e "\n${BLUE}📋 Fix Summary:${NC}"
echo "  • Checked common Dockerfile locations for heredoc issues"
echo "  • Created backup files for any modified Dockerfiles"
echo "  • Generated create-nginx-config.sh helper script"
echo "  • Alternative nginx configuration method available"

echo -e "\n${BLUE}🔧 Usage Instructions:${NC}"
echo "  1. Use the working deployment: ./deploy-working.sh"
echo "  2. Or use the production Dockerfile: docker build -f Dockerfile.production ."
echo "  3. For custom nginx config: ./create-nginx-config.sh"

echo -e "\n${GREEN}✅ Dockerfile nginx configuration fix completed!${NC}"