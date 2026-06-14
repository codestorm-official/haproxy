FROM haproxy:latest

# Copy default HAProxy config to image
COPY haproxy.cfg /usr/local/etc/haproxy/haproxy.cfg
COPY docker-entrypoint.sh /docker-entrypoint.sh

USER root

RUN chmod +x /docker-entrypoint.sh

# Expose ports
EXPOSE 80 8404

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD haproxy -c -f ${HAPROXY_CONFIG:-/usr/local/etc/haproxy/haproxy.cfg} || exit 1

CMD ["/docker-entrypoint.sh"]