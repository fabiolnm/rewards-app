# syntax=docker/dockerfile:1
# check=error=true

# Build stage
FROM oven/bun:1.3.5-slim AS build

WORKDIR /app

# Sentry build arguments (non-sensitive)
ARG VITE_SENTRY_DSN
ARG VITE_GIT_SHA
ARG SENTRY_ORG
ARG SENTRY_PROJECT

# Copy package files
COPY package.json bun.lockb ./

# Install dependencies
RUN bun install --frozen-lockfile

# Copy source code
COPY . .

# Build application with Sentry configuration
# SENTRY_AUTH_TOKEN passed via --mount=type=secret to avoid exposure in image layers
# VITE_* vars are public (embedded in JS), others are build-time only
ENV VITE_SENTRY_DSN=$VITE_SENTRY_DSN
ENV VITE_GIT_SHA=$VITE_GIT_SHA
RUN --mount=type=secret,id=SENTRY_AUTH_TOKEN \
    SENTRY_AUTH_TOKEN=$(cat /run/secrets/SENTRY_AUTH_TOKEN 2>/dev/null) \
    SENTRY_ORG=$SENTRY_ORG \
    SENTRY_PROJECT=$SENTRY_PROJECT \
    bun run build

# Production stage
FROM nginx:1.27.5-alpine

# Copy built assets from build stage
COPY --from=build /app/dist /usr/share/nginx/html

# Copy nginx configurations
COPY nginx-main.conf /etc/nginx/nginx.conf
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Create cache directories and set permissions for nginx user
RUN mkdir -p /var/cache/nginx/client_temp \
             /var/cache/nginx/proxy_temp \
             /var/cache/nginx/fastcgi_temp \
             /var/cache/nginx/uwsgi_temp \
             /var/cache/nginx/scgi_temp && \
    chown -R nginx:nginx /var/cache/nginx && \
    chmod -R 755 /var/cache/nginx

# Health check
HEALTHCHECK --interval=30s --timeout=3s \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1

# Run as non-root user
USER nginx

# Expose port
EXPOSE 8080

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
