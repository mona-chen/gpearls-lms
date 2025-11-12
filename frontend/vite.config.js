import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import path from 'path'
import frappeui from 'frappe-ui/vite/index.js'
import { VitePWA } from 'vite-plugin-pwa'

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [
    frappeui({
      frappeProxy: true,
      lucideIcons: true,
      jinjaBootData: true,
      frappeTypes: {
        input: {},
      },
      buildConfig: {
        indexHtmlPath: '../lms/www/lms.html',
        outputDir: 'dist',
      },
    }),
    vue({
      script: {
        defineModel: true,
        propsDestructure: true,
      },
    }),
    VitePWA({
      registerType: 'autoUpdate',
      devOptions: {
        enabled: true,
      },
      workbox: {
        cleanupOutdatedCaches: true,
        maximumFileSizeToCacheInBytes: 5 * 1024 * 1024,
      },
      manifest: false,
    }),
  ],
  server: {
    host: '0.0.0.0', // Accept connections from any network interface
    allowedHosts: ['ps', 'fs', 'home'], // Explicitly allow this host
    port: 8080,
    proxy: {
      '/api': {
        target: 'http://localhost:3001',
        changeOrigin: true,
        secure: false,
      },
      '/login': {
        target: 'http://localhost:3001',
        changeOrigin: true,
        secure: false,
      },
      '/logout': {
        target: 'http://localhost:3001',
        changeOrigin: true,
        secure: false,
      },
    },
  },
  build: {
    outDir: 'dist',
    emptyOutDir: true,
  },
  resolve: {
    alias: {
      '@': path.resolve(__dirname, 'src'),
      'tailwind.config.js': path.resolve(__dirname, 'tailwind.config.js'),
      'socket.io-client': path.resolve(__dirname, 'src/utils/socketio-mock.js'),
    },
  },
  optimizeDeps: {
    include: [
      'feather-icons',
      'showdown',
      'engine.io-client',
      'tailwind.config.js',
      'interactjs',
      'highlight.js',
      'plyr',
    ],
  },
})
