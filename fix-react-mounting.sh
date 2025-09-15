#!/bin/bash
# Fix React app mounting issues

echo "🔧 Fixing React app mounting issues..."

# First, let's check if the test page works
echo "=== Testing Basic Functionality ==="
echo "Testing basic HTML/JS/API functionality..."
curl -s -o /dev/null -w "Test page status: %{http_code}\n" http://localhost/test.html

# Check if the main issue is React-specific
echo -e "\n=== Checking React App Issues ==="

# Create a minimal React test to isolate the issue
echo "Creating minimal React test..."
sudo docker exec nexus-green sh -c 'cat > /usr/share/nginx/html/react-test.html << "EOF"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>React Test</title>
</head>
<body>
    <div id="react-root">Loading React...</div>
    <script crossorigin src="https://unpkg.com/react@18/umd/react.development.js"></script>
    <script crossorigin src="https://unpkg.com/react-dom@18/umd/react-dom.development.js"></script>
    <script>
        console.log("React test starting...");
        console.log("React version:", React.version);
        
        const e = React.createElement;
        
        function TestApp() {
            return e("div", { style: { padding: "20px", textAlign: "center" } }, [
                e("h1", { key: "title", style: { color: "green" } }, "✅ React is Working!"),
                e("p", { key: "desc" }, "If you see this, React can mount and render."),
                e("button", { 
                    key: "btn",
                    onClick: () => alert("React events working!"),
                    style: { padding: "10px 20px", margin: "10px" }
                }, "Test Click")
            ]);
        }
        
        const root = ReactDOM.createRoot(document.getElementById("react-root"));
        root.render(e(TestApp));
        
        console.log("React test completed");
    </script>
</body>
</html>
EOF'

echo "✅ Created React test page at: http://13.245.181.202/react-test.html"

# Now let's check what might be wrong with the main app
echo -e "\n=== Analyzing Main App Issues ==="

# Check if there are any console errors in the built JavaScript
echo "Checking for potential JavaScript errors in built files..."
sudo docker exec nexus-green grep -i "error\|exception\|undefined" /usr/share/nginx/html/assets/*.js | head -5 || echo "No obvious errors found in JS files"

# Check if the root element exists and is accessible
echo -e "\nChecking root element in main HTML..."
sudo docker exec nexus-green grep -A 5 -B 5 'id="root"' /usr/share/nginx/html/index.html

# Check if React is trying to mount
echo -e "\nChecking if React mounting code exists..."
sudo docker exec nexus-green grep -i "createroot\|render\|mount" /usr/share/nginx/html/assets/*.js | head -3 || echo "React mounting code not found in expected format"

# Create a debug version of the main page
echo -e "\n=== Creating Debug Version ==="
echo "Creating debug version of main page..."
sudo docker exec nexus-green sh -c 'cp /usr/share/nginx/html/index.html /usr/share/nginx/html/debug.html'

# Add debug script to the debug version
sudo docker exec nexus-green sh -c 'sed -i "/<\/body>/i\\
<script>\\
console.log(\"🔍 Debug: Page loaded\");\\
console.log(\"🔍 Debug: Root element:\", document.getElementById(\"root\"));\\
console.log(\"🔍 Debug: All scripts loaded\");\\
\\
// Check if React loaded\\
setTimeout(() => {\\
    console.log(\"🔍 Debug: Checking after 2 seconds...\");\\
    const root = document.getElementById(\"root\");\\
    if (root) {\\
        console.log(\"🔍 Debug: Root element found:\", root);\\
        console.log(\"🔍 Debug: Root innerHTML:\", root.innerHTML);\\
        console.log(\"🔍 Debug: Root children:\", root.children.length);\\
    } else {\\
        console.error(\"❌ Debug: Root element not found!\");\\
    }\\
}, 2000);\\
</script>" /usr/share/nginx/html/debug.html'

echo "✅ Created debug page at: http://13.245.181.202/debug.html"

echo -e "\n🎯 Testing Instructions:"
echo "1. Visit http://13.245.181.202/test.html - Should show basic functionality"
echo "2. Visit http://13.245.181.202/react-test.html - Should show React working"
echo "3. Visit http://13.245.181.202/debug.html - Main app with debug info"
echo "4. Open browser developer tools (F12) and check Console tab"
echo ""
echo "📋 What to look for:"
echo "- test.html: Basic HTML/JS/API functionality"
echo "- react-test.html: React library can mount and render"
echo "- debug.html: Main app debug info in console"
echo ""
echo "If test.html and react-test.html work but debug.html doesn't, the issue is in the built React app."