# Flutter Web App - Docker Deployment

This document explains how the Flutter web app is dockerized and deployed alongside the Go API.

## Docker Architecture

### Multi-Stage Build

The Dockerfile uses a multi-stage build process for optimal production deployment:

1. **Build Stage** (`build-env`):
   - Based on Debian stable-slim
   - Installs Flutter SDK and dependencies
   - Compiles the Flutter web app
   - Generates optimized production build

2. **Production Stage** (`nginx:alpine`):
   - Lightweight nginx server
   - Serves compiled Flutter web assets
   - Configured for optimal performance

### Build Process

```dockerfile
# Stage 1: Build Flutter app
FROM debian:stable-slim AS build-env
# Install Flutter, compile app
RUN flutter build web --release

# Stage 2: Serve with nginx  
FROM nginx:alpine
COPY --from=build-env /app/build/web /usr/share/nginx/html/app
```

## Configuration

### Environment Variables

- `API_BASE_URL`: Configures the Flutter app to connect to the Go API
  - Default: `http://localhost:8081/api/v1`
  - Docker: Automatically configured to use the API container

### Nginx Configuration

```nginx
server {
    listen 80;
    root /usr/share/nginx/html;
    
    # Handle Flutter web routing
    location /app/ {
        try_files $uri $uri/ /app/index.html;
    }
    
    # Optimize static assets
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

## Docker Compose Integration

The web app is integrated into the main docker-compose.yml:

```yaml
services:
  travel-route-planner-web:
    build:
      context: ./src/packages/flutter-app
      dockerfile: Dockerfile
    ports:
      - "8080:80"
    environment:
      - API_BASE_URL=http://localhost:8081/api/v1
    depends_on:
      - travel-route-planner-api
```

## Deployment Commands

### Using Make (Recommended)
```bash
# Build and run both API and web app
make docker-run

# Build only the web app
make docker-build-web

# View web app logs
make docker-logs-web
```

### Using Docker Compose Directly
```bash
# Build and start all services
docker-compose up --build

# Build only the web app
docker-compose build travel-route-planner-web

# Start in background
docker-compose up -d

# View logs
docker-compose logs -f travel-route-planner-web
```

### Using Docker Directly
```bash
# Build the image
docker build -t travel-route-planner-web ./src/packages/flutter-app

# Run the container
docker run -p 3001:80 -e API_BASE_URL=http://host.docker.internal:8081/api/v1 travel-route-planner-web
```

## Access URLs

Once deployed, the application is available at:

- **Web App**: http://localhost:3001
- **Web App Health**: http://localhost:3001/health
- **API**: http://localhost:8081/api/v1
- **API Health**: http://localhost:8081/api/v1/health

## Health Checks

The container includes built-in health monitoring:

```dockerfile
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost/health || exit 1
```

## Production Optimizations

### Flutter Build Optimizations
- Uses `--release` flag for production builds
- Enables `canvaskit` renderer for better performance
- Tree-shaking to reduce bundle size
- Compression and minification

### Nginx Optimizations
- Gzip compression for text assets
- Long-term caching for static assets
- Proper MIME types and headers
- PWA support with service worker

### Security Features
- CORS headers configuration
- Security headers for Flutter web
- Non-root user execution
- Minimal attack surface with Alpine Linux

## Development vs Production

### Development
```bash
# Local development (hot reload)
cd src/packages/flutter-app
flutter run -d web-server --web-port 3001

# API running separately
cd src/packages/api
go run main.go route_optimizer.go country_optimizer.go
```

### Production
```bash
# Dockerized production deployment
docker-compose up --build
```

## Troubleshooting

### Common Issues

1. **API Connection Failed**
   - Ensure the API container is running: `docker-compose logs travel-route-planner-api`
   - Check API health: `curl http://localhost:8081/api/v1/health`

2. **Flutter Build Errors**
   - Clear build cache: `docker-compose build --no-cache travel-route-planner-web`
   - Check Flutter version compatibility in Dockerfile

3. **CORS Issues**
   - Verify CORS is enabled in the Go API
   - Check API_BASE_URL environment variable

### Debugging

```bash
# View container logs
docker-compose logs -f travel-route-planner-web

# Access container shell
docker-compose exec travel-route-planner-web sh

# Check nginx configuration
docker-compose exec travel-route-planner-web cat /etc/nginx/conf.d/default.conf
```

## File Structure

```
src/packages/flutter-app/
├── Dockerfile              # Multi-stage Docker build
├── .dockerignore           # Docker build exclusions
├── web/                    # Flutter web assets
│   ├── index.html         # Main HTML template
│   └── manifest.json      # PWA manifest
├── lib/                    # Flutter source code
└── pubspec.yaml           # Flutter dependencies
```

## Next Steps

For production deployment, consider:

1. **Load Balancing**: Use nginx or a load balancer for multiple instances
2. **SSL/TLS**: Add HTTPS with certificates
3. **CDN**: Serve static assets from a CDN
4. **Monitoring**: Add application monitoring and logging
5. **CI/CD**: Automate build and deployment pipeline
