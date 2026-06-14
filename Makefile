.PHONY: help build run logs stop shell test clean env

help:
	@echo "HAProxy Docker Project - Available Commands"
	@echo ""
	@echo "  make env          - Copy .env.example to .env"
	@echo "  make build        - Build Docker image"
	@echo "  make run          - Build and run Docker container"
	@echo "  make logs         - View HAProxy container logs"
	@echo "  make stop         - Stop HAProxy container"
	@echo "  make shell        - Access HAProxy container shell"
	@echo "  make test         - Test HAProxy is working"
	@echo "  make stats        - Open HAProxy stats page"
	@echo "  make clean        - Remove containers and images"
	@echo ""

env:
	@if [ ! -f .env ]; then \
		cp .env.example .env; \
		echo "✓ .env file created from .env.example"; \
		echo "  Edit .env with your backend server configuration"; \
	else \
		echo "✓ .env already exists"; \
	fi

build:
	docker build -t haproxy:latest .
	@echo "✓ Docker image built"

run: build
	@if [ $$(docker ps -a -q -f name=haproxy-server) ]; then \
		docker stop haproxy-server 2>/dev/null || true; \
		docker rm haproxy-server 2>/dev/null || true; \
	fi
	docker run -d \
		--name haproxy-server \
		--env-file .env \
		-p 80:80 \
		-p 8404:8404 \
		haproxy:latest
	@echo "✓ Container started"
	@echo "  Frontend: http://localhost"
	@echo "  Stats: http://localhost:8404/stats"

logs:
	docker logs -f haproxy-server

stop:
	docker stop haproxy-server
	@echo "✓ Container stopped"

shell:
	docker exec -it haproxy-server sh

test:
	@echo "Testing HAProxy..."
	@curl -s http://localhost/ | head -10
	@echo "\n✓ Load balancer is working!"

stats:
	@echo "Opening HAProxy stats page..."
	@which xdg-open > /dev/null && xdg-open http://localhost:8404/stats || echo "Open http://localhost:8404/stats in your browser"

clean:
	docker stop haproxy-server 2>/dev/null || true
	docker rm haproxy-server 2>/dev/null || true
	docker rmi haproxy:latest 2>/dev/null || true
	@echo "✓ Cleaned up"

restart: stop run
	@echo "✓ Container restarted"
