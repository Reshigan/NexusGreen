import { defineConfig } from "vite";
import react from "@vitejs/plugin-react-swc";
import path from "path";
import { componentTagger } from "lovable-tagger";

// https://vitejs.dev/config/
export default defineConfig(({ mode }) => ({
  server: {
    host: "0.0.0.0",
    port: 12001,
    proxy: {
      "/api": {
        target: "http://localhost:12000",
        changeOrigin: true,
        secure: false,
        timeout: 30000,
      },
    },
  },
  plugins: [
    react(),
    mode === 'development' && componentTagger(),
  ].filter(Boolean),
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "./src"),
    },
  },
  build: {
    // Production optimizations for ARM64
    target: 'es2020',
    minify: 'terser',
    terserOptions: {
      compress: {
        drop_console: mode === 'production',
        drop_debugger: mode === 'production',
        passes: 2,
      },
      mangle: {
        safari10: true,
      },
    },
    rollupOptions: {
      external: [],
      output: {
        manualChunks: (id) => {
          if (id.includes('node_modules')) {
            // Put everything in a single vendor chunk to avoid loading order issues
            return 'vendor';
          }
        },
        // Ensure proper chunk loading order
        chunkFileNames: (chunkInfo) => {
          const name = chunkInfo.name;
          // Add priority prefix to ensure loading order
          if (name === 'react-vendor') {
            return 'assets/[name]-[hash].js';
          }
          if (name === 'ui-vendor') {
            return 'assets/[name]-[hash].js';
          }
          return 'assets/[name]-[hash].js';
        },
      },
    },
    chunkSizeWarningLimit: 1000,
    sourcemap: false,
    // Optimize for ARM64 memory constraints
    assetsInlineLimit: 4096,
  },
  define: {
    __APP_VERSION__: JSON.stringify(process.env.npm_package_version || '1.0.0'),
    __BUILD_TIME__: JSON.stringify(new Date().toISOString()),
  },
  optimizeDeps: {
    include: [
      'react',
      'react-dom',
      'react-dom/client',
      'react/jsx-runtime',
      'react-router-dom',
      '@tanstack/react-query',
      'framer-motion',
      'lucide-react',
      'next-themes',
    ],
  },
}));
