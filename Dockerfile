FROM haproxy:latest

WORKDIR /app

# Copy entrypoint script
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# Copy environment files (only .env.example is required)
COPY .env.example /app/.env.example

# Optional: Copy .env if it exists
# Users can also mount .env or pass env vars via --env-file or -e flags

# Expose ports
EXPOSE 80 8404

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://localhost:8404/stats || exit 1

# Start HAProxy with entrypoint script
ENTRYPOINT ["/app/entrypoint.sh"]
