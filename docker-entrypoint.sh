#!/bin/sh
set -e

DEFAULT_CONFIG="/usr/local/etc/haproxy/haproxy.cfg"
VOLUME_CONFIG="/data/haproxy.cfg"

if [ -f "$VOLUME_CONFIG" ]; then
  echo "Using HAProxy config from Railway volume: $VOLUME_CONFIG"
  CONFIG_PATH="$VOLUME_CONFIG"
else
  echo "Using default HAProxy config from image: $DEFAULT_CONFIG"
  CONFIG_PATH="$DEFAULT_CONFIG"
fi

echo "Validating HAProxy config: $CONFIG_PATH"
haproxy -c -f "$CONFIG_PATH"

echo "Starting HAProxy..."
exec haproxy -f "$CONFIG_PATH" -db