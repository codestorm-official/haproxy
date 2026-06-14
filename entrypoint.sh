#!/bin/sh
set -e

# Load environment variables if .env exists
if [ -f /app/.env ]; then
    set -a
    . /app/.env
    set +a
fi

# Set defaults if not provided
: "${HAPROXY_LOG_LEVEL:=info}"
: "${HAPROXY_MAXCONN:=4096}"
: "${LOAD_BALANCE_MODE:=roundrobin}"
: "${HAPROXY_FRONTEND_PORT:=80}"
: "${HAPROXY_STATS_PORT:=8404}"
: "${HEALTH_CHECK_ENABLED:=true}"
: "${STATS_ENABLED:=true}"
: "${STATS_URI:=/stats}"
: "${STATS_REFRESH:=30}"
: "${TIMEOUT_CONNECT:=5000}"
: "${TIMEOUT_CLIENT:=50000}"
: "${TIMEOUT_SERVER:=50000}"

# Generate HAProxy configuration
cat > /usr/local/etc/haproxy/haproxy.cfg << EOF
global
    maxconn ${HAPROXY_MAXCONN}
    log stdout local0 ${HAPROXY_LOG_LEVEL}
    log stdout local1 notice
    daemon

defaults
    log     global
    mode    http
    option  httplog
    option  denyclose
    timeout connect ${TIMEOUT_CONNECT}
    timeout client  ${TIMEOUT_CLIENT}
    timeout server  ${TIMEOUT_SERVER}

frontend main
    bind *:${HAPROXY_FRONTEND_PORT}
    default_backend servers

backend servers
    balance ${LOAD_BALANCE_MODE}
EOF

# Parse backend servers from BACKEND_SERVERS environment variable
# Format: server_name:host:port,server_name:host:port
if [ -n "$BACKEND_SERVERS" ]; then
    IFS=',' read -r -a servers <<< "$BACKEND_SERVERS"
    for server in "${servers[@]}"; do
        IFS=':' read -r name host port <<< "$server"
        if [ "$HEALTH_CHECK_ENABLED" = "true" ]; then
            echo "    server $name $host:$port check maxconn 32" >> /usr/local/etc/haproxy/haproxy.cfg
        else
            echo "    server $name $host:$port maxconn 32" >> /usr/local/etc/haproxy/haproxy.cfg
        fi
    done
fi

# Add stats section if enabled
if [ "$STATS_ENABLED" = "true" ]; then
    cat >> /usr/local/etc/haproxy/haproxy.cfg << EOF

listen stats
    bind *:${HAPROXY_STATS_PORT}
    stats enable
    stats admin if TRUE
    stats uri ${STATS_URI}
    stats refresh ${STATS_REFRESH}
EOF
fi

echo "✓ HAProxy configuration generated"
echo "✓ Frontend port: ${HAPROXY_FRONTEND_PORT}"
echo "✓ Stats port: ${HAPROXY_STATS_PORT}"
echo "✓ Load balancing: ${LOAD_BALANCE_MODE}"
echo "✓ Backend servers: ${BACKEND_SERVERS}"

# Start HAProxy
exec haproxy -f /usr/local/etc/haproxy/haproxy.cfg
