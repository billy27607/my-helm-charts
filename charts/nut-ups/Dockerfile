FROM debian:13-slim

ENV DEBIAN_FRONTEND=noninteractive

# nut-server: drivers (usbhid-ups) + upsd
# nut-client: upsmon, upsc, upscmd, upssched
# util-linux: nsenter (used to power off the host from inside the pod)
# curl: push notifications (ntfy)
RUN apt-get update && apt-get install -y --no-install-recommends \
    nut-server \
    nut-client \
    usbutils \
    util-linux \
    procps \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /run/nut /etc/nut \
    && rm -f /etc/nut/*.conf /etc/nut/upsd.users

# Config files and scripts are mounted from the chart's Secret/ConfigMap
CMD ["/bin/bash", "/scripts/entrypoint.sh"]
