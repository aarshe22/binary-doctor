FROM ubuntu:24.04

ARG GHIDRA_VERSION=12.1.4
ARG GHIDRA_DATE=20260921
ARG JADX_VERSION=1.5.6
ARG OPENCODE_VERSION=latest
ARG OPENCODE_PACKAGE=@opencode/cli
ARG REA_AGENTS_VERSION=latest
ARG TARGETARCH
ENV DEBIAN_FRONTEND=noninteractive
ENV GHIDRA_INSTALL_DIR=/opt/ghidra
ENV JAVA_HOME=/usr/lib/jvm/default-java
ENV JADX_HOME=/opt/jadx
ENV PATH=/opt/jadx/bin:/opt/ghidra/support:/opt/ghidra:/usr/local/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin

RUN apt-get update && apt-get install -y --no-install-recommends \
    adb \
    apktool \
    arj \
    autoconf \
    automake \
    binutils \
    binutils-arm-none-eabi \
    binutils-avr \
    binutils-mips-linux-gnu \
    binutils-multiarch \
    binutils-powerpc-linux-gnu \
    binutils-riscv64-linux-gnu \
    binutils-sparc64-linux-gnu \
    binwalk \
    brotli \
    bsdmainutils \
    bsdextrautils \
    bzip2 \
    ca-certificates \
    capstone-tool \
    cc65 \
    clang \
    cmake \
    cpio \
    default-jre \
    device-tree-compiler \
    curl \
    default-jdk \
    dosfstools \
    elfutils \
    ewf-tools \
    exiftool \
    fakeroot \
    fdisk \
    file \
    foremost \
    g++ \
    gcc \
    gdb \
    gdb-multiarch \
    git \
    gnupg \
    gputils \
    gzip \
    icoutils \
    iproute2 \
    john \
    jq \
    lld \
    libarchive-tools \
    libimage-exiftool-perl \
    libtool \
    lhasa \
    ltrace \
    llvm \
    lz4 \
    lzip \
    lzop \
    make \
    mtd-utils \
    nasm \
    netcat-openbsd \
    nmap \
    openssh-server \
    p7zip-full \
    patch \
    patchelf \
    pipx \
    protobuf-compiler \
    python3 \
    python3-dev \
    python3-pip \
    python3-venv \
    qemu-system \
    qemu-user \
    qemu-user-static \
    qemu-utils \
    radare2 \
    ripgrep \
    rsync \
    sdcc \
    sleuthkit \
    software-properties-common \
    squashfs-tools \
    srecord \
    strace \
    swig \
    testdisk \
    u-boot-tools \
    unar \
    unzip \
    vim-tiny \
    wget \
    xxd \
    xz-utils \
    yara \
    yasm \
    zlib1g-dev \
    zip \
    xa65 \
    z80dasm \
    zstd \
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
    && npm install --global npm@latest \
    && npm install --global --allow-scripts="${OPENCODE_PACKAGE}" "rea-agents@${REA_AGENTS_VERSION}" "${OPENCODE_PACKAGE}@${OPENCODE_VERSION}" \
    && if [ -f "/usr/lib/node_modules/${OPENCODE_PACKAGE}/postinstall.mjs" ]; then node "/usr/lib/node_modules/${OPENCODE_PACKAGE}/postinstall.mjs"; fi

RUN python3 -m venv /opt/re-venv \
    && /opt/re-venv/bin/pip install --upgrade pip wheel setuptools \
    && /opt/re-venv/bin/pip install \
      angr \
      androguard \
      apkid \
      capstone \
      cxxfilt \
      dnfile \
      flare-floss \
      ghidra-bridge \
      intervaltree \
      lief \
      macholib \
      oletools \
      pefile \
      pwntools \
      pyelftools \
      python-magic \
      r2pipe \
      ropper \
      smda \
      unicorn \
      unblob \
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

COPY yara-rules /opt/yara-rules
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY analyze-ghidra /usr/local/bin/analyze-ghidra
COPY analyze-raw-ghidra /usr/local/bin/analyze-raw-ghidra
COPY rea-doctor /usr/local/bin/rea-doctor
COPY triage-specimen /usr/local/bin/triage-specimen
COPY update-opencode /usr/local/bin/update-opencode
RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/analyze-ghidra /usr/local/bin/analyze-raw-ghidra /usr/local/bin/rea-doctor /usr/local/bin/triage-specimen /usr/local/bin/update-opencode

EXPOSE 22
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/usr/sbin/sshd", "-D", "-e"]
