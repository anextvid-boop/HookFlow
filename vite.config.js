import { defineConfig } from 'vite'

// https://vitejs.dev/config/
export default defineConfig({
  base: './', // Ensures relative paths for GitHub Pages
  build: {
    outDir: 'dist',
    emptyOutDir: true
  }
})
