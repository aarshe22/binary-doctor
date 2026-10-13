# Binary Doctor

Binary Doctor is a portable Docker Compose workbench for authorized reverse engineering, firmware inspection, software decompilation, and security review.

It is designed for a simple operating model:

1. Put each case under `./data/specimens/<case-name>`.
2. Start the stack with Docker Compose.
3. Enter the prepared analysis shell with `./shell.sh`.
4. Use OpenCode + REA + Ghidra + the local GGUF model to inspect, decompile, unpack, and document the target.

The stack is built around direct `llama.cpp` serving of the Qwen 3.8 27B Uncensored GGUF. It avoids Docker Model Runner and Ollama so the GGUF is served with explicit runtime flags, full context configuration, OpenAI-compatible HTTP, and predictable tool access from the analysis containers.

## What Runs

- `REA-model-fetch`: downloads the configured GGUF into `./models`.
- `REA-llm`: builds and runs `llama-server` with CUDA and an OpenAI-compatible API.
- `REA`: reverse-engineering container with REA, Ghidra, Java, Python RE libraries, firmware tools, Android tools, emulation/debugging tools, and multi-architecture disassemblers.
- `REA-opencode`: interactive OpenCode container preconfigured to use the local Qwen model and REA MCP.
- `./data/specimens`: host-persistent case workspace mounted at `/data/specimens`.

## Quick Start

See [QUICKSTART.md](./QUICKSTART.md) for the shortest path.

The compact version:

```bash
cp .env.example .env
./scripts/fetch-weights.sh
docker compose up -d --build
./shell.sh
```

Inside the shell:

```bash
mkdir -p my-case/{originals,extracted,ghidra,notes,reports}
triage-specimen my-case/originals/target.bin my-case
opencode
```

## Model Endpoint

Host endpoint:

```text
http://localhost:12435/v1
```

Compose-internal endpoint:

```text
http://rea-llm:8080/v1
```

Stable model id:

```text
qwen3.8-27b-uncensored
```

OpenCode model id:

```text
examiner-qwen/qwen3.8-27b-uncensored
```

Default llama.cpp settings include:

- `--ctx-size 262144`
- `--n-gpu-layers 999`
- `--flash-attn on`
- `--jinja`
- `--reasoning-preserve`
- `--parallel 1`
- `--batch-size 2048`
- `--ubatch-size 2048`

Adjust these in `.env` when a host needs different performance or memory behavior.

## Case Workspace

Every real target should live under:

```text
./data/specimens/<case-name>
```

Recommended layout:

```text
data/specimens/<case-name>/
  README.md
  originals/
  extracted/
  ghidra/
  notes/
  reports/
```

Use `originals/` for untouched source evidence. Put all derived files in the other folders. `data/specimens/*` is ignored by Git so case material is not accidentally published with the tooling.

## Included Tooling

Core workflow:

- REA and REA MCP
- OpenCode
- Ghidra headless and native decompiler
- llama.cpp `llama-server`
- Java/JDK
- Node.js/npm

Static and decompilation:

- Ghidra
- radare2
- binutils and `binutils-multiarch`
- LLVM tools
- Capstone
- `file`, `xxd`, `strings`, `objdump`, `readelf`
- JADX, APKTool, Androguard, APKID
- `oletools`, `dnfile`, `macholib`, `pefile`, `pyelftools`

Firmware and archive work:

- Binwalk
- unblob
- squashfs-tools
- mtd-utils
- u-boot-tools
- device-tree-compiler
- sleuthkit, testdisk, foremost
- 7z, unar, arj, lhasa, gzip, bzip2, xz, zstd, lz4, lzip, lzop, brotli, cpio, zip

Emulation and debugging:

- qemu-user
- qemu-user-static
- qemu-system
- qemu-utils
- gdb and gdb-multiarch
- strace and ltrace

Retro and raw ROM support:

- Ghidra raw import helper
- 6502 examples via Ghidra language IDs
- z80dasm
- cc65, ca65, ld65
- xa65
- sdcc
- gputils
- srecord

Python RE:

- angr
- lief
- pwntools
- r2pipe
- ghidra-bridge
- volatility3
- yara-python
- unicorn
- ropper
- smda
- python-magic

## OpenCode and REA Updates

OpenCode and REA package versions are controlled by `.env`:

```text
OPENCODE_VERSION=latest
REA_AGENTS_VERSION=latest
OPENCODE_AUTO_UPDATE=1
```

`REA-opencode` runs `update-opencode` on startup when `OPENCODE_AUTO_UPDATE=1`.

Update the live OpenCode container:

```bash
./update-opencode.sh
```

Rebuild the image with current package releases:

```bash
./update-opencode.sh rebuild
```

For repeatable forensic work, pin `OPENCODE_VERSION` and `REA_AGENTS_VERSION` in `.env`.

## Ghidra

Analyze a normal binary:

```bash
docker exec -it REA analyze-ghidra /data/specimens/my-case/originals/target.bin my-case
```

Analyze a raw ROM or flat binary:

```bash
docker exec -it REA analyze-raw-ghidra \
  /data/specimens/my-case/originals/nes-prg.bin \
  6502:LE:16:default \
  nes-prg \
  0x8000
```

Useful language examples:

```text
6502:LE:16:default
z80:LE:16:default
68000:BE:32:default
8051:BE:16:default
avr8:LE:16:default
ARM:LE:32:v7
AARCH64:LE:64:v8A
x86:LE:32:default
x86:LE:64:default
```

List installed Ghidra processor language definitions:

```bash
docker exec -it REA find /opt/ghidra/Ghidra/Processors -name '*.ldefs' -print
```

## Hopper

Hopper is proprietary and is not redistributed here. If you have a licensed Linux Hopper installation, mount or place it at:

```text
/opt/hopper
```

The Compose file mounts that path read-only into `REA` and `REA-opencode`.

## Portability

This repo is intended to be pushed without model weights or specimens:

- `./models/*.gguf` is ignored.
- `./data/specimens/*` is ignored.
- Docker builds Ghidra, REA, OpenCode, Python tooling, and llama.cpp into containers.
- New machines can clone, fetch weights, and run `docker compose up -d --build`.

The Dockerfiles support `linux/arm64` and `linux/amd64`. On ARM64, the REA image compiles Ghidra's native decompiler. On x64, it uses Ghidra's bundled Linux x86_64 decompiler.

## Verification

After build or update:

```bash
docker compose config --quiet
docker compose ps
./scripts/smoke-test.sh
```

Expected healthy state:

- `REA-llm` responds at `/v1/models`.
- `REA` healthcheck passes.
- `REA-opencode` starts and reports an OpenCode version.
- Ghidra headless is installed.
- REA MCP reports the expected tool surface.
- Core tools such as `triage-specimen`, `analyze-raw-ghidra`, `qemu-aarch64-static`, `gdb-multiarch`, `unblob`, `llvm-objdump`, `z80dasm`, and `vol` are available.
