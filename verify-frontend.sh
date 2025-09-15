#!/bin/bash
# Verify frontend is working properly

echo "🔍 Verifying frontend is working..."

echo "=== 1. Container Status ==="
sudo docker-compose -f docker-compose.public.yml ps

echo -e "\n=== 2. Frontend HTML Check ==="
echo "First 20 lines of frontend response:"
curl -s http://localhost | head -20

echo -e "\n=== 3. JavaScript Files Check ==="
echo "Checking if JS files are accessible:"
curl -s -o /dev/null -w "Main JS: %{http_code} (%{size_download} bytes)\n" http://localhost/assets/index-*.js 2>/dev/null || echo "JS files not found with wildcard, checking specific files..."

# Get actual JS filename from HTML
JS_FILE=$(curl -s http://localhost | grep -o 'assets/index-[^"]*\.js' | head -1)
CSS_FILE=$(curl -s http://localhost | grep -o 'assets/index-[^"]*\.css' | head -1)

if [ ! -z "$JS_FILE" ]; then
    echo "Found JS file: $JS_FILE"
    curl -s -o /dev/null -w "JS Status: %{http_code} (%{size_download} bytes)\n" http://localhost/$JS_FILE
else
    echo "❌ No JS file found in HTML"
fi

if [ ! -z "$CSS_FILE" ]; then
    echo "Found CSS file: $CSS_FILE"
    curl -s -o /dev/null -w "CSS Status: %{http_code} (%{size_download} bytes)\n" http://localhost/$CSS_FILE
else
    echo "❌ No CSS file found in HTML"
fi

echo -e "\n=== 4. API Connectivity ==="
echo "API Health:"
curl -s http://localhost/api/health | jq . 2>/dev/null || curl -s http://localhost/api/health

echo -e "\n=== 5. External Access Test ==="
echo "Testing external access (this should work from your browser):"
curl -s -o /dev/null -w "External Status: %{http_code}\n" http://13.245.181.202

echo -e "\n=== 6. Browser Simulation ==="
echo "Simulating browser request with proper headers:"
curl -s -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" \
     -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36" \
     http://localhost | head -10

echo -e "\n=== 7. Container Logs (Last 10 Lines) ==="
echo "Frontend container logs:"
sudo docker-compose -f docker-compose.public.yml logs --tail=10 nexus-green

echo -e "\n🎯 Summary:"
echo "✅ Containers: $(sudo docker-compose -f docker-compose.public.yml ps --format 'table {{.Name}}\t{{.Status}}' | grep -c 'Up')/3 running"
echo "✅ Health: $(curl -s http://localhost/health)"
echo "✅ API: $(curl -s http://localhost/api/health | grep -o '"status":"[^"]*"' | cut -d'"' -f4)"

echo -e "\n🌐 Ready to test in browser:"
echo "   http://13.245.181.202"
echo ""
echo "If you still see a blank page:"
echo "1. Try hard refresh (Ctrl+F5 or Cmd+Shift+R)"
echo "2. Open browser developer tools (F12) and check Console for errors"
echo "3. Check Network tab to see if assets are loading"