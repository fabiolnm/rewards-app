import { sentryVitePlugin } from "@sentry/vite-plugin";
import { defineConfig, loadEnv } from "vite";
import react from "@vitejs/plugin-react";

// https://vite.dev/config/
export default defineConfig(({ mode }) => {
  // Load environment variables
  const env = loadEnv(mode, process.cwd(), "");

  const plugins = [react()];

  // Add Sentry plugin in production for source map upload
  if (mode === "production" && env.SENTRY_AUTH_TOKEN) {
    plugins.push(
      sentryVitePlugin({
        org: env.SENTRY_ORG,
        project: env.SENTRY_PROJECT,
        authToken: env.SENTRY_AUTH_TOKEN,
        release: { name: env.VITE_GIT_SHA },
        sourcemaps: { filesToDeleteAfterUpload: ["./dist/**/*.map"] },
      }),
    );
  }

  return {
    plugins,

    build: {
      sourcemap: true,
    },

    // Define environment variables that will be available in the app
    define: {
      "import.meta.env.VITE_API_URL": JSON.stringify(
        env.VITE_API_URL || "http://localhost:3000",
      ),
      "import.meta.env.VITE_SENTRY_DSN": JSON.stringify(env.VITE_SENTRY_DSN),
      "import.meta.env.VITE_GIT_SHA": JSON.stringify(env.VITE_GIT_SHA),
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
