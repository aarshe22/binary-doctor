FROM nvidia/cuda:13.3.0-devel-ubuntu24.04

ARG LLAMA_CPP_REF=master
ARG TARGETARCH
ARG LLAMA_CUDA_ARCHS
ARG GGML_NATIVE=OFF
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    ccache \
    cmake \
    curl \
    git \
    ninja-build \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src
RUN git clone --depth 1 --branch "${LLAMA_CPP_REF}" https://github.com/ggml-org/llama.cpp.git

WORKDIR /src/llama.cpp
RUN set -eux; \
    case "${TARGETARCH:-$(dpkg --print-architecture)}" in \
      arm64|aarch64) cuda_target="sbsa-linux"; default_cuda_archs="121" ;; \
      amd64|x86_64) cuda_target="x86_64-linux"; default_cuda_archs="75;80;86;89;90" ;; \
      *) echo "Unsupported Docker target architecture: ${TARGETARCH}" >&2; exit 1 ;; \
    esac; \
    cuda_stubs="/usr/local/cuda/targets/${cuda_target}/lib/stubs"; \
    ln -sf libcuda.so "${cuda_stubs}/libcuda.so.1"; \
    cuda_archs="${LLAMA_CUDA_ARCHS:-${default_cuda_archs}}"; \
    cmake -S . -B build -G Ninja \
      -DCMAKE_BUILD_TYPE=Release \
      -DGGML_CUDA=ON \
      -DGGML_NATIVE="${GGML_NATIVE}" \
      -DCMAKE_CUDA_ARCHITECTURES="${cuda_archs}" \
      -DCMAKE_EXE_LINKER_FLAGS="-L${cuda_stubs} -Wl,-rpath-link,${cuda_stubs}" \
      -DLLAMA_CURL=ON \
    && cmake --build build --target llama-server -j"$(nproc)" \
    && install -m 0755 build/bin/llama-server /usr/local/bin/llama-server \
    && rm -rf /src/llama.cpp/.git /root/.cache

EXPOSE 8080
ENTRYPOINT ["/usr/local/bin/llama-server"]
