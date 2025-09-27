# Multi-stage build for Flutter web app
FROM debian:stable-slim AS build-env

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Flutter SDK
ARG FLUTTER_VERSION=3.24.0
RUN git clone https://github.com/flutter/flutter.git /flutter --depth 1 --branch ${FLUTTER_VERSION}
ENV PATH="/flutter/bin:/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Pre-download Flutter dependencies
RUN flutter doctor -v
RUN flutter config --enable-web

# Set working directory
WORKDIR /app

# Copy pubspec files
COPY pubspec.yaml pubspec.lock ./

# Get dependencies
RUN flutter pub get

# Copy source code
COPY lib/ lib/
COPY web/ web/
COPY analysis_options.yaml ./

# Create missing assets if they don't exist
RUN mkdir -p web/icons

# Generate code (for JSON serialization)
RUN dart run build_runner build --delete-conflicting-outputs

# Build the Flutter web app
RUN flutter build web --release \
    --web-renderer canvaskit \
    --base-href /app/ \
    --dart-define=API_BASE_URL=http://localhost:8081/api/v1

# Final stage - serve with nginx
FROM nginx:alpine

# Copy custom nginx config
COPY <<EOF /etc/nginx/conf.d/default.conf
server {
    listen 80;
    server_name localhost;
    
    root /usr/share/nginx/html;
    index index.html;
    
    # Handle Flutter web routing
    location /app/ {
        try_files \$uri \$uri/ /app/index.html;
        
        # Add headers for Flutter web
        add_header Cross-Origin-Embedder-Policy require-corp;
        add_header Cross-Origin-Opener-Policy same-origin;
    }
    
    # Serve static assets with proper cache headers
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        add_header Cross-Origin-Embedder-Policy require-corp;
        add_header Cross-Origin-Opener-Policy same-origin;
    }
    
    # Health check
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
EOF

# Copy built web app
COPY --from=build-env /app/build/web /usr/share/nginx/html/app

# Create a simple index.html that redirects to the app
RUN echo '<!DOCTYPE html><html><head><meta http-equiv="refresh" content="0; url=/app/"></head><body><p>Redirecting to <a href="/app/">Travel Route Planner</a></p></body></html>' > /usr/share/nginx/html/index.html

# Expose port
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost/health || exit 1

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
