FROM ubuntu:24.04

ARG GHIDRA_VERSION=12.1.4
ARG GHIDRA_DATE=20260921
ARG JADX_VERSION=1.5.6
ARG OPENCODE_VERSION=latest
ARG TARGETARCH
ENV DEBIAN_FRONTEND=noninteractive
ENV GHIDRA_INSTALL_DIR=/opt/ghidra
ENV JAVA_HOME=/usr/lib/jvm/default-java
ENV JADX_HOME=/opt/jadx
ENV PATH=/opt/jadx/bin:/opt/ghidra/support:/opt/ghidra:/usr/local/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin

RUN apt-get update && apt-get install -y --no-install-recommends \
    adb \
    apktool \
    binutils \
    binwalk \
    bsdmainutils \
    ca-certificates \
    capstone-tool \
    clang \
    cmake \
    curl \
    default-jdk \
    elfutils \
    exiftool \
    file \
    g++ \
    gcc \
    gdb \
    git \
    gnupg \
    iproute2 \
    jq \
    ltrace \
    make \
    nasm \
    netcat-openbsd \
    openssh-server \
    patch \
    patchelf \
    pipx \
    python3 \
    python3-dev \
    python3-pip \
    python3-venv \
    radare2 \
    rsync \
    software-properties-common \
    strace \
    unzip \
    vim-tiny \
    wget \
    xxd \
    yara \
    zip \
    && rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    curl -fL "https://github.com/skylot/jadx/releases/download/v${JADX_VERSION}/jadx-${JADX_VERSION}.zip" -o /tmp/jadx.zip; \
    mkdir -p "$JADX_HOME"; \
    unzip -q /tmp/jadx.zip -d "$JADX_HOME"; \
    rm /tmp/jadx.zip; \
    chmod +x "$JADX_HOME"/bin/jadx "$JADX_HOME"/bin/jadx-gui

RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get update && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/* \
    && npm install --global npm@latest rea-agents@latest opencode-ai@${OPENCODE_VERSION}

RUN python3 -m venv /opt/re-venv \
    && /opt/re-venv/bin/pip install --upgrade pip wheel setuptools \
    && /opt/re-venv/bin/pip install \
      angr \
      capstone \
      ghidra-bridge \
      lief \
      pefile \
      pwntools \
      pyelftools \
      r2pipe \
      unicorn \
      volatility3 \
      yara-python \
    && ln -s /opt/re-venv/bin/* /usr/local/bin/

RUN set -eux; \
    url="https://github.com/NationalSecurityAgency/ghidra/releases/download/Ghidra_${GHIDRA_VERSION}_build/ghidra_${GHIDRA_VERSION}_PUBLIC_${GHIDRA_DATE}.zip"; \
    curl -fL "$url" -o /tmp/ghidra.zip; \
    unzip -q /tmp/ghidra.zip -d /opt; \
    mv /opt/ghidra_* "$GHIDRA_INSTALL_DIR"; \
    rm /tmp/ghidra.zip; \
    chmod +x "$GHIDRA_INSTALL_DIR/ghidraRun" "$GHIDRA_INSTALL_DIR/support/analyzeHeadless"; \
    case "${TARGETARCH:-$(dpkg --print-architecture)}" in \
      arm64|aarch64) \
        cd "$GHIDRA_INSTALL_DIR/Ghidra/Features/Decompiler/src/decompile/cpp"; \
        make OSDIR=linux_arm_64 ARCH_TYPE= ghidra_opt -j"$(nproc)"; \
        mkdir -p "$GHIDRA_INSTALL_DIR/Ghidra/Features/Decompiler/os/linux_arm_64"; \
        install -m 0755 ghidra_opt "$GHIDRA_INSTALL_DIR/Ghidra/Features/Decompiler/os/linux_arm_64/decompile"; \
        make clean || true; \
        ;; \
      amd64|x86_64) \
        test -x "$GHIDRA_INSTALL_DIR/Ghidra/Features/Decompiler/os/linux_x86_64/decompile"; \
        ;; \
      *) echo "Unsupported Docker target architecture: ${TARGETARCH}" >&2; exit 1 ;; \
    esac

RUN rea setup --yes --skill

RUN mkdir -p /run/sshd /workspace /samples /config /opt/hopper \
    && useradd -m -s /bin/bash examiner

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY analyze-ghidra /usr/local/bin/analyze-ghidra
COPY rea-doctor /usr/local/bin/rea-doctor
RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/analyze-ghidra /usr/local/bin/rea-doctor

EXPOSE 22
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/usr/sbin/sshd", "-D", "-e"]
