#!/bin/bash
# Test if assets are loading properly

echo "🧪 Testing asset loading..."

echo "=== Testing main assets ==="
echo "Main JS file:"
curl -s -o /dev/null -w '%{http_code} %{size_download} bytes\n' http://localhost/assets/index-CwU5SbkU.js

echo "Main CSS file:"
curl -s -o /dev/null -w '%{http_code} %{size_download} bytes\n' http://localhost/assets/index-DxQpe1lr.css

echo "Vendor JS file:"
curl -s -o /dev/null -w '%{http_code} %{size_download} bytes\n' http://localhost/assets/vendor-ev0tmVNn.js

echo -e "\n=== Testing from external IP ==="
echo "External main JS:"
curl -s -o /dev/null -w '%{http_code} %{size_download} bytes\n' http://13.245.181.202/assets/index-CwU5SbkU.js

echo "External main CSS:"
curl -s -o /dev/null -w '%{http_code} %{size_download} bytes\n' http://13.245.181.202/assets/index-DxQpe1lr.css

echo -e "\n=== Browser Console Simulation ==="
echo "Checking for JavaScript errors in main file:"
curl -s http://localhost/assets/index-CwU5SbkU.js | head -5

echo -e "\n=== Content-Type Headers ==="
echo "JS Content-Type:"
curl -s -I http://localhost/assets/index-CwU5SbkU.js | grep -i content-type

echo "CSS Content-Type:"
curl -s -I http://localhost/assets/index-DxQpe1lr.css | grep -i content-type

echo -e "\n=== Index.html Script Tags ==="
echo "Script tags in index.html:"
curl -s http://localhost | grep -E '<script|<link.*css'