# Simple HAProxy Project with Docker

A lightweight HAProxy load balancer configured to work with Docker containers.

## Project Structure

```
haproxy/
├── Dockerfile              # Docker image definition
├── haproxy.cfg            # HAProxy configuration file
├── haproxy.advanced.cfg   # Advanced configuration example
├── .dockerignore          # Files to exclude from Docker build
├── .gitignore             # Git ignore rules
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
- Docker Compose (optional)

## Quick Start

### Build and Run

```bash
# Build the Docker image
docker build -t haproxy:latest .

# Run the container
docker run -d \
  --name haproxy-server \
  -p 80:80 \
  -p 8404:8404 \
  haproxy:latest

# View logs
docker logs -f haproxy-server

# Access HAProxy Stats
curl http://localhost:8404/stats

# Stop the container
docker stop haproxy-server
```

### Configure Backend Servers

Edit `haproxy.cfg` and modify the backend section:

```
backend servers
    balance roundrobin
    server api1 api1.example.com:3000 check maxconn 32
    server api2 api2.example.com:3000 check maxconn 32
    server api3 api3.example.com:3000 check maxconn 32
```

Then rebuild and run:

```bash
docker build -t haproxy:latest .
docker run -d --name haproxy-server -p 80:80 -p 8404:8404 haproxy:latest
```

## Volumes & Persistent Data

HAProxy logs and data are written to the container. To persist data across container restarts, mount a volume to `/data`:

```bash
# Run with volume mount for persistent data
docker run -d \
  --name haproxy-server \
  -v $(pwd)/data:/data \
  -p 80:80 \
  -p 8404:8404 \
  haproxy:latest
```

Or in Railway, add a volume in the Storage section and mount it to `/data`.

## Configuration

All configuration is done by editing the `haproxy.cfg` file.

### Basic Setup

1. Edit `haproxy.cfg` to configure backend servers:

```
backend servers
    balance roundrobin
    server web1 192.168.1.10:8080 check
    server web2 192.168.1.11:8080 check
    server web3 192.168.1.12:8080 check
```

2. Build and deploy:

```bash
docker build -t haproxy:latest .
docker run -d --name haproxy-server -p 80:80 -p 8404:8404 haproxy:latest
```

### Advanced Configuration

For more complex setups, see `haproxy.advanced.cfg` which includes examples for:
- SSL/TLS termination
- TCP load balancing
- Custom headers

## Ports

- **80**: Main HAProxy listening port
- **8404**: HAProxy stats page

## Deployment

### Deploy to Railway

1. Push this repository to GitHub
2. Connect the repository to Railway
3. Railway will detect `Dockerfile` automatically
4. (Optional) Add a volume in Railway:
   - Go to **Storage** tab in your service settings
   - Mount path: `/data` (for persistent logs)
5. Deploy with a single click

### Manual Docker Deployment

```bash
# Build
docker build -t haproxy:latest .

# Run
docker run -d \
  --name haproxy-server \
  -p 80:80 \
  -p 8404:8404 \
  haproxy:latest
```

### Deploy to AWS ECS

```bash
# Build and push to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com
docker build -t haproxy:latest .
docker tag haproxy:latest <account-id>.dkr.ecr.us-east-1.amazonaws.com/haproxy:latest
docker push <account-id>.dkr.ecr.us-east-1.amazonaws.com/haproxy:latest
```

### Deploy to Kubernetes

```bash
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

### View Logs

```bash
# View container logs
docker logs haproxy-server

# Follow logs in real-time
docker logs -f haproxy-server
```

### Test Connection

```bash
# Test HAProxy is responding
curl -v http://localhost/

# Check stats page
curl http://localhost:8404/stats
```

### Backend Health

If backends are not responding:

1. Check HAProxy config is correct:
```bash
docker exec haproxy-server cat /usr/local/etc/haproxy/haproxy.cfg
```

2. Verify backends are reachable from container:
```bash
docker exec haproxy-server curl http://backend-server:8080/
```

3. Restart container:
```bash
docker restart haproxy-server
```

## Notes

- **Configuration**: All configuration is done by editing `haproxy.cfg`
- **Rebuilding**: Any changes to `haproxy.cfg` require rebuilding the Docker image
- **Scaling**: To add/remove backend servers, edit `haproxy.cfg` and rebuild
- **Deployment**: Push to GitHub and connect to Railway for automatic deployments

## Getting Started (TL;DR)

```bash
# 1. Enter project directory
cd haproxy

# 2. Build the image
docker build -t haproxy:latest .

# 3. Run the container
docker run -d --name haproxy-server -p 80:80 -p 8404:8404 haproxy:latest

# 4. Test it
curl http://localhost/

# 5. View stats
curl http://localhost:8404/stats

# 6. View logs
docker logs -f haproxy-server

# 7. Stop
docker stop haproxy-server
```

Your HAProxy load balancer is now running on `http://localhost` with stats on `http://localhost:8404/stats`.

## License

MIT
