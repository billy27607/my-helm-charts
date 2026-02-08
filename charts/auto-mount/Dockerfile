FROM debian:12-slim

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1

# Add contrib repository for libdvdcss2
RUN echo "deb http://deb.debian.org/debian bookworm main contrib" > /etc/apt/sources.list && \
    echo "deb http://deb.debian.org/debian-security bookworm-security main contrib" >> /etc/apt/sources.list && \
    echo "deb http://deb.debian.org/debian bookworm-updates main contrib" >> /etc/apt/sources.list

# Install all system packages in one layer
RUN apt-get update && apt-get install -y --no-install-recommends \
    samba \
    samba-vfs-modules \
    python3 \
    python3-pip \
    python3-venv \
    bash \
    util-linux \
    e2fsprogs \
    procps \
    exfatprogs \
    udftools \
    genisoimage \
    cdparanoia \
    flac \
    curl \
    jq \
    wget \
    libdiscid0 \
    libdiscid-dev \
    cd-discid \
    avahi-daemon \
    dbus \
    handbrake-cli \
    libdvdcss2 \
    eject \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

# Install Python packages
RUN pip3 install --break-system-packages --no-cache-dir \
    flask \
    gunicorn \
    musicbrainzngs \
    discid

# Create mount points
RUN mkdir -p /mnt/hotswap /mnt/optical-mount /raid5/cd-rips

# Load CD-ROM filesystem kernel modules (will be done at runtime with privileged mode)
# These are just for documentation - actual loading happens in entrypoint

WORKDIR /app

# The entrypoint and webui scripts will be mounted via ConfigMap
CMD ["/bin/sh", "/app/entrypoint.sh"]
