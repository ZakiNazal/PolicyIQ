.PHONY: run-backend build-docker up help

# ─── Backend ──────────────────────────────────────────────────────────────────
run-backend:
	@echo "🚀 Starting FastAPI backend with hot-reload..."
	uvicorn backend.main:app --reload --host 0.0.0.0 --port 8000

# ─── Docker ───────────────────────────────────────────────────────────────────
build-docker:
	@echo "🐳 Building Docker image..."
	docker compose build

up:
	@echo "🐳 Starting all services via Docker Compose..."
	docker compose up

# ─── Help ─────────────────────────────────────────────────────────────────────
help:
	@echo ""
	@echo "PolicyIQ — Available Make Targets"
	@echo "----------------------------------"
	@echo "  run-backend   Run the FastAPI server locally with uvicorn --reload"
	@echo "  build-docker  Build the Docker image for the backend service"
	@echo "  up            Start all services via Docker Compose"
	@echo ""
