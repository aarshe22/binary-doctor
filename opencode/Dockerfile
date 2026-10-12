FROM node:22-bookworm

ARG OPENCODE_VERSION=latest
ENV DEBIAN_FRONTEND=noninteractive
ENV OPENCODE_CONFIG_DIR=/root/.config/opencode
ENV OPENCODE_DATA_DIR=/root/.local/share/opencode

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    jq \
    openssh-client \
    python3 \
    ripgrep \
    sudo \
    vim-tiny \
    && rm -rf /var/lib/apt/lists/*

RUN npm install --global "opencode-ai@${OPENCODE_VERSION}"

COPY opencode.json /root/.config/opencode/opencode.json
COPY opencode-v2.json /root/.config/opencode/opencode-v2.json
COPY entrypoint.sh /usr/local/bin/opencode-entrypoint
RUN chmod +x /usr/local/bin/opencode-entrypoint

WORKDIR /workspace
ENTRYPOINT ["/usr/local/bin/opencode-entrypoint"]
CMD ["bash"]
