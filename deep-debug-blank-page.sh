#!/bin/bash
# Deep debugging for blank page issue

echo "🔍 Deep debugging blank page issue..."

echo "=== 1. Container Inspection ==="
echo "Frontend container details:"
sudo docker inspect nexus-green | grep -A 5 -B 5 "Mounts\|Env"

echo -e "\n=== 2. Built Files Analysis ==="
echo "Files inside the container:"
sudo docker exec nexus-green ls -la /usr/share/nginx/html/

echo -e "\nAssets directory:"
sudo docker exec nexus-green ls -la /usr/share/nginx/html/assets/ 2>/dev/null || echo "No assets directory found"

echo -e "\n=== 3. HTML Content Analysis ==="
echo "Complete index.html content:"
sudo docker exec nexus-green cat /usr/share/nginx/html/index.html

echo -e "\n=== 4. JavaScript File Analysis ==="
JS_FILES=$(sudo docker exec nexus-green find /usr/share/nginx/html -name "*.js" -type f)
for js_file in $JS_FILES; do
    echo -e "\n--- JavaScript file: $js_file ---"
    echo "Size: $(sudo docker exec nexus-green stat -c%s $js_file) bytes"
    echo "First 500 characters:"
    sudo docker exec nexus-green head -c 500 $js_file
    echo -e "\n..."
    echo "Last 200 characters:"
    sudo docker exec nexus-green tail -c 200 $js_file
    echo -e "\n"
done

echo -e "\n=== 5. CSS File Analysis ==="
CSS_FILES=$(sudo docker exec nexus-green find /usr/share/nginx/html -name "*.css" -type f)
for css_file in $CSS_FILES; do
    echo -e "\n--- CSS file: $css_file ---"
    echo "Size: $(sudo docker exec nexus-green stat -c%s $css_file) bytes"
    echo "First 200 characters:"
    sudo docker exec nexus-green head -c 200 $css_file
    echo -e "\n"
done

echo -e "\n=== 6. Nginx Configuration Check ==="
echo "Nginx config:"
sudo docker exec nexus-green cat /etc/nginx/nginx.conf

echo -e "\n=== 7. Network Connectivity Test ==="
echo "Testing asset loading from inside container:"
sudo docker exec nexus-green wget -q -O - http://localhost/assets/index-*.js 2>/dev/null | head -100 || echo "Failed to load JS from inside container"

echo -e "\n=== 8. Browser Simulation with Headers ==="
echo "Simulating browser request:"
curl -v -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8" \
     -H "Accept-Language: en-US,en;q=0.5" \
     -H "Accept-Encoding: gzip, deflate" \
     -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:91.0) Gecko/20100101 Firefox/91.0" \
     http://localhost 2>&1 | head -50

echo -e "\n=== 9. Create Minimal Test Page ==="
echo "Creating minimal test page to verify nginx is serving files correctly:"
sudo docker exec nexus-green sh -c 'cat > /usr/share/nginx/html/test.html << "EOF"
<!DOCTYPE html>
<html>
<head>
    <title>Test Page</title>
    <style>
        body { font-family: Arial, sans-serif; text-align: center; padding: 50px; }
        .success { color: green; }
        .error { color: red; }
    </style>
</head>
<body>
    <h1 class="success">✅ Test Page Working!</h1>
    <p>If you can see this, nginx is serving files correctly.</p>
    <div id="js-test">❌ JavaScript not loaded</div>
    <script>
        console.log("Test JavaScript is running");
        document.getElementById("js-test").innerHTML = "✅ JavaScript is working!";
        document.getElementById("js-test").className = "success";
        
        // Test API call
        fetch("/api/health")
            .then(response => response.json())
            .then(data => {
                console.log("API Response:", data);
                document.body.innerHTML += "<p class=\"success\">✅ API Connection: " + data.status + "</p>";
            })
            .catch(error => {
                console.error("API Error:", error);
                document.body.innerHTML += "<p class=\"error\">❌ API Connection Failed</p>";
            });
    </script>
</body>
</html>
EOF'

echo "Test page created. Access it at: http://13.245.181.202/test.html"

echo -e "\n=== 10. React App Root Element Check ==="
echo "Checking if React root element exists in HTML:"
sudo docker exec nexus-green grep -n "root\|app\|div" /usr/share/nginx/html/index.html

echo -e "\n=== 11. Environment Variables in Built Files ==="
echo "Checking if environment variables were properly embedded:"
sudo docker exec nexus-green grep -r "VITE_\|13.245.181.202\|api" /usr/share/nginx/html/ 2>/dev/null | head -10

echo -e "\n=== 12. Container Logs ==="
echo "Recent nginx logs:"
sudo docker logs nexus-green --tail=20

echo -e "\n🎯 SUMMARY:"
echo "1. Visit http://13.245.181.202/test.html to verify basic functionality"
echo "2. Check browser developer tools (F12) for JavaScript errors"
echo "3. Look at the Network tab to see if assets are loading"
echo "4. If test.html works but main page doesn't, the issue is with the React app"

echo -e "\n💡 Next steps based on results:"
echo "- If test.html works: React app issue"
echo "- If test.html doesn't work: Nginx/server issue"
echo "- If assets don't load: Path/routing issue"