# Simple HAProxy Project with Docker

A lightweight HAProxy load balancer configured to work with Docker containers.

## Project Structure

```
haproxy/
├── Dockerfile              # Docker image definition
├── entrypoint.sh          # Startup script that generates config from env vars
├── .env                   # Environment variables (local, gitignored)
├── .env.example           # Example environment variables
├── haproxy.cfg            # HAProxy configuration (auto-generated)
├── haproxy.advanced.cfg   # Advanced configuration example
├── .dockerignore           # Files to exclude from Docker build
├── Makefile               # Helper commands
└── README.md              # This file
```

## Features

- **Load Balancing**: Round-robin load balancing across backend servers
- **Docker Support**: Easy containerization with Docker and Docker Compose
- **Health Checks**: Built-in health checks for backend servers
- **Stats Dashboard**: HAProxy stats page on port 8404
- **Alpine-based**: Lightweight image using Alpine Linux

## Prerequisites

- Docker
- Docker Compose (optional, for easy local testing)

## Quick Start

### Option 1: Using Docker (Recommended)

```bash
# Copy .env.example to .env and customize
cp .env.example .env

# Edit .env with your backend servers
nano .env

# Build the image
docker build -t haproxy:latest .

# Run the container
docker run -d \
  --name haproxy-server \
  --env-file .env \
  -p 80:80 \
  -p 8404:8404 \
  haproxy:latest

# View logs
docker logs -f haproxy-server

# Access HAProxy Stats
# Open browser: http://localhost:8404/stats

# Stop the container
docker stop haproxy-server
```

### Option 2: Using Docker without .env file

```bash
# Run with inline environment variables
docker run -d \
  --name haproxy-server \
  -e BACKEND_SERVERS="server1:127.0.0.1:8001,server2:127.0.0.1:8002" \
  -e LOAD_BALANCE_MODE="roundrobin" \
  -p 80:80 \
  -p 8404:8404 \
  haproxy:latest
```

### Option 3: Using Docker with Custom Config

If you prefer the old static configuration approach:

```bash
# Build the image
docker build -t haproxy:latest .

# Run with mounted haproxy.cfg
docker run -d \
  --name haproxy-server \
  -v $(pwd)/haproxy.cfg:/usr/local/etc/haproxy/haproxy.cfg:ro \
  -p 80:80 \
  -p 8404:8404 \
  haproxy:latest
```

### Test Load Balancing

```bash
# Test the load balancer
curl http://localhost/

# View stats page
curl http://localhost:8404/stats
```

## Configuration

### Environment Variables

All configuration is done through environment variables in `.env` file. Copy `.env.example` to `.env` and customize:

```bash
cp .env.example .env
```

Key environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `HAPROXY_MAXCONN` | 4096 | Maximum number of concurrent connections |
| `HAPROXY_LOG_LEVEL` | info | Log level (debug, info, warning, alert, err, crit) |
| `BACKEND_SERVERS` | - | Comma-separated list of backend servers (format: `name:host:port`) |
| `LOAD_BALANCE_MODE` | roundrobin | Load balancing algorithm (roundrobin, leastconn, source, uri, etc.) |
| `HAPROXY_FRONTEND_PORT` | 80 | Frontend listening port |
| `HAPROXY_STATS_PORT` | 8404 | Stats page port |
| `HEALTH_CHECK_ENABLED` | true | Enable health checks for backends |
| `STATS_ENABLED` | true | Enable stats page |
| `STATS_URI` | /stats | Stats page URI path |
| `TIMEOUT_CONNECT` | 5000 | Connection timeout in ms |
| `TIMEOUT_CLIENT` | 50000 | Client timeout in ms |
| `TIMEOUT_SERVER` | 50000 | Server timeout in ms |

### Example .env Configuration

```env
# Local development with 3 backend servers
BACKEND_SERVERS=api1:127.0.0.1:3001,api2:127.0.0.1:3002,api3:127.0.0.1:3003
LOAD_BALANCE_MODE=roundrobin
HAPROXY_FRONTEND_PORT=80
HAPROXY_STATS_PORT=8404
```

### Backend Server Format

Backend servers in the `BACKEND_SERVERS` variable use this format:

```
name:host:port,name2:host2:port2
```

Examples:
```env
# Single server
BACKEND_SERVERS=web1:localhost:8080

# Multiple servers (round-robin)
BACKEND_SERVERS=web1:api1.example.com:8080,web2:api2.example.com:8080,web3:api3.example.com:8080

# Docker network
BACKEND_SERVERS=api1:api-container-1:3000,api2:api-container-2:3000
```

### Advanced HAProxy Configuration

The `haproxy.cfg` file is auto-generated from environment variables. For complex scenarios:

1. Create a custom config based on `haproxy.advanced.cfg`
2. Mount it as a volume in Docker
3. Or extend the `entrypoint.sh` script

## Ports

- **80**: Main HAProxy listening port
- **8404**: HAProxy stats page

## Deployment

### Deploy to Railway

1. Push this repository to GitHub
2. Connect the repository to Railway
3. Railway will detect `Dockerfile` automatically
4. Set environment variables in Railway dashboard:

```
BACKEND_SERVERS=api1:backend-service-1:3000,api2:backend-service-2:3000
LOAD_BALANCE_MODE=roundrobin
HAPROXY_FRONTEND_PORT=80
HAPROXY_STATS_PORT=8404
```

5. Deploy with a single click

### Deploy to AWS ECS

```bash
# Build and push to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com
docker build -t haproxy:latest .
docker tag haproxy:latest <account-id>.dkr.ecr.us-east-1.amazonaws.com/haproxy:latest
docker push <account-id>.dkr.ecr.us-east-1.amazonaws.com/haproxy:latest
```

### Deploy to Google Cloud Run

```bash
# Build and push to GCR
gcloud builds submit --tag gcr.io/PROJECT_ID/haproxy
gcloud run deploy haproxy --image gcr.io/PROJECT_ID/haproxy --set-env-vars BACKEND_SERVERS="..."
```

### Deploy to Kubernetes

```bash
# Create ConfigMap from .env
kubectl create configmap haproxy-config --from-file=.env

# Apply deployment
kubectl apply -f - << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: haproxy
spec:
  replicas: 2
  selector:
    matchLabels:
      app: haproxy
  template:
    metadata:
      labels:
        app: haproxy
    spec:
      containers:
      - name: haproxy
        image: haproxy:latest
        ports:
        - containerPort: 80
        - containerPort: 8404
        envFrom:
        - configMapRef:
            name: haproxy-config
EOF
```

## Monitoring

Access the HAProxy stats dashboard:
```
http://localhost:8404/stats
```

## Troubleshooting

### Logs
```bash
# Docker
docker logs haproxy-server

# Docker Compose
docker-compose logs haproxy
```

### Test Connection
```bash
curl -v http://localhost/
```

### Check Backend Health
```bash
curl http://localhost:8404/stats
```

## Notes

- **Configuration**: All configuration is through environment variables, not static config files
- **HAProxy config generation**: The `haproxy.cfg` is auto-generated from `.env` at container startup via `entrypoint.sh`
- **Backend server discovery**: Services can be discovered using Docker DNS or external hosts
- **Scaling**: Update `BACKEND_SERVERS` env var to add/remove backend servers
- **No docker-compose required**: Pure Docker approach for simplicity and Railway deployment compatibility

## Troubleshooting

### .env file location

The `.env` file should be in the project root:

```bash
# Correct location
/home/asepsaputra/dev/Railway/haproxy/.env

# Make sure you created it from .env.example
cp .env.example .env
```

### Backend servers not responding

Check the logs to see if backends are being added:

```bash
docker logs haproxy-server | grep "Backend servers"
```

Check the generated config:

```bash
docker exec haproxy-server cat /usr/local/etc/haproxy/haproxy.cfg
```

### Environment variables not being read

When using `--env-file .env`:

```bash
# Verify Docker can access the file
ls -la .env

# Make sure it's in the correct directory
pwd

# Run with verbose output
docker run -it --env-file .env haproxy:latest
```

### Port already in use

If port 80 or 8404 is already in use:

```bash
# Find what's using the port
lsof -i :80
lsof -i :8404

# Use different ports
docker run -d \
  --env-file .env \
  -p 8080:80 \
  -p 8405:8404 \
  haproxy:latest
```

### HAProxy stats not loading

```bash
# Check if stats is enabled
grep "STATS_ENABLED" .env

# Verify port is accessible
curl http://localhost:8404/stats

# Check HAProxy config was generated correctly
docker exec haproxy-server cat /usr/local/etc/haproxy/haproxy.cfg | grep stats
```

## Getting Started (TL;DR)

```bash
# 1. Clone/enter project directory
cd haproxy

# 2. Create .env file
cp .env.example .env

# 3. Edit .env with your backend servers (optional)
# nano .env

# 4. Build and run using Makefile
make build
make run

# 5. Test it works
make test

# 6. View stats dashboard
make stats

# 7. Stop when done
make stop
```

That's it! Your HAProxy load balancer is running on `http://localhost` with stats on `http://localhost:8404/stats`.

## License

MIT
