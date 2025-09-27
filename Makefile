# Travel Route Planner - Development Makefile
.PHONY: help build run test clean docker-build docker-run api-build api-run api-test

# Variables
API_DIR = src/packages/api
FLUTTER_DIR = src/packages/flutter-app
DOCKER_IMAGE = travel-route-planner-api
DOCKER_TAG = latest

# Default target
help: ## Show this help message
	@echo "Travel Route Planner - Available Commands:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

# Docker commands
docker-build: ## Build all Docker images
	docker-compose build

docker-build-api: ## Build only the API Docker image
	docker-compose build travel-route-planner-api

docker-build-web: ## Build only the Flutter web Docker image
	docker-compose build travel-route-planner-web

docker-run: ## Run all services using Docker Compose
	docker-compose up

docker-run-bg: ## Run all services in background using Docker Compose
	docker-compose up -d

docker-stop: ## Stop Docker Compose services
	docker-compose down

docker-logs: ## Show Docker Compose logs for all services
	docker-compose logs -f

docker-logs-api: ## Show Docker Compose logs for API only
	docker-compose logs -f travel-route-planner-api

docker-logs-web: ## Show Docker Compose logs for web only
	docker-compose logs -f travel-route-planner-web

# API commands
api-deps: ## Download API dependencies
	cd $(API_DIR) && go mod tidy

api-build: ## Build the API binary
	cd $(API_DIR) && go build -o travel-route-planner .

api-run: ## Run the API locally
	cd $(API_DIR) && go run main.go route_optimizer.go country_optimizer.go

api-test: ## Run API tests
	cd $(API_DIR) && ./test_examples.sh

api-fmt: ## Format Go code
	cd $(API_DIR) && go fmt ./...

api-vet: ## Run go vet
	cd $(API_DIR) && go vet ./...

# Flutter commands
flutter-deps: ## Install Flutter dependencies
	cd $(FLUTTER_DIR) && flutter pub get

flutter-build-web: ## Build Flutter web app
	cd $(FLUTTER_DIR) && flutter build web

flutter-build-models: ## Generate Flutter model code
	cd $(FLUTTER_DIR) && dart run build_runner build

flutter-run: ## Run Flutter app
	cd $(FLUTTER_DIR) && flutter run

flutter-test: ## Run Flutter tests
	cd $(FLUTTER_DIR) && flutter test

flutter-analyze: ## Analyze Flutter code
	cd $(FLUTTER_DIR) && flutter analyze

# Development commands
dev: docker-run ## Start development environment (alias for docker-run)

dev-api: api-run ## Start API development server

test: api-test ## Run all tests

clean: ## Clean up build artifacts
	cd $(API_DIR) && rm -f travel-route-planner
	docker-compose down
	docker system prune -f

# Setup commands
setup: ## Initial project setup
	@echo "Setting up Travel Route Planner development environment..."
	cd $(API_DIR) && go mod tidy
	cd $(FLUTTER_DIR) && flutter pub get
	@echo "Setup complete!"
	@echo ""
	@echo "🚀 Quick Start Options:"
	@echo "  make docker-run     # Run both API and web app with Docker"
	@echo "  make dev           # Run API only with Docker"
	@echo "  make flutter-run   # Run Flutter app locally"

# Health check
health: ## Check API health
	curl -s http://localhost:8081/api/v1/health | jq '.' || echo "API not running or jq not installed"

health-web: ## Check web app health
	curl -s http://localhost:3001/health || echo "Web app not running"

health-all: ## Check health of all services
	@echo "🔍 Checking API health..."
	@curl -s http://localhost:8081/api/v1/health | jq '.' || echo "❌ API not running"
	@echo ""
	@echo "🔍 Checking web app health..."
	@curl -s http://localhost:3001/health || echo "❌ Web app not running"

# Quick test commands
test-route: ## Test route optimization endpoint
	curl -s -X POST http://localhost:8081/api/v1/optimize-route \
		-H "Content-Type: application/json" \
		-d @$(API_DIR)/test_data.json | jq '.'

test-countries: ## Test country optimization endpoint  
	curl -s -X POST http://localhost:8081/api/v1/optimize-countries \
		-H "Content-Type: application/json" \
		-d '{"countries":[{"code":"US","name":"United States","latitude":39.8283,"longitude":-98.5795,"min_stay_days":7}],"optimize_for":"balanced"}' | jq '.'

# Documentation
docs: ## Show application URLs and documentation
	@echo "🌐 Application URLs:"
	@echo "  Web App: http://localhost:3001"
	@echo "  API Health: http://localhost:8081/api/v1/health"
	@echo ""
	@echo "📖 API Endpoints:"
	@echo "  Route Optimization: POST http://localhost:8081/api/v1/optimize-route"
	@echo "  Country Optimization: POST http://localhost:8081/api/v1/optimize-countries"
	@echo ""
	@echo "📚 Documentation:"
	@echo "  Main README: ./README.md"
	@echo "  API README: ./src/packages/api/README.md"
	@echo "  Flutter README: ./src/packages/flutter-app/README.md"
