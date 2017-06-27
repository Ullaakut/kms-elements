#!/bin/bash

set -e

echo "Hello world"

# Configuration

if [ -n "$KMS_TURN_URL" ]; then
  echo "turnURL=$KMS_TURN_URL" > /etc/kurento/modules/kurento/WebRtcEndpoint.conf.ini
fi

if [ -n "$OUTPUT_BITRATE" ]; then
    echo "outputBitrate=$OUTPUT_BITRATE" > /etc/kurento/modules/kurento/MediaElement.conf.ini
fi

if [ -n "$KMS_STUN_IP" -a -n "$KMS_STUN_PORT" ]; then
  # Generate WebRtcEndpoint configuration
  echo "stunServerAddress=$KMS_STUN_IP" > /etc/kurento/modules/kurento/WebRtcEndpoint.conf.ini
  echo "stunServerPort=$KMS_STUN_PORT" >> /etc/kurento/modules/kurento/WebRtcEndpoint.conf.ini
fi

# Remove ipv6 local loop until ipv6 is supported
cat /etc/hosts | sed '/::1/d' | tee /etc/hosts > /dev/null

exec /usr/local/bin/kurento-media-server "$@"