import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'
import path from 'node:path'

// Served from a GitHub Pages project site at /Project-Aurora/site/,
// alongside the existing AuroraReader web build at /Project-Aurora/.
export default defineConfig(({ command }) => ({
  base: command === 'build' ? '/Project-Aurora/site/' : '/',
  plugins: [react(), tailwindcss()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
}))
