FROM haproxy:latest

# Copy HAProxy config
COPY haproxy.cfg /usr/local/etc/haproxy/haproxy.cfg

# Expose ports
EXPOSE 80 8404

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://localhost:8404/stats || exit 1
