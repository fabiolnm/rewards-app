import { defineConfig, loadEnv } from 'vite';
import react from '@vitejs/plugin-react';

// https://vite.dev/config/
export default defineConfig(({ mode }) => {
  // Load environment variables
  const env = loadEnv(mode, process.cwd(), '');

  return {
    plugins: [react()],

    // Define environment variables that will be available in the app
    define: {
      'import.meta.env.VITE_API_URL': JSON.stringify(
        env.VITE_API_URL || 'http://localhost:3000'
      ),
    },

    server: {
      port: 5173,
      host: true,
    },

    preview: {
      port: 80,
      host: true,
    },
  };
});
